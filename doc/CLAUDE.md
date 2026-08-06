# iac notes

Implementation notes distilled from comments that used to live inline in the
Terraform source. Each entry is referenced from a short 1-2 line comment at
its original location.

## Root (main.tf)

- **client_artifacts_bucket**: Deliberately not public - left at the s3
  module's secure defaults (`is_public = false`, public access block fully
  on). CloudFront's Origin Access Control is the only intended read path. A
  public bucket policy alongside OAC would let anyone bypass CloudFront
  entirely via the bucket's own endpoint.
- **client_artifacts_cloudfront_access** (IAM policy document): Scopes
  bucket access to just the one CloudFront distribution via OAC's
  `AWS:SourceArn` condition, rather than using the generic modules/s3
  public-bucket path. Grants `s3:PutObject` alongside `GetObject` even
  though CloudFront (read-only cache/CDN) never writes back to its origin -
  flagged during review, left as-is per explicit instruction.

## bootstrap/provider.tf

Deliberately no `backend` block: this config provisions the remote state
bucket and lock table themselves, so it has to run on local state until
those exist. Once applied, every other Terraform root (auth/.infra, iac's
own root config, ...) points its S3 backend at the bucket/table created
here.

## modules/cloudfront

`viewer_certificate` falls back to the CloudFront-issued default certificate
(which only covers `*.cloudfront.net`, not `var.aliases`) when no ACM cert
is given - `acm_certificate_arn` should only be passed once `var.aliases` is
also set, otherwise requests to a custom domain hit a cert mismatch.

## modules/route53

`transfer_lock` defaults to `false` (leaving the domain unlocked) rather
than the provider's own default of `true` - some TLD registries (confirmed
for `.click`) reject the `EnableDomainTransferLock` call outright, which
otherwise fails every apply. Override per-domain via `var.transfer_lock` if
the registry actually supports it.

## modules/s3

`aws_s3_bucket_policy.this` has an explicit `depends_on` on the public
access block resource: AWS rejects attaching a public bucket policy while
the public access block is still restrictive, and nothing else ties the two
resources together (the policy only references `aws_s3_bucket.this.id`), so
without the explicit dependency the apply order isn't guaranteed.

**Lifecycle expiry is opt-in via `expiration_days`** (null by default, so the
two build-artifact buckets get no lifecycle configuration at all). Only
`files_artifacts_bucket` sets it, at 4 days — those objects are CSVs the api
stages for the SQS file-processor pipeline, consumed within minutes, with the
extra days as slack for a DLQ redrive replaying a batch against the original
object.

Three details that are easy to get wrong, which is why the module emits three
rules rather than one `expiration`:

- **On a versioned bucket, `expiration` deletes nothing.** It writes a delete
  marker and the object's bytes live on as a noncurrent version forever — the
  rule *hides* data while still billing for it. Every bucket here has
  `versioning_enabled = true`, so `noncurrent_version_expiration` is what
  actually removes the data, and it is not optional.
- **`days` and `expired_object_delete_marker` cannot share an expiration
  block** — S3 rejects it. Hence the separate `expire-delete-markers` rule,
  which sweeps the markers left behind once every version under them is gone.
- **The `filter` block is written explicitly**, even to say "everything". The
  AWS provider treats an omitted filter as a deprecation warning rather than a
  match-all default.

The rule is scoped by `expiration_prefix` to `csv-metrics/`, which is where the
api writes these objects (`MetricServiceImpl#CSV_KEY_PREFIX`) — so anything else
stored in this shared bucket later does not inherit a 4-day life. The prefix and
the rule have to move together: renaming one without the other silently stops
the cleanup. An empty prefix (the default) means the whole bucket.

**`modules/lambda` also gained `s3_bucket_arns`** for this, granting object-level
Get/Put/Delete on a bucket the function actually uses. It is deliberately
distinct from `s3_bucket`, which only locates the deployment package, and is
object-level only — the bare bucket ARN would also grant ListBucket and
delete-bucket, which nothing here does. Its `sqs_queue_arns` statement gained
`sqs:SendMessage` at the same time, since a service can be both ends of its own
queue (the api enqueues the CSV imports it later consumes).

## modules/lambda (data.tf)

- **SES configuration-set IAM statement**: kept as a separate `dynamic
  "statement"` block from the identity-level SES grant. A `SendEmail` call
  that sets `ConfigurationSetName` is authorized against both the sending
  identity *and* the configuration set as distinct resources. Missing this
  statement fails with `not authorized to perform ses:SendEmail on resource
  ...:configuration-set/...` even though the identity grant is in place.
- **`sqs_queue_arns`**: optional list, same pattern as `dynamodb_table_arns` /
  `ses_*`. When non-empty, grants the ReceiveMessage / DeleteMessage /
  GetQueueAttributes / ChangeMessageVisibility set an SQS event source mapping
  needs to poll the queue, plus `SendMessage` — a service can be both ends of
  its own queue, as the api is. Callers that only use API Gateway (or SNS)
  leave it at the default `[]`.
- **`s3_bucket_arns`**: optional list, object-level Get/Put/Delete on buckets
  the function actually reads and writes. Distinct from `s3_bucket`, which only
  locates the deployment package; object-level only, because the bare bucket ARN
  would also grant ListBucket and delete-bucket.
- **`data.aws_s3_object.package`**: `aws_lambda_function` only diffs on the
  `s3_bucket`/`s3_key` strings, not on the object's actual content. Since CI
  re-uploads to the same key on every build, those strings never change and
  Terraform would otherwise see no diff at all. Looking up the current
  object version (the bucket has versioning enabled) and pinning the
  function to it gives Terraform a value that actually changes on every new
  upload, so it redeploys.

## modules/lambda (keep_warm)

Optional `keep_warm` (bool, default `false`) plus `keep_warm_interval_minutes`
(number, default `5`). When enabled, `keep_warm.tf` stands up an EventBridge
`aws_cloudwatch_event_rule` on a `rate(N minutes)` schedule that invokes the
function, so an execution environment stays live between real requests. This is
a deliberate, low-cost substitute for provisioned concurrency, which bills for a
reserved environment around the clock — the ping only pays for one short
invocation per interval.

- **Targets the alias, never `$LATEST`.** The target arn is
  `aws_lambda_alias.live.arn`, and the `aws_lambda_permission` carries the
  matching `qualifier`. Real traffic (API Gateway, SQS, SNS) resolves through
  the alias to a published, SnapStart-restored version; pinging `$LATEST` would
  keep a different environment warm than the one that actually serves requests.
- **No custom `input`** — EventBridge delivers its standard scheduled-event
  payload (`source: "aws.events"`, `detail-type: "Scheduled Event"`). **This
  matters:** the services' `LambdaEventDispatcher` raises
  `UnsupportedLambdaEventException` (failing the invocation) for any event no
  strategy claims, so this only works because each service carries a
  `KeepWarmEventStrategy` (`lambda/dispatch/strategy`) that matches that shape
  via the pre-existing `LambdaEventDiscriminators.isEventBridgeEvent(...,
  "aws.events", "Scheduled Event")` and returns an empty body without doing
  work. It is the "one new strategy" seam the dispatch package is built around
  (see each service's `doc/CLAUDE.md` "Lambda event dispatch"). The warmup rule
  is the only scheduled EventBridge rule on either function, so that shape
  unambiguously means "warmup"; a future scheduled job that needs real work
  would want a distinguishing `detail`/`input` and its own strategy so this one
  does not swallow it.
- **`rate()` pluralisation**: `rate(1 minute)` is singular, `rate(5 minutes)`
  plural — AWS rejects the wrong form — so the schedule expression switches on
  the interval. `keep_warm_interval_minutes` is validated as a whole number ≥ 1
  (EventBridge's `rate()` floor).
- **Everything is `count`-gated on `var.keep_warm`**, so a caller that leaves it
  at the default adds no EventBridge resources at all, and the
  `keep_warm_rule_arn` output is `null`.

## modules/api-integration

`payload_format_version` must stay `"1.0"`. `StreamLambdaHandler` builds its
handler via `getAwsProxyHandler()`, which deserializes the incoming event as
`AwsProxyRequest` - the shape used by REST APIs and HTTP API payload format
1.0, not the newer, differently-shaped 2.0 format. Mismatching this causes
`InvalidRequestEventException` ("not a valid request from Amazon API
Gateway") on every call.

## modules/acm

CloudFront requires its certificate to exist in `us-east-1` regardless of
which region the rest of the account's infra runs in - callers must pass an
`aws.us_east_1` provider alias in, same pattern as modules/route53 uses for
Route53 Domains.

## modules/ses

`configuration_set_arn` output is constructed rather than read off the
resource: `aws_ses_configuration_set` (the SESv1 resource) doesn't export an
`arn` attribute of its own, unlike its SESv2 counterpart, but the ARN format
is fixed/documented by AWS so the constructed value is exact.

## modules/sns-lambda-subscription

Lambda-protocol SNS subscriptions are confirmed automatically by AWS as
soon as the subscription and matching invoke permission both exist - unlike
http/https endpoints, there's no SubscribeURL confirmation handshake for the
function to implement.
