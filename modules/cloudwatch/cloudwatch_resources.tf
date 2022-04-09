resource "aws_cloudwatch_log_group" "hello_world" {
  name = "/aws/lambda/${var.lambda_function_name}"

  retention_in_days = 30
}
