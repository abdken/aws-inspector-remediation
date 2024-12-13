resource "aws_lambda_event_source_mapping" "this_sqs" {
    count = var.sqs_enable_event_source_mapping ? 1 : 0
    event_source_arn = var.sqs_event_source_arn
    function_name    = aws_lambda_function.this_lambda.arn
    enabled = var.sqs_enable_event_source_mapping
    batch_size = var.sqs_event_source_batch_size
    depends_on = [
      aws_iam_policy.lambda_sqs_policy,
      aws_lambda_function.this_lambda
    ]
}


# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_sqs_policy" {
  count = var.sqs_enable_event_source_mapping ? 1 : 0
  name        = "${var.prefix}_${var.lambda_name}_lambda_sqs_policy_${var.envirnoment}"
  path        = "/"
  description = "IAM policy for lambda to call sqs"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes"
            ],
            "Resource": "${var.sqs_event_source_arn}"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy" {
  count = var.sqs_enable_event_source_mapping ? 1 : 0
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_sqs_policy[0].arn
  depends_on = [
    aws_iam_policy.lambda_sqs_policy
  ]
}


#####  aws_cloudwatch_event lambda 

resource "aws_cloudwatch_event_rule" "scheduled_event" {
  count = var.cw_scheduled_event ? 1 : 0
  name                = "${var.prefix}_${var.lambda_name}_${var.envirnoment}_scheduled_event"
  description         = "${var.prefix}_${var.lambda_name}_${var.envirnoment}_scheduled_event_description"
  schedule_expression = var.cw_event_rule_schedule_expression
  depends_on = [
    aws_lambda_function.this_lambda
  ]
}

resource "aws_cloudwatch_event_target" "scheduled_event_target" {
  count = var.cw_scheduled_event ? 1 : 0
  rule      = "${aws_cloudwatch_event_rule.scheduled_event[0].name}"
  target_id = "lambda"
  arn       = aws_lambda_function.this_lambda.arn
  depends_on = [
    aws_lambda_function.this_lambda,
    aws_cloudwatch_event_rule.scheduled_event
  ]
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call" {
  count = var.cw_scheduled_event ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${var.prefix}_${var.lambda_name}_${var.envirnoment}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.scheduled_event[0].arn}"
  depends_on = [
    aws_lambda_function.this_lambda,
    aws_cloudwatch_event_rule.scheduled_event
  ]
}