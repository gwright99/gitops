terraform {
    required_version = ">= 1.1.6"
}

# Retrieve the default vpc for the region
data "aws_vpc" "default" {
  default = true
}

# `aws_subnet_ids` deprecated. Replacing.
data "aws_subnets" "all_default_subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Inline JSON can't have leading spaces. Externalize to TFTPL file.
# Use variables to keep the amount of "../" to a minimum.
resource "aws_iam_role" "batch_role" {
  name               = "batch_role"
  assume_role_policy = templatefile(
    "${var.tf_root}/assets/templates/batch_role.tftpl", {})

  tags = var.tf_common_tags
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

  tags = var.tf_common_tags
}