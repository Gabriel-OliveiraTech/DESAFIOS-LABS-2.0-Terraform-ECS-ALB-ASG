resource "aws_lb" "bia_alb" {
  name               = "bia-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.bia_alb.id]
  subnets            = [aws_subnet.sub_1.id, aws_subnet.sub_2.id]
}

resource "aws_lb_target_group" "bia_target_group" {
  name_prefix          = "bia-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = local.vpc_bia
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    path                = "/api/versao"
    matcher             = 200
  }
}


resource "aws_alb_listener" "bia_listener" {
  load_balancer_arn = aws_lb.bia_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bia_target_group.arn
   }
  
}


output "alb_dns_name" {
  value = aws_lb.bia_alb.dns_name
}