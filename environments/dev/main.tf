terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.8.0"
    }
  }

  backend "s3" {
    # Does not seem to be possible to use variables here. Hardcode for now.
    bucket = "terraform.grahamwright.net"
    region = "us-east-1"
    key    = "gitops/learning/dev/terraform.tfstate"
    # dynamodb_table = "<SOME_TABLE>"
  }
}


provider "aws" {
  region                   = var.default_region
  # shared_credentials_files = ["~/.aws/credentials"]
  # profile                  = "AWSCLI"
}


locals {
  # Since idea won't work since you can't put variables into module 
  # source values. Gotta use `../../` instead?!
  tf_root = abspath("${path.module}/../")
  resource_group = "${var.environment}-${var.project}"

  common_tags = {
    CreateBy = "terraform"
    Environment = "${var.environment}"
    Project = "${var.project}"
    ResourceGrouop = local.resource_group
  }

  context = {
    tf_root = abspath("${path.module}/../")
    resource_group = "${var.environment}-${var.project}"

    common_tags = {
      CreatedBy = "terraform"
      Environment = "${var.environment}"
      Project = "${var.project}"
      ResourceGrouop = local.resource_group
    }
  }
}


module "terraform_aws_security" {
  source = "../modules/custom/terraform_aws_security"

  context = local.context
}

module "terraform_aws_application" {
  source = "../modules/custom/terraform_aws_application"

  context = local.context
  lambda_execution_role_arn = module.terraform_aws_security.lambda_execution_role_arn

  depends_on = [
    module.terraform_aws_security
  ]
}


module "terraform_aws_batch_computing" {
  source = "../modules/custom/terraform_aws_batch_computing"

  context = local.context
}




