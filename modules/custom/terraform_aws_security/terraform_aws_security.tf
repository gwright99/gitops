resource "aws_iam_role" "lambda_execution_role" {
  name = "serverless_lambda"
  assume_role_policy = templatefile(
      "${var.context.tf_root}/assets/templates/lambda_role.tftpl", {})
  
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Sid    = ""
#       Principal = {
#         Service = "lambda.amazonaws.com"
#       }
#       }
#     ]
#   })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


# Inline JSON can't have leading spaces. Externalize to TFTPL file.
# Use variables to keep the amount of "../" to a minimum.
resource "aws_iam_role" "batch_role" {
  name               = "batch_role"
  assume_role_policy = templatefile(
    "${var.context.tf_root}/assets/templates/batch_role.tftpl", {})

  tags = var.context.common_tags
}

# Attach the Batch policy to the Batch role
resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.batch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}