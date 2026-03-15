terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.31.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}


resource "aws_security_group" "secure_sg" {
  name        = "secure-security-group"
  description = "Allow SSH from office network"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.1.0/24"]
  }

}


resource "aws_s3_bucket" "secure_bucket" {
  bucket = "terraform-secure-bucket-example123"
}

# -----------------------
# S3 Versioning
# -----------------------

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.secure_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------
# Public Access Block
# -----------------------

resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------
# Server Side Encryption
# -----------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# -----------------------
# Lifecycle Policy
# -----------------------

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = 365
    }
  }
}

# -----------------------
# Logging
# -----------------------

resource "aws_s3_bucket_logging" "logging" {
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = aws_s3_bucket.secure_bucket.id
  target_prefix = "log/"
}

# -----------------------
# Event Notification
# -----------------------

resource "aws_s3_bucket_notification" "notification" {
  bucket = aws_s3_bucket.secure_bucket.id

  eventbridge = true
}
