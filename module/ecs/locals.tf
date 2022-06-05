locals {
  vpc_id                            = var.vpc_id
  region                            = var.region
  project_name                      = var.project_name
  container_name                    = var.image_name
  image                             = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.image_name}:latest"
  vpc_private_subnets_id            = var.vpc_private_subnets_id
  vpc_public_subnets_id             = var.vpc_public_subnets_id
  ecs_cluster_name                  = var.ecs_cluster_name
  ecs_service_name                  = var.ecs_service_name
  max_capacity                      = var.max_capacity
  min_capacity                      = var.min_capacity
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
  cpu                               = var.cpu
  memory                            = var.memory
  tags                              = var.ecs_tags
}