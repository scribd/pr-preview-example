terraform {
  required_version = "~> 1.0.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.44"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Example = "pr-preview"
    }
  }
}
