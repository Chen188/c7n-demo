output "tf-backend-bkt" {
    value = aws_s3_bucket.tf-backend-bkt.id
}

output "tf-backend-ddb-tbl" {
    value = aws_dynamodb_table.tf-backend-tbl.name
}

output "tf-backend-bkt-key-alias" {
    value = aws_kms_alias.tf-backend-bkt-key-alias.name
}