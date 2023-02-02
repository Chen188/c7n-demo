
locals {
  default_tags = {
    Environment = var.env
    Terraform   = "true"
  }
}

provider "aws" {
  region       = "us-east-1"

  default_tags {
     tags = local.default_tags
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_kms_key" "tf-backend-bkt-key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "tf-backend-bkt-key-alias" {
  name          = "alias/tf-backend-bkt-key"
  target_key_id = aws_kms_key.tf-backend-bkt-key.key_id
}

resource "aws_s3_bucket" "tf-backend-bkt" {
  bucket = "tf-bkt-binc-${random_string.suffix.result}"
}

resource "aws_s3_bucket_acl" "tf-backend-bkt-acl" {
  bucket = aws_s3_bucket.tf-backend-bkt.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "tf-backend-bkt-versioning" {
  bucket = aws_s3_bucket.tf-backend-bkt.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf-backend-bkt-sse" {
  bucket = aws_s3_bucket.tf-backend-bkt.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.tf-backend-bkt-key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.tf-backend-bkt.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf-backend-tbl" {
  name           = "tf-state-${random_string.suffix.result}"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}