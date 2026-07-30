variable "name" {
  type        = string
  description = "Base name used for the DynamoDB table and related resources"
}

variable "billing_mode" {
  type        = string
  description = "Billing mode for the DynamoDB table (e.g., PROVISIONED or PAY_PER_REQUEST)"
  default     = "PAY_PER_REQUEST"
}

variable "read_capacity" {
  type        = number
  description = "Read capacity units for the DynamoDB table (only applicable if billing_mode is PROVISIONED)"
  default     = 5
}

variable "write_capacity" {
  type        = number
  description = "Write capacity units for the DynamoDB table (only applicable if billing_mode is PROVISIONED)"
  default     = 5
}

variable "hash_key" {
  type        = string
  description = "The name of the hash key for the DynamoDB table"
}

variable "range_key" {
  type        = string
  description = "The name of the range (sort) key for the DynamoDB table, if any"
  default     = null
}

variable "attributes" {
  type = list(object({
    name = string
    type = string
  }))
  description = "List of attributes for the DynamoDB table"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Map of tags"
  default     = {}
}

variable "items" {
  type        = map(string)
  description = "Map of seed-item-key => JSON-encoded DynamoDB item (attribute-value format, e.g. jsonencode({ role = { S = \"ADMIN\" } })) to seed into the table"
  default     = {}
}

variable "global_secondary_indexes" {
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string)
    projection_type    = optional(string, "ALL")
    non_key_attributes = optional(list(string), [])
    read_capacity      = optional(number)
    write_capacity     = optional(number)
  }))
  description = <<EOF
List of global secondary indexes for the DynamoDB table.

- `projection_type`: One of ALL (default), KEYS_ONLY, or INCLUDE.
- `non_key_attributes`: Required only when projection_type is INCLUDE.
- `read_capacity` / `write_capacity`: Only relevant when billing_mode is PROVISIONED.
EOF
  default     = []
}
