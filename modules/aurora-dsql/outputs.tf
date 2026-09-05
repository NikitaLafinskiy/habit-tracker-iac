output "arn" {
  value = aws_dsql_cluster.this.arn
}

output "identifier" {
  value = aws_dsql_cluster.this.identifier
}

# aws_dsql_cluster exports no endpoint attribute - the endpoint is always
# https://<identifier>.dsql.<region>.on.aws, so it is constructed here.
output "endpoint" {
  value = "https://${aws_dsql_cluster.this.identifier}.dsql.${data.aws_region.current.region}.on.aws"
}
