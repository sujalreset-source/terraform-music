###############################################################
# VARIABLES FOR CLOUD FRONT MODULE
###############################################################

variable "project_name" {
  description = "Project name (ex: reset-streaming)"
  type        = string
}

variable "environment" {
  description = "Environment name (ex: dev, staging, prod)"
  type        = string
}

variable "data_bucket_name" {
  description = "S3 bucket used as the CloudFront origin"
  type        = string
}

variable "logs_bucket_name" {
  description = "S3 bucket where CloudFront logs will be stored"
  type        = string
}

variable "region" {
  description = "AWS region of the origin S3 bucket"
  type        = string
}
