###############################################################
# Lambda Function Creation
###############################################################

resource "aws_lambda_function" "lambda" {
  for_each = { for l in var.lambda_functions : l.name => l }

  function_name = "${var.project_name}-${var.environment}-${each.value.name}"
  role          = var.lambda_role_arn

  handler     = each.value.handler
  runtime     = each.value.runtime
  timeout     = each.value.timeout
  memory_size = each.value.memory_size

  filename         = each.value.source_path
  source_code_hash = filebase64sha256(each.value.source_path)

  environment {
    variables = each.value.environment_vars
  }
}

###############################################################
# S3 → Lambda Trigger (Backup trigger)
# Note: This will manage notifications for buckets used here.
###############################################################

resource "aws_s3_bucket_notification" "s3_trigger" {
  for_each = {
    for l in var.lambda_functions :
    l.name => l
    if length([
      for t in l.triggers : t
      if t.type == "s3"
    ]) > 0
  }

  bucket = one([
    for t in each.value.triggers : t.bucket_name
    if t.type == "s3"
  ])

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda[each.key].arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = one([
      for t in each.value.triggers : t.prefix
      if t.type == "s3"
    ])
  }

  # ensure lambda and permissions created first
  depends_on = [
    aws_lambda_permission.allow_s3,
    aws_lambda_function.lambda
  ]
}

resource "aws_lambda_permission" "allow_s3" {
  for_each = {
    for l in var.lambda_functions :
    l.name => l
    if length([
      for t in l.triggers : t
      if t.type == "s3"
    ]) > 0
  }

  statement_id  = "AllowExecutionFromS3-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda[each.key].function_name
  principal     = "s3.amazonaws.com"

  source_arn = one([
    for t in each.value.triggers : t.bucket_arn
    if t.type == "s3"
  ])
}

###############################################################
# SQS → Lambda Trigger
###############################################################

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  for_each = {
    for l in var.lambda_functions :
    l.name => l
    if length([
      for t in l.triggers : t
      if t.type == "sqs"
    ]) > 0
  }

  event_source_arn = one([
    for t in each.value.triggers : t.queue_arn
    if t.type == "sqs"
  ])

  # AWS expects function name (or ARN) but best to use function name
  function_name = aws_lambda_function.lambda[each.key].function_name
  batch_size    = lookup(each.value, "batch_size", 1)
  maximum_retry_attempts = lookup(each.value, "maximum_retry_attempts", null)
  maximum_record_age_in_seconds = lookup(each.value, "maximum_record_age_in_seconds", null)

  metrics_config {
    metrics = ["EventCount"]
  }
}

###############################################################
# EventBridge → Lambda Permission (for rules defined elsewhere)
# Only create permission entries for lambdas that declare an eventbridge trigger
#
# Note: the actual EventBridge rule resources live in modules/eventbridge or envs/dev.
###############################################################

resource "aws_lambda_permission" "allow_eventbridge" {
  for_each = {
    for l in var.lambda_functions :
    l.name => l
    if length([
      for t in l.triggers : t
      if t.type == "eventbridge"
    ]) > 0
  }

  statement_id  = "AllowExecutionFromEventBridge-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda[each.key].function_name
  principal     = "events.amazonaws.com"

  source_arn = one([
    for t in each.value.triggers : t.rule_arn
    if t.type == "eventbridge"
  ])
}
