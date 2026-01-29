##############################################
########      IAM Role for Lambda    #########
##############################################
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

##############################################
########     IAM Role for MediaConvert    ####
##############################################
resource "aws_iam_role" "mediaconvert_role" {
  name = "${var.project_name}-${var.environment}-mediaconvert-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "mediaconvert.amazonaws.com"
      }
    }]
  })
}



##############################################
########     CLOUDWATCH Policy        #########
##############################################
resource "aws_iam_policy" "lambda_cloudwatch_policy" {
  name = "${var.project_name}-${var.environment}-lambda-cloudwatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "*"
    }]
  })
}

##############################################
########        S3 Policy             #########
##############################################
resource "aws_iam_policy" "lambda_s3_policy" {
  name = "${var.project_name}-${var.environment}-lambda-s3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:*"]
      Resource = [
        "arn:aws:s3:::${var.data_bucket_name}",
        "arn:aws:s3:::${var.data_bucket_name}/*"
      ]
    }]
  })
}

##############################################
########     MediaConvert Policy      #########
##############################################
resource "aws_iam_policy" "lambda_mediaconvert_policy" {
  name = "${var.project_name}-${var.environment}-lambda-mediaconvert"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "mediaconvert:*"
      Resource = "*"
    }]
  })
}

##############################################
########        SQS Policy           #########
##############################################
resource "aws_iam_policy" "lambda_sqs_policy" {
  name = "${var.project_name}-${var.environment}-lambda-sqs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ChangeMessageVisibility"
      ]
      Resource = var.sqs_queue_arn
    }]
  })
}

##############################################
########     MediaConvert S3 Policy   #########
##############################################
# resource "aws_iam_policy" "mediaconvert_s3_policy" {
#   name = "${var.project_name}-${var.environment}-mediaconvert-s3"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Action = ["s3:*"]
#       Resource = [
#         "arn:aws:s3:::${var.data_bucket_name}",
#         "arn:aws:s3:::${var.data_bucket_name}/*"
#       ]
#     }]
#   })
# }

resource "aws_iam_policy" "mediaconvert_s3_policy" {
  name = "${var.project_name}-${var.environment}-mediaconvert-s3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.data_bucket_name}",
          "arn:aws:s3:::${var.data_bucket_name}/*",
          "arn:aws:s3:::${var.output_bucket_name}",
          "arn:aws:s3:::${var.output_bucket_name}/*"
        ]
      }
    ]
  })
}



resource "aws_iam_policy" "allow_lambda_send_to_sqs" {
  name        = "${var.project_name}-${var.environment}-lambda-send-to-sqs"
  description = "Allow Lambda to send messages to SQS queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
       Resource = var.sqs_queue_arn 
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.allow_lambda_send_to_sqs.arn
}
##############################################
########    Attach Policies to Roles  #########
##############################################

# Attach CloudWatch to Lambda
resource "aws_iam_role_policy_attachment" "attach_cloudwatch" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_policy.arn
}

# Attach S3 to Lambda
resource "aws_iam_role_policy_attachment" "attach_s3" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

# Attach SQS to Lambda
resource "aws_iam_role_policy_attachment" "attach_sqs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

# Attach MediaConvert Policy to Lambda (IMPORTANT)
resource "aws_iam_role_policy_attachment" "attach_mediaconvert" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_mediaconvert_policy.arn
}

# Attach MediaConvert S3 access to MediaConvert role
resource "aws_iam_role_policy_attachment" "mc_s3_attach" {
  role       = aws_iam_role.mediaconvert_role.name
  policy_arn = aws_iam_policy.mediaconvert_s3_policy.arn
}

##############################################
########  Allow Lambda to Pass MC Role  ######
##############################################
resource "aws_iam_policy" "lambda_passrole_mediaconvert" {
  name = "${var.project_name}-${var.environment}-lambda-passrole-mediaconvert"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = aws_iam_role.mediaconvert_role.arn,
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "mediaconvert.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_passrole_mediaconvert" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_passrole_mediaconvert.arn
}



resource "aws_iam_policy" "allow_lambda_read_mongo_secret" {
  name        = "${var.project_name}-${var.environment}-lambda-read-mongo-secret"
  description = "Allow Lambda to read MongoDB URI from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.mongodb_secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach_mongo_secret_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.allow_lambda_read_mongo_secret.arn
}
