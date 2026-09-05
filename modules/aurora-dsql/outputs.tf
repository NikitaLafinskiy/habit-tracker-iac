output "arn" {
  value = aws_dsql_cluster.this.arn
}

output "identifier" {
  value = aws_dsql_cluster.this.identifier
}

# aws_dsql_cluster exports no endpoint attribute, so it is constructed here -
# as a BARE host. Every consumer composes its own scheme: the Lambda's
# application-<env>.yml builds jdbc:aws-dsql:postgresql://${DSQL_CLUSTER_ENDPOINT}/postgres
# and psql/CLI take --host. The AWS console displays the endpoint as
# https://<identifier>...., but baking that scheme in here is exactly how the
# connector ended up parsing the region from the literal string "https"
# (Cannot determine region from host: https).
output "endpoint" {
  value = "${aws_dsql_cluster.this.identifier}.dsql.${data.aws_region.current.region}.on.aws"
}
