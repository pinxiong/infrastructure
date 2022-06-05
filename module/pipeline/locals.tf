locals {
  region           = var.region
  account_id       = var.account_id
  image_name       = var.image_name
  project_name     = var.name
  repository_name  = var.name
  build_name       = var.name
  pipeline_name    = var.name
  bucket_name      = "${var.name}-archive"
  ecs_cluster_name = var.ecs_cluster_name
  ecs_service_name = var.ecs_service_name
  pipeline_tags    = var.pipeline_tags
}