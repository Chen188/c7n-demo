
resource "aws_lb_target_group" "tg_ip" {
  name        = "TargetGroup"
  port        = 80
  target_type = "ip"
  protocol    = "HTTP"
  vpc_id      = module.vpc_main.vpc_id
}

resource "aws_alb_target_group_attachment" "tgattachment" {
  target_group_arn = aws_lb_target_group.tg_ip.arn
  target_id        = aws_instance.nginx_vpc_main.private_ip
}

resource "aws_alb_target_group_attachment" "tgattachment-secondary" {
  target_group_arn  = aws_lb_target_group.tg_ip.arn
  target_id         = aws_instance.nginx_vpc_secondary.private_ip
  availability_zone = "all"
}

# alb
resource "aws_lb" "alb" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_elb.id, ]
  subnets            = module.vpc_main.public_subnets
}

# Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.tg_ip.arn
      }
    }
  }
}


# Listener Rule
resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_ip.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}