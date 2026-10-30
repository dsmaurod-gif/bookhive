
# AMI oficial de Amazon Linux 2023
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Application Load Balancer
resource "aws_lb" "principal" {
  name               = "${var.proyecto}-${var.entorno}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_alb_id]
  subnets            = var.subredes_publicas_ids

  tags = {
    Name     = "${var.proyecto}-${var.entorno}-alb"
    Proyecto = var.proyecto
    Entorno  = var.entorno
  }
}

# Target Group
resource "aws_lb_target_group" "app" {
  name        = "${var.proyecto}-${var.entorno}-tg"
  port        = var.puerto_app
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.proyecto}-${var.entorno}-tg"
  }
}

# Listener HTTP
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.principal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "${var.proyecto}-${var.entorno}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.sg_app_id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y python3
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name     = "${var.proyecto}-${var.entorno}-sync"
      Proyecto = var.proyecto
      Entorno  = var.entorno
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                = "${var.proyecto}-${var.entorno}-asg"
  min_size            = var.asg_min
  max_size            = var.asg_max
  desired_capacity    = var.asg_deseado
  vpc_zone_identifier = var.subredes_aplicacion_ids

  target_group_arns = [
    aws_lb_target_group.app.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.proyecto}-${var.entorno}-sync"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
