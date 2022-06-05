variable "name" {
  type        = string
  description = "The prefix name for repository, build, deploy and pipeline."
}

variable "image_name" {
  type        = string
  description = "The built image name."
}

variable "account_id" {
  type = string
  description = "The aws account id."
}

variable "region" {
  type = string
  description = "The region of workshop"
}

variable "ecs_cluster_name" {
  type = string
  description = "The name of ecs cluster"
}

variable "ecs_service_name" {
  type = string
  description = "The name of ecs service"
}

variable "pipeline_tags" {
  description = "A map of tags to add to pipeline"
  type        = map(string)
  default     = {}
}