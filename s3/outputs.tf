output "bucket_id" {
  value = aws_s3_bucket.tf_state.id
}

output "bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}
