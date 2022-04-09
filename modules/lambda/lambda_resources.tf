terraform {
    required_version = ">= 1.1.6"
}

resource "aws_s3_bucket" "bucket1" {
    # bucket = "${var.project}-${var.environment}-grahamwright.net"
    bucket = "${var.main_args.resource_group}-grahamwright.net"

    tags = var.main_args.common_tags
}

resource "aws_s3_bucket_acl" "bucket1" {
    bucket = aws_s3_bucket.bucket1.id
    acl = "private"
}

# Deploy Lambda via TF: https://learn.hashicorp.com/tutorials/terraform/lambda-api-gateway
data "archive_file" "lambda_hello_world" {
  type = "zip"

  #source_dir = "${path.module}/hello-world"
#   source_dir = "../src/hello-world"
#   output_path = "../src/hello-world.zip"
  source_dir = "${var.main_args.tf_root}/src/hello-world"
  output_path = "${var.main_args.tf_root}/src/hello-world.zip"
}

resource "aws_s3_object" "lambda_hello_world" {
  # Note the reference to module here
  # bucket = module.create_S3_bucket.bucket1#.id
  bucket = aws_s3_bucket.bucket1.id
  key = "hello-world.zip"
  source = data.archive_file.lambda_hello_world.output_path

  etag = filemd5(data.archive_file.lambda_hello_world.output_path)
}

resource "aws_lambda_function" "hello_world" {
  function_name = "HelloWorld"

  # s3_bucket = module.create_S3_bucket.bucket1#.id
  s3_bucket = aws_s3_bucket.bucket1.id
  s3_key    = aws_s3_object.lambda_hello_world.key

  runtime = "nodejs12.x"
  handler = "hello.handler"

  source_code_hash = data.archive_file.lambda_hello_world.output_base64sha256
  # role = aws_iam_role.lambda_exec.arn
  role = var.lambda_exec_role_arn
}