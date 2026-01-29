output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "mediaconvert_role_arn" {
  value = aws_iam_role.mediaconvert_role.arn
}
