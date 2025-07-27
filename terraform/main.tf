terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

#------------------------------------------------------------
# S3 bucket for data lake
#------------------------------------------------------------
resource "aws_s3_bucket" "data_lake" {
  bucket = var.data_bucket

  versioning {
    enabled = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

#------------------------------------------------------------
# EventBridge integration on the bucket
#------------------------------------------------------------
resource "aws_s3_bucket_notification" "send_to_eventbridge" {
  bucket      = aws_s3_bucket.data_lake.id
  eventbridge = true
}

#------------------------------------------------------------
# SNS topic + email subscription
#------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

#------------------------------------------------------------
# IAM Role for Lambdas
#------------------------------------------------------------
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "events.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda-glue-trigger-notifier-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_extra" {
  name = "lambda-glue-sns-s3-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "sns:Publish",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:CopyObject"
        ]
        Resource = ["*"]
      }
    ]
  })
}

#------------------------------------------------------------
# IAM Role for Glue
#------------------------------------------------------------
resource "aws_iam_role" "glue_service" {
  name = "glue-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "glue.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_s3" {
  role       = aws_iam_role.glue_service.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

#------------------------------------------------------------
# Lambda: trigger and notifier
#------------------------------------------------------------
resource "aws_lambda_function" "trigger_glue" {
  function_name = "trigger-glue-on-s3-upload"
  s3_bucket     = var.code_bucket
  s3_key        = var.lambda_code_s3_key_trigger
  handler       = "lambda_trigger.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 180

  environment {
    variables = {
      GLUE_DATABASE_NAME = var.glue_database_name
      GLUE_JOB_NAME      = var.glue_job_name
      SNS_TOPIC_ARN      = aws_sns_topic.alerts.arn
    }
  }
}

resource "aws_lambda_function" "notify_glue" {
  function_name = "glue-job-completion-notifier"
  s3_bucket     = var.code_bucket
  s3_key        = var.lambda_code_s3_key_notifier
  handler       = "lambda_notifier.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 180

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}

#------------------------------------------------------------
# EventBridge execution IAM Role & Policy
#------------------------------------------------------------
resource "aws_iam_role" "eventbridge_execution" {
  name = "eventbridge-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_execution_policy" {
  name = "eventbridge-execution-policy"
  role = aws_iam_role.eventbridge_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          aws_lambda_function.trigger_glue.arn,
          aws_lambda_function.notify_glue.arn
        ]
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.data_lake.arn,
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = [aws_sns_topic.alerts.arn]
      }
    ]
  })
}

#------------------------------------------------------------
# EventBridge rules & targets
#------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "s3_trigger" {
  name = "s3-to-glue-trigger"

  event_pattern = <<PATTERN
{
  "source":      ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["${var.data_bucket}"]
    },
    "object": {
      "key": [{ "prefix": "raw/" }]
    }
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "s3_trigger_target" {
  rule     = aws_cloudwatch_event_rule.s3_trigger.name
  arn      = aws_lambda_function.trigger_glue.arn
  role_arn = aws_iam_role.eventbridge_execution.arn
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowEventBridgeInvokeTrigger"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_glue.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_trigger.arn
}

resource "aws_cloudwatch_event_rule" "glue_state" {
  name          = "Glue-Job-State-Change"
  event_pattern = <<PATTERN
{"source":["aws.glue"],"detail-type":["Glue Job State Change"],"detail":{"jobName":["${var.glue_job_name}"],"state":["SUCCEEDED","FAILED","TIMEOUT"]}}
PATTERN
}

resource "aws_cloudwatch_event_target" "glue_state_target" {
  rule     = aws_cloudwatch_event_rule.glue_state.name
  arn      = aws_lambda_function.notify_glue.arn
  role_arn = aws_iam_role.eventbridge_execution.arn
}

resource "aws_lambda_permission" "allow_glue" {
  statement_id  = "AllowEventBridgeInvokeNotify"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_glue.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.glue_state.arn
}

#------------------------------------------------------------
# Glue Catalog & Job
#------------------------------------------------------------
resource "aws_glue_catalog_database" "main" {
  name = var.glue_database_name
}

locals {
  iceberg_conf = "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.glue_catalog.warehouse=s3://${var.data_bucket}/processed/ --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO"
}

resource "aws_glue_job" "etl" {
  name     = var.glue_job_name
  role_arn = aws_iam_role.glue_service.arn

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = var.glue_script_s3_path
  }

  default_arguments = {
    "--bucket"             = var.data_bucket
    "--glue_database_name" = var.glue_database_name
    "--conf"               = local.iceberg_conf
  }

  glue_version = "5.0"
  # switch to worker-based scaling:
  worker_type       = "G.1X" # standard 1 DPU worker
  number_of_workers = 3      # max workers

  # overall job timeout in minutes
  timeout = 30

  execution_property {
    max_concurrent_runs = 1
  }
}

#------------------------------------------------------------
# Athena results bucket (dynamic name)
#------------------------------------------------------------
resource "aws_s3_bucket" "athena_results" {
  bucket = "athena-query-results-${var.account_id}-${var.region}"

  # optional: keep this simple, or add encryption, lifecycle, etc.
  acl = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

#------------------------------------------------------------
# Athena Workgroup that writes query results into S3
#------------------------------------------------------------
resource "aws_athena_workgroup" "supply_chain" {
  name        = "supply-chain-wg"
  description = "Workgroup for supply-chain Athena queries with enforced S3 output."

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"
    }
  }
}


