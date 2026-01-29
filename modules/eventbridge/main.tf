# MediaConvert job state change rule
resource "aws_cloudwatch_event_rule" "mediaconvert_job_state" {
  name        = "${var.project_name}-${var.environment}-mediaconvert-job-state"
  description = "Trigger Lambda when MediaConvert job completes or errors"
  event_bus_name = "default"

  event_pattern = jsonencode({
    "source": ["aws.mediaconvert"],
    "detail-type": ["MediaConvert Job State Change"],
    "detail": {
      "status": ["COMPLETE"]
    }
  })
}

# Target Lambda (HandleHLSComplete)
resource "aws_cloudwatch_event_target" "mediaconvert_to_lambda" {
  rule      = aws_cloudwatch_event_rule.mediaconvert_job_state.name
  target_id = "InvokeHandleHLSComplete"
  arn       = var.target_lambda_arn
  role_arn  = aws_iam_role.eventbridge_target_role.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.target_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.mediaconvert_job_state.arn
}

# IAM role used by EventBridge to invoke the Lambda target
resource "aws_iam_role" "eventbridge_target_role" {
  name               = "${var.project_name}-${var.environment}-eventbridge-target-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "events.amazonaws.com" },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_target_invoke_lambda" {
  name = "${var.project_name}-${var.environment}-eventbridge-target-invoke-lambda"
  role = aws_iam_role.eventbridge_target_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["lambda:InvokeFunction"],
        Resource = [var.target_lambda_arn, "${var.target_lambda_arn}:*"]
      }
    ]
  })
}
