module "inspector_remediation_sns" {
    source = "../modules/sns"
    enable_topic_subscription = true
    sns_email = var.inspector_sns_email_topic
    sns_topic_name = "aws-inspector-sns-remediation"
    envirnoment = var.environment_name
}