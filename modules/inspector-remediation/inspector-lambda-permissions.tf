data "aws_iam_policy_document" "inspector_lambda_operation_permissions" {
  statement {
    sid = "1"

    actions = [
      "securityhub:GetFindings"
    ]

    resources = [
      format("arn:aws:securityhub:us-east-1:%s:hub/default", var.account_id)
    ]
  }

  statement {
    sid = "2"

    actions = [
      "ssm:StartAutomationExecution"
    ]

    resources = [
      format("arn:aws:ssm:*:%s:automation-definition/%s:*", var.account_id, data.aws_cloudformation_stack.remediation_inspector_runbook.outputs["AutomationRunbookName"])
    ]
  }

  statement {
    sid = "3"

    actions = [
      "iam:PassRole"
    ]

    resources = [
      data.aws_cloudformation_stack.remediation_inspector_runbook.outputs["AutomationAssumeRole"]
    ]
  }

  statement {
    sid = "4"

    actions = [
      "ssm:DescribeAutomationExecutions"
    ]

    resources = ["*"]
  }

  statement {
    sid = "5"

    actions = [
      "sns:Publish"
    ]

    resources = [
        module.inspector_remediation_sns.sns_arn
    ]
  }

  statement {
    sid = "6"

    actions = [
      "ssm:GetAutomationExecution"
    ]

    resources = [
        format("arn:aws:ssm:us-east-1:%s:automation-execution/*", var.account_id)
    ]
  }

  statement {
    sid = "7"

    actions = [
      "ec2:RebootInstances"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "remediation_operation_policy" {
  name   = format("%s_aws-inspector-lambda-remediation_operation_policy_%s", var.prefix, var.environment_name)
  path   = "/"
  policy = data.aws_iam_policy_document.inspector_lambda_operation_permissions.json
  depends_on = [
    module.inspector_lambda_remediation
  ]
}

resource "aws_iam_role_policy_attachment" "remediation_operation_policy" {
  policy_arn = aws_iam_policy.remediation_operation_policy.arn
  role       = module.inspector_lambda_remediation.lambda_iam_role_name
  depends_on = [
    aws_iam_policy.remediation_operation_policy
  ]
}