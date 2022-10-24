############################################################################################################
# Goal: Create a cron event with cloudwatch
# Path: cloudwatch.tf
# Schedule event
############################################################################################################
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.simplification_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule-lambda.arn
}

resource "aws_cloudwatch_event_rule" "schedule-lambda" {
  name                = "run-lambda-function"
  description         = "Schedule lambda function"
  schedule_expression = "rate(1440 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda-function-target" {
  target_id = "lambda-function-target"
  rule      = aws_cloudwatch_event_rule.schedule-lambda.name
  arn       = aws_lambda_function.simplification_lambda_function.arn
}


############################################################################################################

resource "aws_cloudwatch_log_metric_filter" "error_log_metric_filter" {
  name           = "error-log-metric-filter"
  pattern        = "{ $.Level = \"Error\" }"
  log_group_name = "/aws/lambda/lambdaTestTemplate"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "lambdaTestTemplate"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "error_alarm" {
  alarm_name                = "error-alarm"
  alarm_description         = "Error >= 1"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  period                    = "60"
  threshold                 = "1"
  statistic                 = "Sum"
  metric_name               = aws_cloudwatch_log_metric_filter.error_log_metric_filter.metric_transformation[0].name
  namespace                 = aws_cloudwatch_log_metric_filter.error_log_metric_filter.metric_transformation[0].namespace
  alarm_actions             = [aws_sns_topic.alarm_topic.arn]
  ok_actions                = [aws_sns_topic.alarm_topic.arn]
  insufficient_data_actions = [aws_sns_topic.alarm_topic.arn]

  tags = {
    cost_center = var.cost_center
    environment = var.environment
    project     = var.project
  }
}

resource "aws_cloudwatch_metric_alarm" "invocation_alarm" {
  alarm_name          = "invocation-alarm"
  alarm_description   = "Invocation >= 1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "60"
  threshold           = "1"

  namespace   = "AWS/Lambda"
  metric_name = "Invocations"
  statistic   = "Sum"

  alarm_actions = [aws_sns_topic.alarm_topic.arn]
  ok_actions    = [aws_sns_topic.alarm_topic.arn]
  # insufficient_data_actions = [aws_sns_topic.alarm_topic.arn]

  tags = {
    cost_center = var.cost_center
    environment = var.environment
    project     = var.project
  }
}

resource "aws_sns_topic" "alarm_topic" {
  name = "alarm-topic"
  delivery_policy = jsonencode({
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "minDelayTarget" : 20,
        "maxDelayTarget" : 20,
        "numRetries" : 3,
        "numMaxDelayRetries" : 0,
        "numNoDelayRetries" : 0,
        "numMinDelayRetries" : 0,
        "backoffFunction" : "linear"
      },
      "disableSubscriptionOverrides" : false,
      "defaultThrottlePolicy" : {
        "maxReceivesPerSecond" : 1
      }
    }
  })
  tags = {
    cost_center = var.cost_center
    environment = var.environment
    project     = var.project
  }
}

resource "aws_sns_topic_subscription" "topic_email_subscription" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email"
  endpoint  = "fmercado00@gmail.com"

}