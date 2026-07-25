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

## modules/lambda (data.tf)

- **SES configuration-set IAM statement**: kept as a separate `dynamic
  "statement"` block from the identity-level SES grant. A `SendEmail` call
  that sets `ConfigurationSetName` is authorized against both the sending
  identity *and* the configuration set as distinct resources. Missing this
  statement fails with `not authorized to perform ses:SendEmail on resource
  ...:configuration-set/...` even though the identity grant is in place.
- **`data.aws_s3_object.package`**: `aws_lambda_function` only diffs on the
  `s3_bucket`/`s3_key` strings, not on the object's actual content. Since CI
  re-uploads to the same key on every build, those strings never change and
  Terraform would otherwise see no diff at all. Looking up the current
  object version (the bucket has versioning enabled) and pinning the
  function to it gives Terraform a value that actually changes on every new
  upload, so it redeploys.

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
