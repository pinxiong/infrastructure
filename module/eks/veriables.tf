variable "name" {
  type        = string
  description = "The EKS name"
}

variable "vpc_id" {
  type        = string
  description = "The VPC id"
}

variable "public_subnets_id" {
  description = "The public subnets id"
  type        = list
}

variable "private_subnets_id" {
  description = "The private subnets id"
  type        = list
}

variable "desired_size" {
  description = "The desired size of node"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "The maximum size of node"
  type        = number
}

variable "min_size" {
  description = "The minimum size of node"
  type        = number
  default     = 0
}

variable "security_group_ids" {
  description = "The security groups to access EKS"
  type        = list
  default     = []
}

variable "eks_tags" {
  description = "A map of tags to add to EKS"
  type        = map(string)
  default     = {}
}
