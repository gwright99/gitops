terraform {
    required_version = ">= 1.1.6"
}

resource "aws_s3_bucket" "bucket1" {
    # bucket = "${var.project}-${var.environment}-grahamwright.net"
    bucket = "${var.context.resource_group}-grahamwright.net"

    tags = var.context.common_tags
}

resource "aws_s3_bucket_acl" "bucket1" {
    bucket = aws_s3_bucket.bucket1.id
    acl = "private"
}

# Deploy Lambda via TF: https://learn.hashicorp.com/tutorials/terraform/lambda-api-gateway
data "archive_file" "lambda_hello_world" {

  type = "zip"
  source_dir = "${var.context.tf_root}/src/hello-world"
  output_path = "${var.context.tf_root}/src/hello-world.zip"
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
  role = var.lambda_execution_role_arn

  tags = var.context.common_tags

}

resource "aws_cloudwatch_log_group" "hello_world" {
  name = "/aws/lambda/${aws_lambda_function.hello_world.function_name}"

  retention_in_days = 30
  tags = var.context.common_tags
}