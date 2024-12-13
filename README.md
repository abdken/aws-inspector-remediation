# aws-inspector-remediation
inspector-remediation

## Dependencies
- AWS account
- Terraform ~> 4.11.0
- python3.8


```

module "inspector_remediation" {
  source = "./modules/inspector-remediation"
  organization_id = <organization_id>
  account_id = var.accountid
  environment_name = var.environment_name
  cw_event_schedule_expression = "rate(30 minutes)"
  inspector_sns_email_topic = <target-channel/email>
  lambda_variables = {
      "ACCOUNT_ID" = var.accountid,
      "RPT" = "yes",
      "RPT_CONTROL" = "yes",
      "ENV" = var.environment_name,
      "CVE_DAYS_AGE" = 14
      "TITLE_START_WITH" = "CVE"
      "REMEDIATION_SLACK_INFO" = "yes",
      "REMEDIATION_SLACK_ALARM" = "yes",
      "REMEDIATION_REBOOT_TAG_KEY" = "remediation_reboot",
      "REMEDIATION_REBOOT_TAG_VALUE" = "true",
      "REMEDIATION_SCAN_TAG_KEY" = "remediation",
      "REMEDIATION_SCAN_TAG_VALUE" = "true"
  }
}

```
