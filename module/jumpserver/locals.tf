locals {
  vpc_id             = var.vpc_id
  instance_type      = var.instance_type
  instance_ami       = var.instance_ami
  subnet_id          = var.public_subnets_id[0][0]
  security_group_ids = var.security_group_ids
  tags               = var.shared_tags
}
