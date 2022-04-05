terraform {
    required_version = ">= 1.1.6"
}

resource "aws_s3_bucket" "bucket1" {
    bucket = "${var.project}-${var.environment}-grahamwright.net"

    tags = {
        Name = "${var.project}-${var.environment}-nametag"
        Environment = "${var.environment}-envtag"
        CustomTag = var.tag_for_bucket
    }
}

resource "aws_s3_bucket_acl" "bucket1" {
    bucket = aws_s3_bucket.bucket1.id
    acl = "private"
}