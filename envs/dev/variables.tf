variable "project_name" {
  type    = string
  default = "reset-streaming"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "cloudfront_distribution_arns" {
  type        = list(string)
  description = "CloudFront distribution ARNs that can access the bucket"
  default     = []
}

variable "cloudfront_distribution_ids" {
  type        = list(string)
  description = "List of CloudFront distribution IDs to allow in S3 policy"
  default     = []
}

