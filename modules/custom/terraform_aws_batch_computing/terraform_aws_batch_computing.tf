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

  tags = var.context.common_tags
}