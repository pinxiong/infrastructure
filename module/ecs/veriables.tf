variable "vpc_id" {
  type        = string
  description = "The vpc id"
}

variable "account_id" {
  type = string
  description = "The aws account id."
}

variable "region" {
  type        = string
  description = "The region of workshop"
}

variable "project_name" {
  type        = string
  description = "The project name"
}

variable "image_name" {
  type        = string
  description = "The image name"
}

variable "vpc_private_subnets_id" {
  description = "The private subnets id"
  type        = list
}

variable "vpc_public_subnets_id" {
  description = "The public subnets id"
  type        = list
}

variable "ecs_cluster_name" {
  type        = string
  description = "The name of ecs cluster"
}

variable "ecs_service_name" {
  type        = string
  description = "The name of ecs service"
}

variable "max_capacity" {
  type = number
  description = "The maximum capacity of tasks in ecs"
}

variable "min_capacity" {
  type = number
  default = 1
  description = "The minimum capacity of tasks in ecs"
}

variable "health_check_grace_period_seconds" {
  type        = number
  default     = 10
  description = "The time period for health check in seconds."
}

variable "cpu" {
  type        = number
  description = "The cup unit"
}

variable "memory" {
  type        = number
  description = "The memory size MB"
}

variable "ecs_tags" {
  description = "A map of tags to add to ecs"
  type        = map(string)
  default     = {}
}