#########################
# AWS inspector remediation
#########################

module "inspector_lambda_remediation" {
  source = "../modules/lambda"
  lambda_name = "aws-inspector-lambda-remediation"
  lambda_function_zip_file = "${path.module}/inspector_lambda_files.zip"
  aws_lambda_function_handler = "main.main"
  aws_lambda_function_runtime = "python3.8"
#   aws_lambda_function_tags = ""
  envirnoment = var.environment_name
#   sqs_enable_event_source_mapping = false
  lambda_variables = merge(var.lambda_variables,
  {
    "REMEDIATION_BUCKET" = local.l_remediation_bucket,
    "REMEDIATION_ASSUMEROLE" = local.l_remediation_assumerole,
    "REMEDIATION_RUNBOOK" = local.l_remediation_runbook,
    "SNS_TOPIC" = local.l_sns_topic
  }
  )
  cw_scheduled_event = true
  cw_event_rule_schedule_expression = var.cw_event_schedule_expression
  lambda_layer_activate = true
  lambda_layer_zip_path = "${path.module}/inspector-lambda-python-layer.zip"
  depends_on = [
    data.archive_file.lambda-archive
  ]

}


## lambda files

data "archive_file" "lambda-archive" {
  type        = "zip"
  source_file = "${path.module}/main.py"
  output_path = "${path.module}/inspector_lambda_files.zip"
  output_file_mode = "0777"
  # excludes = ["string"]
}
