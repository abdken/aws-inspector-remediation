# output "sns_arn" {
#     value = data.aws_sns_topic.this.arn
#     depends_on = [
#       data.aws_sns_topic.this
#     ]
# }


output "sns_arn" {
    value = aws_sns_topic.this.arn
    depends_on = [
      aws_sns_topic.this
    ]
}
data "aws_sns_topic" "this" {
  name = "${aws_sns_topic.this.name}"
  depends_on = [
    aws_sns_topic.this
  ]
}