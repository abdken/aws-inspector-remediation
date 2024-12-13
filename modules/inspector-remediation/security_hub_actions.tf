# aws_securityhub_account custom action

resource "aws_securityhub_action_target" "inspector_custom_action_NoRBT" {
  name        = "Rem-Inspector-NoRBT"
  identifier  = "InspectorRemNoRBT"
  description = "actions without reboot"
}

resource "aws_securityhub_action_target" "inspector_custom_action_RBT" {
  name        = "Rem-Inspector-RBT"
  identifier  = "InspectorRemRBT"
  description = "actions with reboot"
}

# output arn aws_securityhub_action_target 

output "inspector_custom_action_NoRBT_arn" {
  value = aws_securityhub_action_target.inspector_custom_action_NoRBT.arn
}

output "inspector_custom_action_RBT_arn" {
  value = aws_securityhub_action_target.inspector_custom_action_RBT.arn
}