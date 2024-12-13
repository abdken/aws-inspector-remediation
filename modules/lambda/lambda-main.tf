resource "aws_lambda_function" "this_lambda" {
    filename      = var.lambda_function_zip_file
    function_name = "${var.prefix}_${var.lambda_name}_${var.envirnoment}"
    role          = aws_iam_role.iam_for_lambda.arn
    handler       = var.aws_lambda_function_handler
    description = var.aws_lambda_function_description
    timeout = 890
    layers = var.lambda_layer_activate ? ["${aws_lambda_layer_version.this_lambda_layer[0].arn}"] : null
    # The filebase64sha256() function is available in Terraform 0.11.12 and later
    # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
    # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
    source_code_hash = filebase64sha256("${var.lambda_function_zip_file}")   
    runtime = var.aws_lambda_function_runtime
    tags = var.aws_lambda_function_tags
    environment {
      variables = var.lambda_variables
    }
    depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.this_lambda,
    aws_iam_role.iam_for_lambda
  ]
}

resource "aws_lambda_layer_version" "this_lambda_layer" {
  count = var.lambda_layer_activate ? 1 : 0
  filename            = var.lambda_layer_zip_path
  layer_name          = "${var.prefix}_${var.lambda_name}_layer_${var.envirnoment}"
  source_code_hash    = "${filebase64sha256("${var.lambda_layer_zip_path}")}"
  compatible_runtimes = [var.aws_lambda_function_runtime]
}