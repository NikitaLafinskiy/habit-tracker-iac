locals {
  name = "habit-tracker-api"
  tags = {}
}

module "api_gateway" {
  source = "./modules/api-gateway"

  name                 = local.name
  tags                 = local.tags
}

