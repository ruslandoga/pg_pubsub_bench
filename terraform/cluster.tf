resource "aws_ecs_cluster" "pg_pubsub_bench" {
  name = "pg_pubsub_bench"
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name = "name"
    # aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended
    # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html
    values = ["amzn2-ami-ecs-hvm-*-arm64-ebs"]
  }

  owners = ["amazon"]
}

resource "aws_security_group" "ssh" {
  name   = "ssh"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.myip
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "pg_pubsub_bench" {
  name_prefix = "${aws_ecs_cluster.pg_pubsub_bench.name}-"

  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t4g.micro"

  security_groups = [
    module.vpc.default_security_group_id,
    aws_security_group.ssh.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ecs_instance.id
  key_name             = var.ssh_key

  user_data = <<-EOH
  #cloud-config
  bootcmd:
    - cloud-init-per instance $(echo "ECS_CLUSTER=${aws_ecs_cluster.pg_pubsub_bench.name}" >> /etc/ecs/ecs.config)
  EOH

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "pg_pubsub_bench" {
  name                 = aws_ecs_cluster.pg_pubsub_bench.name
  vpc_zone_identifier  = module.vpc.public_subnets
  launch_configuration = aws_launch_configuration.pg_pubsub_bench.name

  desired_capacity = 2
  min_size         = 2
  max_size         = 4

  health_check_grace_period = 300
  health_check_type         = "EC2"

  tag {
    key                 = "Name"
    value               = "pg_pubsub_bench"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
