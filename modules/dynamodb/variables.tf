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
