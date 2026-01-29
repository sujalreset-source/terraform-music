variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name: dev, staging, prod"
  type        = string
}

variable "project_name" {
  description = "Name of the project for tagging and naming resources"
  type        = string
  default     = "reset-streaming"
}

# ------------------------------------------------------------
# REQUIRED for dynamic CloudFront integration
# ------------------------------------------------------------
variable "cloudfront_distribution_ids" {
  description = "List of CloudFront Distribution IDs used for S3 access"
  type        = list(string)
  default     = []
}

# (Optional) – you can override bucket names if needed
variable "log_bucket_name" {
  description = "Log bucket name prefix"
  type        = string
  default     = "cloudfront-logs-yourapp"
}

variable "data_bucket_name" {
  description = "Data bucket name prefix"
  type        = string
  default     = "reset-streaming"
}


