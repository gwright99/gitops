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

# Retrieve the default vpc for the region
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all_default_subnets" {
  # Passing the VPC ID in for the execution.
  vpc_id = data.aws_vpc.default.id
}

# IAM Role for batch processing
# JSON can't have leading spaces. ugly.
resource "aws_iam_role" "batch_role" {
  name               = "batch_role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":
    [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
            "Service": "batch.amazonaws.com"
        }
    }
    ]
}
    EOF

  tags = {
    created-by = "terraform"
  }
}

# Attach the Batch policy to the Batch role
resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.batch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# Security Group for batch processing
resource "aws_security_group" "batch_security_group" {
  name        = "batch_security_group"
  description = "AWS Batch Security Group for batch jobs"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    created-by = "terraform"
  }
}

module "create_S3_bucket" {
    source = "../../modules/S3/testbucket"
    tag_for_bucket = "made_with_tf"
    # These are the vars defined in /setups/dev/
    environment = var.environment
    project = var.project
}

# Deploy Lambda via TF: https://learn.hashicorp.com/tutorials/terraform/lambda-api-gateway
data "archive_file" "lambda_hello_world" {
  type = "zip"

  #source_dir = "${path.module}/hello-world"
  source_dir = "../../src/hello-world"
  output_path = "../../src/hello-world.zip"
}

resource "aws_s3_object" "lambda_hello_world" {
  # Note the reference to module here
  bucket = module.create_S3_bucket.bucket1#.id
  key = "hello-world.zip"
  source = data.archive_file.lambda_hello_world.output_path

  etag = filemd5(data.archive_file.lambda_hello_world.output_path)
}

resource "aws_lambda_function" "hello_world" {
  function_name = "HelloWorld"

  s3_bucket = module.create_S3_bucket.bucket1#.id
  s3_key    = aws_s3_object.lambda_hello_world.key

  runtime = "nodejs12.x"
  handler = "hello.handler"

  source_code_hash = data.archive_file.lambda_hello_world.output_base64sha256
  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "hello_world" {
  name = "/aws/lambda/${aws_lambda_function.hello_world.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}