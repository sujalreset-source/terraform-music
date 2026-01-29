# Dead Letter Queue
#resource "aws_sqs_queue" "dlq" {
 # name = "${var.project_name}-${var.environment}-songs-dlq"

  #message_retention_seconds = 1209600  # 14 days
#}

# Main processing queue
resource "aws_sqs_queue" "main" {
  name = "${var.project_name}-${var.environment}-songs-processing-queue"

  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600  # 4 days

  #redrive_policy = jsonencode({
#    deadLetterTargetArn = aws_sqs_queue.dlq.arn
   # maxReceiveCount     = var.max_receive_count
  #})
}

data "aws_caller_identity" "current" {}

resource "aws_sqs_queue_policy" "main_policy" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "__default_policy_ID",
    Statement = [
      {
        Sid       = "__owner_statement",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = "SQS:*",
        Resource  = aws_sqs_queue.main.arn
      }
    ]
  })
}
