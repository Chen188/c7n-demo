# s3 bkt to store code asset
resource "aws_s3_bucket" "c7n_cicd_asset_bkt" {
  bucket = "c7n-cicd-asset-bkt-binc"
}

resource "aws_s3_bucket_acl" "c7n_cicd_asset_bkt_acl" {
  bucket = aws_s3_bucket.c7n_cicd_asset_bkt.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "c7n_cicd_asset_bkt_versioning" {
  bucket = aws_s3_bucket.c7n_cicd_asset_bkt.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "c7n_cicd_asset_bkt_sse" {
  bucket = aws_s3_bucket.c7n_cicd_asset_bkt.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.c7n_cicd_asset_bkt_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block-c7n_cicd_asset_bkt" {
  bucket = aws_s3_bucket.c7n_cicd_asset_bkt.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# s3 encryption key
resource "aws_kms_key" "c7n_cicd_asset_bkt_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "c7n_cicd_asset_bkt_key_alias" {
  name          = "alias/c7n_cicd_asset_bkt_key"
  target_key_id = aws_kms_key.c7n_cicd_asset_bkt_key.key_id
}