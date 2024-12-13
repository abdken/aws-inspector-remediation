resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.prefix}_${var.lambda_name}_lambda_role_${var.envirnoment}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


