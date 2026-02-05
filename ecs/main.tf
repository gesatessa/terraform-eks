terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = terraform.workspace
      ProjectName = var.project_name
    }
  }
}


locals {
  prefix = "${var.project_name}-${terraform.workspace}"
}
