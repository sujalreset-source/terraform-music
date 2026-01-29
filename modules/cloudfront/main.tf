###############################################################
# CLOUD FRONT DISTRIBUTION FOR HLS STREAMING
###############################################################

locals {
  origin_id = "${var.project_name}-${var.environment}-origin"
  
}
###############################################################
# ORIGIN ACCESS CONTROL (OAC)
###############################################################

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for CloudFront → S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

###############################################################
# MAIN CLOUD FRONT DISTRIBUTION
###############################################################

resource "aws_cloudfront_distribution" "cdn" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name}-${var.environment}-cdn"
  default_root_object = ""

  ###############################################################
  # ORIGIN → S3 (FIXED BUCKET NAMING)
  ###############################################################

  origin {
    domain_name              = "${var.data_bucket_name}-${var.environment}.s3.${var.region}.amazonaws.com"
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  ###############################################################
  # DEFAULT CACHE BEHAVIOR
  ###############################################################

  default_cache_behavior {
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    # AWS CachingOptimized Managed Policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  ###############################################################
  # GEO RESTRICTION
  ###############################################################

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  ###############################################################
  # PRICE CLASS
  ###############################################################

  price_class = "PriceClass_All"

  ###############################################################
  # LOGGING (FIXED)
  ###############################################################
/*
  logging_config {
    bucket          = "${var.log_bucket_name}-${var.environment}.s3.amazonaws.com"
    prefix          = "cloudfront/"
    include_cookies = false
  }
*/
  ###############################################################
  # SSL CERTIFICATE
  ###############################################################

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.project_name}-cdn"
    Environment = var.environment
  }
}
