variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "log_bucket_name" {
  type = string
  description = "Bucket for logs"
}

variable "data_bucket_name" {
  type = string
  description = "Bucket for actual streaming data"
}


#variable "cloudfront_distribution_arn" {
 # type        = string
  #description = "The ARN of the CloudFront distribution for OAC access"
  #default     = ""
#}

variable "cloudfront_distribution_arns" {
  type        = list(string)
  description = "List of CloudFront distribution ARNs allowed to read from this bucket"
  default     = []
}
variable "public_prefixes" {
  type        = list(string)
  default     = ["covers", "songs-hls", "artists"]
}
