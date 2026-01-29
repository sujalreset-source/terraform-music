###############################################################
# LOG BUCKET (FOR CLOUDFRONT LOGS)
###############################################################

resource "aws_s3_bucket" "log_bucket" {
  bucket        = "${var.log_bucket_name}-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "log_bucket_pab" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "log_bucket_controls" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.log_bucket_controls]

  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_sse" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_policy" "cloudfront_logs_policy" {
  bucket = aws_s3_bucket.log_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontToWriteLogs"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.log_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

###############################################################
# DATA BUCKET
###############################################################

resource "aws_s3_bucket" "data_bucket" {
  bucket        = "${var.data_bucket_name}-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "data_bucket_pab" {
  bucket = aws_s3_bucket.data_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_bucket_sse" {
  bucket = aws_s3_bucket.data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "data_bucket_controls" {
  bucket = aws_s3_bucket.data_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

###############################################################
# DATA BUCKET FOLDERS
###############################################################

resource "aws_s3_object" "artists_folder" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "artists/"
}

resource "aws_s3_object" "covers_folder" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "covers/"
}

resource "aws_s3_object" "songs_folder" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "songs/"
}

resource "aws_s3_object" "songs_hls_folder" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "songs-hls/"
}

resource "aws_s3_object" "songs_hls_test_folder" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "songs-hls-test/"
}

resource "aws_s3_bucket_logging" "data_bucket_logging" {
  bucket        = aws_s3_bucket.data_bucket.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "cloudfront/"
}

###############################################################
# CORS
###############################################################

resource "aws_s3_bucket_cors_configuration" "data_bucket_cors" {
  bucket = aws_s3_bucket.data_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

###############################################################
# VARIABLES FOR DYNAMIC POLICY
###############################################################

locals {
  cf_enabled = length(var.cloudfront_distribution_arns) > 0
}

###############################################################
# DYNAMIC PUBLIC ACCESS POLICY
###############################################################

data "aws_iam_policy_document" "data_bucket_public" {
  dynamic "statement" {
    for_each = var.public_prefixes

    content {
      sid     = "PublicAccessTo${replace(statement.value, "-", "_")}"
      effect  = "Allow"
      actions = ["s3:GetObject"]

      principals {
        # This produces "Principal": "*"
        type        = "*"
        identifiers = ["*"]
      }

      resources = [
        "${aws_s3_bucket.data_bucket.arn}/${statement.value}/*"
      ]
    }
  }
}

###############################################################
# CLOUDFRONT ACCESS POLICY
###############################################################

data "aws_iam_policy_document" "data_bucket_cloudfront" {
  count = local.cf_enabled ? 1 : 0

  statement {
    sid     = "AllowCloudFrontServicePrincipal"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    resources = [
      "${aws_s3_bucket.data_bucket.arn}/*"
    ]

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values   = var.cloudfront_distribution_arns
    }
  }
}

###############################################################
# COMBINE POLICIES
###############################################################

data "aws_iam_policy_document" "data_bucket_combined" {
  source_policy_documents = concat(
    [data.aws_iam_policy_document.data_bucket_public.json],
    local.cf_enabled ? [data.aws_iam_policy_document.data_bucket_cloudfront[0].json] : []
  )
}

###############################################################
# APPLY POLICY
###############################################################

resource "aws_s3_bucket_policy" "cloudfront_read_access" {
  bucket = aws_s3_bucket.data_bucket.id
  policy = data.aws_iam_policy_document.data_bucket_combined.json
}
