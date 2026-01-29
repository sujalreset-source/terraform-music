terraform {
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}
locals {
  environment = "dev"
}

# ------------------------------------------------------------
# 1) CALL S3 MODULE
# ------------------------------------------------------------

module "s3" {
  source = "../../modules/s3"

  project_name     = var.project_name
  environment      = local.environment
  log_bucket_name  = "cloudfront-logs-yourapp"
  data_bucket_name = "reset-streaming"


  cloudfront_distribution_arns = [for id in var.cloudfront_distribution_ids : "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${id}"]
}


# ------------------------------------------------------------
# 2) CALL SQS MODULE
# ------------------------------------------------------------

module "sqs" {
  source = "../../modules/sqs"

  project_name = var.project_name
  environment  = local.environment
}

# ------------------------------------------------------------
# 3) CALL IAM MODULE
# ------------------------------------------------------------

module "iam" {
  source = "../../modules/iam"

  project_name       = var.project_name
  environment        = local.environment
  data_bucket_name   = module.s3.data_bucket_name
  output_bucket_name  = "reset-streaming" 
  sqs_queue_arn      = module.sqs.queue_arn
  sqs_queue_url      = module.sqs.queue_url
  mongodb_secret_arn = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:reset/mongodb/uri*"
}

# # Package Node.mjs Lambda code into ZIPs
# data "archive_file" "s3_to_sqs_zip" {
#   type        = "zip"
#   source_dir  = "../../lambda_code/s3_to_sqs_handler/S3ToSQSHandler.zip"
#   output_path = "../../lambda_code/s3_to_sqs_handler/s3_to_sqs_handler.zip"
# }

# data "archive_file" "sqs_processor_zip" {
#   type        = "zip"
#   source_dir  = "../../lambda_code/sqs_processor/SQSProcessor_MediaConvertJob.zip"
#   output_path = "../../lambda_code/sqs_processor/sqs_processor.zip"
# }

# data "archive_file" "hls_complete_zip" {
#   type        = "zip"
#   source_dir  = "../../lambda_code/handle_hls_complete/src"
#   output_path = "../../lambda_code/handle_hls_complete/handleHLSComplete.zip"
# }

# # ------------------------------------------------------------
# # 4) LAMBDA MODULE (3 Lambdas)
# # ------------------------------------------------------------

# module "lambda" {
#   source = "../../modules/lambda"

#   project_name     = var.project_name
#   environment      = local.environment
#   lambda_role_arn  = module.iam.lambda_role_arn

#   lambda_functions = [

#     # --------------------------------------------------------
#     # Lambda #1 — S3 → SQS
#     # --------------------------------------------------------
#     {
#       name         = "s3-to-sqs"
#       handler      = "index.handler"
#       runtime      = "nodejs22.x"
#       memory_size  = 128
#       timeout      = 10
#       source_path  = data.archive_file.s3_to_sqs_zip.output_path

#       environment_vars = {
#         SQS_QUEUE_URL = module.sqs.queue_url
#       }

#       triggers = [
#         {
#           type        = "s3"
#           bucket_name = module.s3.data_bucket_name
#           bucket_arn  = "arn:aws:s3:::${module.s3.data_bucket_name}"
#           prefix      = "songs/"
#         }
#       ]
#     },

#     # --------------------------------------------------------
#     # Lambda #2 — SQS → MediaConvert
#     # --------------------------------------------------------
#     {
#       name         = "sqs-processor"
#       handler      = "index.handler"
#       runtime      = "nodejs22.x"
#       memory_size  = 256
#       timeout      = 30
#       source_path  = data.archive_file.sqs_processor_zip.output_path

#       batch_size   = 1

#       environment_vars = {
#         MEDIACONVERT_ROLE_ARN = module.iam.mediaconvert_role_arn
#       }

#       triggers = [
#         {
#           type      = "sqs"
#           queue_arn = module.sqs.queue_arn
#         }
#       ]
#     },

#     # --------------------------------------------------------
#     # Lambda #3 — HLS Complete Handler
#     # (Triggered by EventBridge + S3 backup)
#     # --------------------------------------------------------
#     {
#       name         = "hls-complete"
#       handler      = "index.handler"
#       runtime      = "nodejs22.x"
#       memory_size  = 128
#       timeout      = 10
#       source_path  = data.archive_file.hls_complete_zip.output_path

#       environment_vars = {
#         DATA_BUCKET = module.s3.data_bucket_name
#       }

#       triggers = []
#     }
#   ]
# }

#correct lambda path 

# ------------------------------------------------------------
# 4) LAMBDA MODULE (3 Lambdas)
# ------------------------------------------------------------

module "lambda" {
  source = "../../modules/lambda"

  project_name    = var.project_name
  environment     = local.environment
  lambda_role_arn = module.iam.lambda_role_arn

  lambda_functions = [

    # --------------------------------------------------------
    # Lambda #1 — S3 → SQS
    # --------------------------------------------------------
    {
      name        = "s3-to-sqs"
      handler     = "s3_to_sqs_handler/index.handler"
      runtime     = "nodejs22.x"
      memory_size = 128
      timeout     = 10
      source_path = "../../lambda_code/s3_to_sqs_handler/s3_to_sqs_handler.zip"

      environment_vars = {
        SQS_QUEUE_URL = module.sqs.queue_url
      }

      triggers = [
        {
          type        = "s3"
          bucket_name = module.s3.data_bucket_name
          bucket_arn  = "arn:aws:s3:::${module.s3.data_bucket_name}"
          prefix      = "songs/"
        }
      ]
    },

    # --------------------------------------------------------
    # Lambda #2 — SQS → MediaConvert
    # --------------------------------------------------------
    {
      name        = "sqs-processor"
      handler     = "sqs_processor/index.handler"
      runtime     = "nodejs22.x"
      memory_size = 256
      timeout     = 30
      source_path = "../../lambda_code/sqs_processor/sqs_processor.zip"

      batch_size = 1

      environment_vars = {
        MEDIACONVERT_ROLE_ARN = module.iam.mediaconvert_role_arn
        DATA_BUCKET           = module.s3.data_bucket_name
      }

      triggers = [
        {
          type      = "sqs"
          queue_arn = module.sqs.queue_arn
        }
      ]
    },

    # --------------------------------------------------------
    # Lambda #3 — HLS Complete Handler
    # --------------------------------------------------------
    {
      name        = "hls-complete"
      handler     = "handle_hls_complete/index.handler"
      runtime     = "nodejs22.x"
      memory_size = 128
      timeout     = 10
      source_path = "../../lambda_code/handle_hls_complete/handle_hls_complete.zip"

      environment_vars = {
        DATA_BUCKET = module.s3.data_bucket_name
      }

      triggers = []
    }
  ]
}



# ------------------------------------------------------------
# 5) EVENTBRIDGE (Primary trigger for Lambda #3)
# ------------------------------------------------------------

module "eventbridge" {
  source = "../../modules/eventbridge"

  project_name      = var.project_name
  environment       = local.environment
  target_lambda_arn = module.lambda.lambda_arns["hls-complete"]
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  project_name     = var.project_name
  environment      = local.environment
  data_bucket_name = module.s3.data_bucket_name
  logs_bucket_name = module.s3.log_bucket_name
  region           = var.region
}
