locals {
  name               = var.name
  vpc_id             = var.vpc_id
  public_subnets_id  = var.public_subnets_id
  private_subnets_id = distinct(flatten(var.private_subnets_id))
  eks_version        = var.eks_version
  desired_size       = var.desired_size
  max_size           = var.max_size
  min_size           = var.min_size
  security_group_ids = var.security_group_ids
  tags               = var.eks_tags
}