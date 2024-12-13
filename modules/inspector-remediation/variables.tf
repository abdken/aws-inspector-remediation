variable "organization_id" {}
variable "account_id" {}
# add
variable "environment_name" {}
variable "lambda_variables" {}
variable "cw_event_schedule_expression" {
    type = string
    default = "rate(10 minutes)"
}

variable "inspector_sns_email_topic" {
  type = string
}

variable "prefix" {
  default = "spaceX"
}