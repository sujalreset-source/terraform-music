variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "data_bucket_name" {
  type = string
}

variable "sqs_queue_arn" {
  type = string
}

variable "sqs_queue_url" {
  type = string
}

variable "mongodb_secret_arn" {
  type = string
}

variable "output_bucket_name" {
  description = "S3 bucket where MediaConvert will write output files"
  type        = string
}
