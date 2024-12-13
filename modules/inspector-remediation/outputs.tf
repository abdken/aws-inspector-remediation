
output "inspector_sns_arn" {
    value = module.inspector_remediation_sns.sns_arn
}

output "inspector_remediation_assumerole" {
    value = data.aws_cloudformation_stack.remediation_inspector_runbook.outputs["AutomationAssumeRole"]
  depends_on = [
    aws_cloudformation_stack.remediation_inspector_runbook
  ]
    
}

output "inspector_remediation_runbook" {
    value = data.aws_cloudformation_stack.remediation_inspector_runbook.outputs["AutomationRunbookName"]
  depends_on = [
    aws_cloudformation_stack.remediation_inspector_runbook
  ]
}

output "inspector_remediation_override_bucket" {
    value = data.aws_cloudformation_stack.remediation_inspector_runbook.outputs["InstallOverrideListS3BucketName"]
  depends_on = [
    aws_cloudformation_stack.remediation_inspector_runbook
  ]
}

