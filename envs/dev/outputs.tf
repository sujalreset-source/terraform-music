output "s3_buckets" {
  value = {
    logs_bucket = module.s3.log_bucket_name
    data_bucket = module.s3.data_bucket_name
  }
}

output "sqs_queue" {
  value = {
    queue_url = module.sqs.queue_url
    queue_arn = module.sqs.queue_arn
  }
}

output "lambda_functions" {
  value = module.lambda.lambda_names
}

#output "mediaconvert_template" {
# value = module.mediaconvert.hls_template_name
#}
