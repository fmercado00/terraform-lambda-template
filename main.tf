provider "aws" {
  region = "us-east-2"
}

data "archive_file" "python_lambda_package" {
  type = "zip"
  source_file = "./code/lambda_function.py"
  output_path = "lambda_function.zip"
}

/*
  Create the lamda function
*/
resource "aws_lambda_function" "simplification_lambda_function" {
    function_name = "lambdaTestTemplate"
    
    filename      = "lambda_function.zip"
    source_code_hash = data.archive_file.python_lambda_package.output_base64sha256
    role          = aws_iam_role.lambda_role.arn
    runtime       = "python3.9"
    handler       = "lambda_function.lambda_handler"
    timeout       = 10

    environment {
      variables = {
        AWSREGION = "us-east-2"
        SPEED_ALERT_THRESHOLD = "45"
      }
    }

      tags = {
        cost_center = var.cost_center
        environment = var.environment
        project = var.project
      }

}