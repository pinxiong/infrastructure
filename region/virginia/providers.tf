terraform {
  required_version = ">= 0.13.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">=3.1.0"
    }
    local = {
      source = "hashicorp/local"
      version = ">=2.1.0"
    }
    template = {
      source = "hashicorp/template"
      version = ">=2.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.1.0"
    }
  }

  backend "s3" {
    //NOTE: make sure the bucket exists
    // You can create bucket using setup module first
    bucket  = "pin-terraform-state-us-east-1"
    key     = "terraform/backend.tfstate"
    region  = "us-east-1"
    encrypt = "true"
  }
}