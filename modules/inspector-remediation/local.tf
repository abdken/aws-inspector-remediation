locals{
    l_remediation_bucket = data.aws_cloudformation_stack.remediation_inspector_runbook.outputs["InstallOverrideListS3BucketName"]
    l_remediation_assumerole = data.aws_cloudformation_stack.remediation_inspector_runbook.outputs["AutomationAssumeRole"]
    l_remediation_runbook = data.aws_cloudformation_stack.remediation_inspector_runbook.outputs["AutomationRunbookName"]
    l_sns_topic = module.inspector_remediation_sns.sns_arn

}