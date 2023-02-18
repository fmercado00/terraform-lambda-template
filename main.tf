provider "aws" {
  region = "us-east-2"
}

data "archive_file" "python_lambda_package" {
  type        = "zip"
  source_file = "./code/lambda_function.py"
  output_path = "lambda_function.zip"
}

/*
  Create the lamda function
*/
resource "aws_lambda_function" "simplification_lambda_function" {
  function_name = "lambdaTestTemplate"

  filename         = "lambda_function.zip"
  source_code_hash = data.archive_file.python_lambda_package.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.9"
  handler          = "lambda_function.lambda_handler"
  timeout          = 10

  environment {
    variables = {
      AWSREGION             = "us-east-2"
      SPEED_ALERT_THRESHOLD = "45"
    }
  }

  tags = {
    cost_center = var.cost_center
    environment = var.environment
    project     = var.project
  }
}

resource "aws_cloudwatch_event_rule" "every_five_minutes" {
    name = "every-five-minutes"
    description = "Fires every five minutes"
    schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "check_foo_every_five_minutes" {
    rule = aws_cloudwatch_event_rule.every_five_minutes.name
    target_id = "simplification_lambda"
    arn = aws_lambda_function.simplification_lambda_function.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
    statement_id = "AllowExecutionFromCloudWatch_simplification_lambda"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.simplification_lambda_function.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.every_five_minutes.arn
}