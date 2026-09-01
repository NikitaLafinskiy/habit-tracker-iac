# iac notes

Implementation notes distilled from comments that used to live inline in the
Terraform source. Each entry is referenced from a short 1-2 line comment at
its original location.

## Environments

Two environments, `prod` and `dev`, in **one AWS account**, separated by name
suffix and by state file. Every Terraform root here (`iac`, `api/.infra`,
`auth/.infra`) follows the same three-part convention:

| | prod | dev |
|---|---|---|
| state key | `<root>/terraform.tfstate` | `<root>/terraform.dev.tfstate` |
| backend config | `backend.prod.hcl` | `backend.dev.hcl` |
| var file | `terraform.prod.tfvars` | `terraform.dev.tfvars` |
| `var.environment` | `"prod"` | `"dev"` |
| name suffix | none | `-dev` |

```bash
terraform init -reconfigure -backend-config=backend.dev.hcl
terraform plan -var-file=terraform.dev.tfvars
```

- **A var file alone would not have been enough, and getting this wrong
  destroys prod.** `terraform.tfvars` used to auto-load, and the backend `key`
  was hardcoded. Applying a dev var file against that single key would not
  build a second environment - Terraform would read the existing prod
  resources out of state and *rename* them to `-dev`, which for a DynamoDB
  table means destroy-and-recreate. The state key is what separates the
  environments; the var file only decides what the names look like.
- **`key` is the only part of the backend supplied at init.** Bucket, region
  and lock table stay in `backend.tf` because they are the same everywhere.
  This does cost the "init needs no flags" property the old hardcoded key had
  - that was a deliberate trade, and `-reconfigure` is in the documented
  command so a re-init between environments cannot silently reuse the
  previous one's state.
- **No tfvars file auto-loads any more**, and `var.environment` has no
  default. An apply that forgets `-var-file` therefore fails on a missing
  required variable instead of silently picking an environment.
- **Prod names are unsuffixed, so nothing in prod is renamed.** `local.suffix`
  is `""` for prod and `"-dev"` otherwise.
- **Per-service roots read the shared state key that matches their own
  environment** (`data.terraform_remote_state.iac`, keyed off
  `var.environment`), and each asserts `outputs.environment` matches via a
  `terraform_data` precondition. That catches a dev service wired to the prod
  API Gateway. It cannot catch the remaining hole - initialising with
  `backend.prod.hcl` and applying `terraform.dev.tfvars` - because a root
  cannot read its own backend key. CI never diverges (both are derived from
  the branch, below); by hand, the plan for that mistake is wall-to-wall
  destroy/create and must not be approved.

### Migrating an existing prod state onto this layout

Making the prod-only modules conditional means `module.<name>` becomes
`module.<name>[0]`, and Terraform reads a changed address as "the old one is
gone, build a new one". Left alone, the first prod plan wanted to **destroy 12
resources**, including the registered domain, the CloudFront distribution, the
ACM certificate and the bucket holding the deployed SPA.

This was fixed **once, by hand, with `terraform state mv`** rather than by
committing `moved` blocks - the state is remote and shared, so a single run
fixes it for every future plan including CI, and nothing is left in the repo
afterwards. Recorded here because the commands are otherwise unrecoverable:

```bash
# iac, initialised against backend.prod.hcl
terraform state mv 'module.domain'                 'module.domain[0]'
terraform state mv 'module.client_artifacts_bucket' 'module.client_artifacts_bucket[0]'
terraform state mv 'module.client_certificate'      'module.client_certificate[0]'
terraform state mv 'module.cloudfront'              'module.cloudfront[0]'

# auth/.infra, initialised against backend.prod.hcl
terraform state mv 'module.ses'                          'module.ses[0]'
terraform state mv 'module.ses_notifications_topic'       'module.ses_notifications_topic[0]'
terraform state mv 'module.ses_notifications_subscription' 'module.ses_notifications_subscription[0]'
```

A whole-module move carries everything inside it, including nested data sources
and already-indexed resources (`module.ses.aws_route53_record.dkim[0]` and so
on). `api/.infra` needs nothing - no module there gained a `count`.

**Only modules need this.** Terraform infers the index-0 move when `count` is
added to a bare *resource*, which is why `aws_route53_record.cloudfront` and
`aws_s3_bucket_policy.client_artifacts_cloudfront_access` were left alone.

The state bucket has versioning enabled, so a mistake is recoverable by
restoring the previous object version; `terraform state pull > backup.json`
first is the cheaper habit.

**No `Environment` tag, and that was not an oversight.** Tagging looked free,
but `local.tags` reaches `module.domain`, and any change to
`aws_route53domains_registered_domain` defers the `data.aws_route53_zone` that
`depends_on` it. `zone_id` then becomes "known after apply", which **forces
replacement of the apex A record and the ACM validation record** - live DNS
churn for a tag. `local.tags` is `{}`. Adding tags later is possible but is its
own careful change, and it must skip the route53 module.

**Order matters, because the per-service guard reads an output that does not
exist yet.** `terraform_data.environment_guard` compares
`data.terraform_remote_state.iac.outputs.environment` against `var.environment`,
and a prod iac state written before this split has no such output. The guard
uses `try(...)` so that surfaces as its own precondition message
("...says `<no environment output - apply the iac root for this environment
first>`") rather than a bare "Unsupported attribute" crash. So:

1. the `state mv` commands above
2. `iac` prod - expect **0 to add, 0 to change, 0 to destroy**, and it publishes
   the `environment` output the guard needs
3. `auth/.infra` prod, then `api/.infra` prod - each **2 to change**: the Lambda
   and its alias picking up `SPRING_PROFILES_ACTIVE=prod`, plus the guard
   resource itself. That env var is required, not cosmetic - without it the
   deployed function loads no `application-<env>.yml` and fails to start on an
   unresolvable placeholder.

### What dev does not get

Dev is **backend-only**: its own API Gateway, Lambdas, tables, queues and
files bucket, reached at the gateway's `execute-api` URL with the client run
locally against it.

- **No domain, ACM certificate, CloudFront distribution or client bucket.**
  These are `count = local.is_prod ? 1 : 0` in the root. There is one
  registered domain, so `modules/route53` in particular cannot run twice.
- **No SES identity, DKIM records or bounce/complaint topic** (same treatment
  in `auth/.infra`). A domain cannot be verified twice, and two states
  managing the same `_amazonses` TXT record would flap it on every apply.
  Dev sends through prod's already-verified identities, passed in as
  `additional_ses_identity_arns`. The cost is that dev has no bounce or
  complaint handling.
- **No `keep_warm`.** The EventBridge ping exists to hide cold starts from
  users; dev has none, and it bills per invocation.
- **No point-in-time recovery** on dev tables - set explicitly to `false` per
  table rather than left to the module's `true` default, since dev data is
  disposable and PITR is billed per GB-month.

### Deployed configuration: a Spring profile per environment

Each service ships `application-prod.yml` and `application-dev.yml`, and the
only thing Terraform injects is `SPRING_PROFILES_ACTIVE = var.environment`. So
**one artifact serves both environments** with no per-environment build, and
every environment's values are greppable in its own file.

**`application.yml` holds nothing environment-specific, and that is the point.**
It used to carry the prod queue URL, bucket and table names as committed
defaults, with Terraform overriding them per environment. That worked, but it
failed in the wrong direction: a mistyped or dropped override did not break the
dev function, it silently pointed it at **prod's** tables and queue. With the
values moved out, a Lambda with no `SPRING_PROFILES_ACTIVE` fails to start on an
unresolvable placeholder instead.

What stays in `application.yml` is what genuinely does not vary: `aws.region`,
`dynamodb.endpoint` (the regional service endpoint - same in both environments
by construction, since they share an account and a region), Jackson/management
settings, and `ses.configuration-set`, whose value only exists as a
Terraform-created resource and so is still injected.

Table names are part of the per-environment set: they used to be `private
static final String` constants in the repositories, which would have pointed
the dev Lambdas at the prod tables. They are now `dynamodb.tables.*`
properties.

**The trade-off:** a resource renamed in `terraform.<env>.tfvars` must also be
renamed in the matching `application-<env>.yml` - Terraform no longer feeds the
name in from `module.sqs.queue_url` and friends. That is the same manual-sync
rule `application.yml` already carried for the prod queue and bucket, now
applied per environment. A drift shows up as a runtime AccessDenied or
ResourceNotFound in that environment only, never as a cross-environment write.

Tests were already configured by `src/test/resources/application.properties`
in each repo; the table names the DynamoDB Local fixtures provision were added
there, alongside placeholder queue/bucket values that are never actually
called. No test profile was introduced - that file already owned this job.

### Manual prerequisites for a new environment

Terraform reads the JWT signing secrets from SSM; it never mints them, so
they will not exist for a fresh environment. Create them before the first
`auth` apply:

```bash
aws ssm put-parameter --type SecureString --name /services/auth-dev/jwt/access-secret  --value "$(openssl rand -hex 32)"
aws ssm put-parameter --type SecureString --name /services/auth-dev/jwt/refresh-secret --value "$(openssl rand -hex 32)"
```

`api/.infra` reads the access secret only - it verifies tokens auth mints and
never issues them - so both roots must name the same parameter.

### Apply order

The per-service roots read the shared root's outputs, so it goes first:

1. `iac` with `backend.dev.hcl` / `terraform.dev.tfvars`
2. the SSM parameters above
3. `auth/.infra`, then `api/.infra` (either order; `auth`'s var file names the
   api queue as a literal, so the queue need not exist at plan time)

### CI

**One workflow per path, and no job anywhere carries an `if:`.** A job either
runs or renders as "skipped", so a single workflow serving both environments
necessarily shows prod jobs greyed out on a dev run and vice versa. The split is
what removes that: each workflow is triggered by exactly one thing, and every
job in it runs unconditionally.

Two reusable workflows here hold the actual Terraform steps, both
`workflow_call`-only:

| | |
|---|---|
| `terraform-plan.yaml` | init, fmt, validate, plan, upload |
| `terraform-apply.yaml` | the same, then apply, in one job |

They are separate files rather than one workflow with a conditional apply job,
for the same no-skipped-jobs reason. Neither has an approval gate - callers own
that.

The callers, per repo:

| workflow | trigger | calls |
|---|---|---|
| `iac-dev.yaml` / `deploy-dev.yaml` | push to `dev` | `terraform-apply` (dev) |
| `iac-prod-plan.yaml` / `terraform-prod-plan.yaml` | PR to `main` | `terraform-plan` (prod) |
| `iac-prod-apply.yaml` / `terraform-prod-apply.yaml` | `workflow_dispatch` | `terraform-apply` (prod) |
| `java-ci.yaml` (api/auth) | PR to `main` | - build and test only |
| `prod-publish.yaml` (api/auth) | `workflow_dispatch` | - build and publish the jar |

- **`environment` is now an explicit input, not derived from the ref.** Each
  caller is triggered by exactly one path so it already knows which environment
  it is. It still cannot be mis-paired: the backend config, the var file and the
  GitHub environment all come from that one input inside the reusable workflow.
- **`workflow_dispatch`-only is still the prod approval gate**, since this repo
  is private on a plan without required-reviewer environment protection. What
  changed is where "must be main" lives: it used to be `github.ref ==
  'refs/heads/main'` in a job `if:`, which is exactly the thing that rendered as
  a skipped job elsewhere. **Set a deployment branch rule limiting the `prod`
  GitHub environment to `main` instead** - a job with `environment: prod` on any
  other ref then fails outright rather than skipping. Without that rule, a prod
  dispatch from any branch will publish and apply.
- **A dev push deploys through `deploy-dev.yaml`, which chains build → publish →
  terraform-apply.** The Lambda tracks its artifact's S3 object version
  (`modules/lambda/data.tf`), so publishing a jar does not reach the function
  until Terraform applies. That workflow has no path filter, so an `.infra`-only
  change on dev comes through it too, and the prod terraform workflows keep
  their own triggers rather than racing it for the state lock.
- **Prod deploy is two dispatches, unchanged:** `prod-publish.yaml` then
  `terraform-prod-apply.yaml`.
- **`vars.LAMBDA_ARTIFACT_S3_BUCKET` is the only value that differs per
  environment**, so it is the only GitHub *environment* variable. `AWS_REGION`,
  `TF_STATE_S3_BUCKET` and `LAMBDA_ARTIFACT_S3_KEY` stay repo-level and are
  inherited; environment variables override repo ones of the same name. Dev's
  artifact bucket is `habit-tracker-lambda-artifacts-dev`; the key within it is
  the same as prod's. The `dev` and `prod` environments must exist in **api,
  auth and iac** - a reusable workflow resolves `environment:` and `vars`
  against the *caller's* repo.
- **`concurrency` is grouped per repo + root + environment** with
  `cancel-in-progress: false`. Two pushes to `dev` in quick succession would
  otherwise race for the DynamoDB state lock and one would fail outright
  rather than queueing.

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
