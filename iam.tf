resource "aws_iam_role" "lambda_exec" {
  name = "${var.stackname}-url-redirect-lambda-role"
  assume_role_policy = jsonencode({
    Version : "2012-10-17"
    Statement : [{
      Effect    : "Allow"
      Principal : { Service : "lambda.amazonaws.com" }
      Action    : "sts:AssumeRole"
    }]
  })
}

# Attach the managed policy that grants:
#   logs:CreateLogGroup / logs:CreateLogStream / logs:PutLogEvents
resource "aws_iam_role_policy_attachment" "basic_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for enhanced logging permissions
resource "aws_iam_role_policy" "enhanced_logging" {
  name = "${var.stackname}-enhanced-logging-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.stackname}",
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.stackname}:*"
        ]
      }
    ]
  })
}

