variable "vpc_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "instance_ami" {
  type    = string
  default = "ami-0f9fc25dd2506cf6d"
}

variable "public_subnets_id" {
  description = "The public subnet id"
  type        = list
}

variable "security_group_ids" {
  description = "The security group for jump server"
  type        = list
  default = []
}

variable "shared_tags" {
  description = "A map of tags to add to Jump Server"
  type        = map(string)
  default     = {}
}
