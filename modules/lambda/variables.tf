variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "lambda_role_arn" {
  type = string
}

variable "lambda_functions" {
  type = list(object({
    name         = string
    handler      = string
    runtime      = string
    memory_size  = number
    timeout      = number
    source_path  = string

    # triggers may include s3, sqs, or eventbridge entries
    triggers     = list(object({
      type        = string       # "s3", "sqs", or "eventbridge"
      bucket_name = optional(string)
      bucket_arn  = optional(string)
      prefix      = optional(string)
      queue_arn   = optional(string)
      rule_arn    = optional(string)  # for eventbridge triggers
    }))

    environment_vars = map(string)

    # optional lambda mapping settings for sqs
    batch_size = optional(number)
    maximum_retry_attempts = optional(number)
    maximum_record_age_in_seconds = optional(number)
  }))
}
