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
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "AWSCLI"
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

module "my_iam_resources" {
  source = "../modules/iam"

  main_args = local.context
}

module "my_batch_resources" {
  source = "../modules/batch"

  tf_root = local.tf_root
  tf_common_tags = local.common_tags
}

module "my_lambda_resources" {
  source = "../modules/lambda"

  main_args = local.context
  lambda_exec_role_arn = module.my_iam_resources.lambda_exec_role_arn
}

module "my_cloudwatch_resources" {
  source = "../modules/cloudwatch"

  main_args = local.context
  lambda_function_name = module.my_lambda_resources.lambda_function_name
}




