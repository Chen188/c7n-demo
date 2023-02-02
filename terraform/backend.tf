terraform {
  backend "s3" {
    bucket         = "tf-bkt-binc-mhk1jyez"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "alias/tf-backend-bkt-key"
    dynamodb_table = "tf-state-mhk1jyez"
  }
}