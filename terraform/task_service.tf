resource "aws_ecs_task_definition" "pg_pubsub_bench" {
  family                   = "pg_pubsub_bench"
  requires_compatibilities = ["EC2"]

  memory       = 500
  network_mode = "host"

  container_definitions = <<-EOF
  [
    {
      "image": "${var.docker_image}",
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.log_group.name}",
          "awslogs-region": "eu-north-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "portMappings": [
        {
          "hostPort": 4369,
          "protocol": "tcp",
          "containerPort": 4369
        },
        {
          "hostPort": 4370,
          "protocol": "tcp",
          "containerPort": 4370
        }
      ],
      "environment": [
        {"name": "RELEASE_COOKIE", "value": "kka+STG7DXGVweA24KXsKkb+oBVMg7RHd9t5i3KrkUD0e1GBYr2VLO1xG7p+IxFY"}
      ],
      "essential": true,
      "name": "pg_pubsub_bench"
    }
  ]
  EOF
}

resource "aws_ecs_service" "pg_pubsub_bench" {
  name        = "pg_pubsub_bench"
  cluster     = aws_ecs_cluster.pg_pubsub_bench.id
  launch_type = "EC2"

  task_definition     = aws_ecs_task_definition.pg_pubsub_bench.arn
  deployment_minimum_healthy_percent = 50
  desired_count = 2

  service_registries {
    registry_arn   = aws_service_discovery_service.pg_pubsub_bench.arn
    container_name = "pg_pubsub_bench"
    container_port = 4369
  }
}
