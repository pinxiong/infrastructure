variable "name" {
  type        = string
  description = "The VPC name"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block of the vpc"
}

variable "public_subnets_cidr_block" {
  type        = list
  description = "CIDR block for Public Subnet"
}

variable "private_subnets_cidr_block" {
  type        = list
  description = "CIDR block for Private Subnet"
}

variable "availability_zones" {
  type        = list
  description = "AZ in which all the resources will be deployed"
}

variable "vpc_tags" {
  description = "A map of tags to add to VPC"
  type        = map(string)
  default     = {}
}
