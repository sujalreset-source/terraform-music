output "lambda_arns" {
  value = {
    for name, fn in aws_lambda_function.lambda :
    name => fn.arn
  }
}

output "lambda_names" {
  value = {
    for name, fn in aws_lambda_function.lambda :
    name => fn.function_name
  }
}
