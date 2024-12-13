resource "aws_sns_topic" "this" {
  name = "${var.prefix}_${var.sns_topic_name}_${var.envirnoment}"
  display_name = "${var.prefix}_${var.sns_topic_name}_${var.envirnoment}"
  
}

# add
resource "aws_sns_topic_subscription" "target_subscription" {
  count = var.enable_topic_subscription ? 1 : 0
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.sns_email
}
