resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/ecs/test"
  retention_in_days = 30
}
