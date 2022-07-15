provider "aws" {
  region = local.region
}

module "Networking" {
  source                     = "../../module/networking"
  name                       = "VPC"
  availability_zones         = local.availability_zones
  vpc_cidr_block             = "10.0.0.0/16"
  public_subnets_cidr_block  = ["10.0.32.0/24", "10.0.96.0/24", "10.0.224.0/24"]
  private_subnets_cidr_block = ["10.0.0.0/19", "10.0.64.0/19", "10.0.128.0/19"]
  vpc_tags                   = local.tags
}

module "EKS" {
  source             = "../../module/eks"
  max_size           = 2
  name               = "Marketing"
  private_subnets_id = module.Networking.private_subnets_id
  public_subnets_id  = module.Networking.public_subnets_id
  vpc_id             = module.Networking.vpc_id
}

module "Jumper" {
  source            = "../../module/jumpserver"
  public_subnets_id = module.Networking.public_subnets_id
  vpc_id            = module.Networking.vpc_id
  instance_type     = "t3.nano"
}
