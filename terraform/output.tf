output "data_bucket" { value = aws_s3_bucket.data_lake.bucket }
output "sns_topic_arn" { value = aws_sns_topic.alerts.arn }
output "trigger_lambda" { value = aws_lambda_function.trigger_glue.function_name }
output "notifier_lambda" { value = aws_lambda_function.notify_glue.function_name }
output "glue_job" { value = aws_glue_job.etl.name }
output "glue_database" { value = aws_glue_catalog_database.main.name } 
