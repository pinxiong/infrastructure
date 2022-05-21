locals {
  region             = "us-east-1"
  availability_zones = ["${local.region}a", "${local.region}b", "${local.region}c"]
  tags               = {
    "Environment" : "PROD"
    "Project" : "Infrastructure"
  }
}

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

module "JumpServer" {
  source            = "../../module/jumpserver"
  vpc_id            = module.Networking.vpc_id
  public_subnets_id = module.Networking.public_subnets_id
  shared_tags       = local.tags
}

/*module "EKS" {
  source             = "../../module/eks"
  name               = "EKS"
  vpc_id             = module.Networking.vpc_id
  public_subnets_id  = module.Networking.public_subnets_id
  private_subnets_id = module.Networking.private_subnets_id
  desired_size       = 1
  max_size           = 16
  eks_tags           = local.tags
}*/

/*module "ECS" {
  source         = "../../module/ecs"
  vpc_id         = module.Networking.vpc_id
  ecs_name       = " Message Transmission "
  log_group_name = "/aws/mq/message-transmission"
  vpc_subnets_id = ["subnet-02c08f984a1cc349f", "subnet-0a4351da270f767fe", "subnet-041bc2a26869a5a65"]
}*/
