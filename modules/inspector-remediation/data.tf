data "aws_cloudformation_stack" "remediation_inspector_runbook" {
  name = "remediation-inspector-runbook"
  depends_on = [
    aws_cloudformation_stack.remediation_inspector_runbook
  ]
}

data "aws_ssm_document" "remediation_inspector_runbook" {
  name            = data.aws_cloudformation_stack.remediation_inspector_runbook.outputs["AutomationRunbookName"]
  depends_on = [
    aws_cloudformation_stack.remediation_inspector_runbook
  ]
}
