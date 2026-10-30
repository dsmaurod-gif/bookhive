locals {
  prefijo = "${var.proyecto}-${var.entorno}"

  # Carpeta con los playbooks de Ansible (path.root = carpeta terraform/)
  ansible_dir      = "${path.root}/../ansible"
  archivos_ansible = fileset(local.ansible_dir, "**")

  # Huella de todos los archivos de Ansible
  ansible_sha = sha1(join("", [for f in sort(tolist(local.archivos_ansible)) : filesha1("${local.ansible_dir}/${f}")]))
}

data "aws_caller_identity" "actual" {}

# 1. Imagen (AMI) más reciente de Amazon Linux 2023
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 2. Bucket privado con los playbooks de Ansible
resource "aws_s3_bucket" "ansible" {
  bucket        = "${local.prefijo}-ansible-${data.aws_caller_identity.actual.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "ansible" {
  bucket                  = aws_s3_bucket.ansible.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "ansible" {
  for_each = local.archivos_ansible

  bucket = aws_s3_bucket.ansible.id
  key    = "ansible/${each.value}"
  source = "${local.ansible_dir}/${each.value}"
  etag   = filemd5("${local.ansible_dir}/${each.value}")
}

# 3. Rol IAM para las EC2 Sync
data "aws_iam_policy_document" "ec2_confianza" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sync" {
  name               = "${local.prefijo}-sync-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_confianza.json
}

resource "aws_iam_role_policy" "sync" {
  name = "${local.prefijo}-sync-politica"
  role = aws_iam_role.sync.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "LeerPlaybooks"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.ansible.arn}/ansible/*"
      },
      {
        Sid      = "ListarPlaybooks"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.ansible.arn
      },
      {
        Sid      = "EscribirNotas"
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = var.tabla_notas_arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "sync" {
  name = "${local.prefijo}-sync-profile"
  role = aws_iam_role.sync.name
}

# 4. Launch Template con Ansible en user_data
resource "aws_launch_template" "sync" {
  name_prefix   = "${local.prefijo}-sync-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.sync.name
  }

  vpc_security_group_ids = [var.sg_app_id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {
    bucket_ansible = aws_s3_bucket.ansible.id
    region         = var.region
    tabla          = var.tabla_notas_nombre
    entorno        = var.entorno
    puerto_app     = var.puerto_app
    ansible_sha    = local.ansible_sha
  }))

  update_default_version = true

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${local.prefijo}-sync"
    }
  }
}

# 5. Application Load Balancer
resource "aws_lb" "sync" {
  name                       = "${local.prefijo}-alb"
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [var.sg_alb_id]
  subnets                    = var.subredes_publicas
  drop_invalid_header_fields = true
  enable_deletion_protection = false
  idle_timeout               = 3600
}

resource "aws_lb_target_group" "sync" {
  name                 = "${local.prefijo}-sync"
  port                 = var.puerto_app
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.sync.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sync.arn
  }
}

# 6. Auto Scaling Group
resource "aws_autoscaling_group" "sync" {
  name                      = "${local.prefijo}-sync"
  min_size                  = var.asg_min
  max_size                  = var.asg_max
  desired_capacity          = var.asg_deseado
  vpc_zone_identifier       = var.subredes_aplicacion
  target_group_arns         = [aws_lb_target_group.sync.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 600
  wait_for_capacity_timeout = "0"

  launch_template {
    id      = aws_launch_template.sync.id
    version = aws_launch_template.sync.latest_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.prefijo}-sync"
    propagate_at_launch = true
  }

  depends_on = [aws_s3_object.ansible]

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# 7. Política de escalado por CPU (60 %)
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${local.prefijo}-sync-cpu"
  autoscaling_group_name = aws_autoscaling_group.sync.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60
  }
}