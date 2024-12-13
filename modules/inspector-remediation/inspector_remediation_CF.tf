resource "aws_cloudformation_stack" "remediation_inspector_runbook" {
  name = "remediation-inspector-runbook"

  parameters = {
    RemediateInspectorFindingCustomActionNoRBTArn = aws_securityhub_action_target.inspector_custom_action_NoRBT.arn
    RemediateInspectorFindingCustomActionRBTArn = aws_securityhub_action_target.inspector_custom_action_RBT.arn,
    OrganizationId = var.organization_id
  }

  template_body = file("${path.module}/resolveInspectorFindingsCFN.yaml")
  depends_on = [
    aws_securityhub_action_target.inspector_custom_action_RBT,
    aws_securityhub_action_target.inspector_custom_action_NoRBT
  ]
  timeout_in_minutes = 15
  disable_rollback = true
  capabilities = ["CAPABILITY_NAMED_IAM", "CAPABILITY_IAM"]
  lifecycle {
    ignore_changes = [
      template_body,
      disable_rollback,
    ]
  }
  
}


resource "aws_cloudformation_stack" "remediation_inspector_automation_execution" {
  name = "remediation-inspector-automation-execution"

  parameters = {
    DelegatedAdministratorAccountId = var.account_id,
    InstallOverrideListBucket = data.aws_cloudformation_stack.remediation_inspector_runbook.outputs["InstallOverrideListS3BucketName"],
    AutomationRunPatchBaselineRunbook = data.aws_cloudformation_stack.remediation_inspector_runbook.outputs["AutomationRunbookName"]
  }

  template_body = file("${path.module}/automationExecutionRole.yaml")
  depends_on = [
    aws_securityhub_action_target.inspector_custom_action_RBT,
    aws_securityhub_action_target.inspector_custom_action_NoRBT,
    aws_cloudformation_stack.remediation_inspector_runbook
  ]
  timeout_in_minutes = 15
  disable_rollback = true
  capabilities = ["CAPABILITY_NAMED_IAM", "CAPABILITY_IAM"]
  lifecycle {
    ignore_changes = [
      template_body,
      parameters.InstallOverrideListBucket,
      parameters.AutomationRunPatchBaselineRunbook,
      disable_rollback,
    ]
  }
  
}

#-----------------
