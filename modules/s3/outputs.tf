output "log_bucket_name" {
  value = aws_s3_bucket.log_bucket.bucket
}

output "data_bucket_name" {
  value = aws_s3_bucket.data_bucket.bucket
}
