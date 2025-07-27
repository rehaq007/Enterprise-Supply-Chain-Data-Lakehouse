variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "data_bucket" {
  description = "S3 bucket for raw/processed/archive/quarantine"
  type        = string
}

variable "code_bucket" {
  description = "S3 bucket where Lambda ZIPs and Glue scripts live"
  type        = string
}

variable "lambda_code_s3_key_trigger" {
  description = "S3 key for trigger-glue Lambda ZIP"
  type        = string
}

variable "lambda_code_s3_key_notifier" {
  description = "S3 key for glue completion notifier Lambda ZIP"
  type        = string
}

variable "glue_script_s3_path" {
  description = "Full S3 URI of the Glue ETL script"
  type        = string
}

variable "glue_job_name" {
  description = "Name of the Glue ETL job"
  type        = string
  default     = "supply-chain-iceberg-job"
}

variable "glue_database_name" {
  description = "Glue Data Catalog database"
  type        = string
  default     = "supply_chain_db"
}

variable "sns_topic_name" {
  description = "SNS topic for pipeline notifications"
  type        = string
  default     = "dehtopic"
}

variable "notification_email" {
  description = "Email address to subscribe to SNS alerts"
  type        = string
}
