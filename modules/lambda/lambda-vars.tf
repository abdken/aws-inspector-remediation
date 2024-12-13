variable "lambda_name" {
  type = string
}

## like "index.main"
variable "aws_lambda_function_handler" {
  type = string
  default = null
}

variable "aws_lambda_function_description" {
  type = string
  default = null
}

## runtime like "nodejs12.x"
variable "aws_lambda_function_runtime" {
  type = string
  default = null
}

variable "aws_lambda_function_tags" {
  type = map(string)
  default = null
}

variable "envirnoment" {
  type = string
}

variable "sqs_enable_event_source_mapping" {
    type = bool
    default = false
}

variable "sqs_event_source_arn" {
  type = string
  default = null
}

variable "sqs_event_source_batch_size" {
    type = number
    default = 1
}

variable "lambda_variables" {
  type = map(string)
  default = {
    "key" = "value"
  }
}

## add

variable "cw_event_rule_schedule_expression" {
  type = string
  default = "rate(10 minutes)"
}

variable "cw_scheduled_event" {
  type = bool
  default = false
}

variable "lambda_function_zip_file" {
  type = string
  default = "lambda_function_payload.zip"
}

variable "lambda_layer_zip_path" {}

variable "lambda_layer_activate" {
  type = bool
  default = false
}

variable "prefix" {
  default = "spaceX"
}