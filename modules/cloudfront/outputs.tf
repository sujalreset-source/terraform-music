output "cloudfront_arn" {
  description = "ARN of the CloudFront Distribution"
  value       = aws_cloudfront_distribution.cdn.arn
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront Distribution"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_id" {
  description = "ID of the CloudFront Distribution"
  value       = aws_cloudfront_distribution.cdn.id
}
