resource "aws_lb" "medusa_alb" {
  name               = "medusa-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.medusa_alb_sg.id]
  subnets            = [aws_subnet.medusa_subnet_1.id, aws_subnet.medusa_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "medusa-alb"
  }
}

resource "aws_lb_target_group" "medusa_tg" {
  name        = "medusa-tg"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.medusa_vpc.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_listener" "medusa_listener" {
  load_balancer_arn = aws_lb.medusa_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.existing_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.medusa_tg.arn
  }
}

resource "aws_lb_listener" "medusa_listener_http" {
  load_balancer_arn = aws_lb.medusa_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
resource "aws_lb_listener_rule" "redirect_to_dashboard" {
  listener_arn = aws_lb_listener.medusa_listener.arn
  priority     = 1

  action {
    type = "redirect"
    redirect {
      path        = "/dashboard"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = [local.full_domain]
    }
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_security_group" "medusa_alb_sg" {
  name_prefix  = "medusa-alb-sg-"
  description  = "Security group for Medusa ALB"
  vpc_id       = aws_vpc.medusa_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "medusa-alb-sg"
    Environment = "production"
    Project     = "medusa"
    Terraform   = "true"
  }
}