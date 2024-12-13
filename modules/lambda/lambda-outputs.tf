output "lambda_iam_role_arn" {
    value = aws_iam_role.iam_for_lambda.arn
    depends_on = [
      aws_iam_role.iam_for_lambda
    ]
}

output "lambda_iam_role_name" {
    value = aws_iam_role.iam_for_lambda.name
    depends_on = [
      aws_iam_role.iam_for_lambda
    ]
}