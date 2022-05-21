variable "vpc_id" {
  type        = string
  description = "The name of ECS"
}

variable "ecs_name" {
  type        = string
  description = "The name of ECS"
}

variable "log_group_name" {
  type = string
  description = "The log group for Cloudwatch when creating ECS"
}

variable "retention_in_days" {
  type =number
  default = 7
  description = "The retention days for saving log in Cloudwatch"
}

variable "vpc_subnets_id" {
  type = set(string)
  description = "The subnet ids for creating EC2 instances"
}

variable "ecs_tags" {
  description = "A map of tags to add to ECS"
  type        = map(string)
  default     = {}
}