locals {
  account_id            = "157854716818"
  region             = "us-east-1"
  availability_zones = ["${local.region}a", "${local.region}b", "${local.region}c"]
  tags               = {
    "Environment" : "PROD"
    "Project" : "Infrastructure"
  }
}