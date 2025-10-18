provider "aws" {
    profile                  = "acloudguru"
    shared_credentials_files = ["C:/Users/jinkang.tan/.aws/credentials"]
    region = "us-east-1"
  default_tags {
    tags = local.tags
  }
  
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67.0"
    }
  }

  required_version = ">= 1.4.2"
}