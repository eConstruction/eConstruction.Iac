# resource "aws_lb" "main" {
#   name               = "main-lb"
#   internal           = false
#   load_balancer_type = "application"
#   subnets            = var.subnets
#   security_groups    = var.security_groups

#   tags = {
#     Name = "MainALB"
#   }
# }

# resource "aws_lb_target_group" "main" {
#   name     = "main-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = var.vpc_id

#   health_check {
#     enabled     = true
#     path        = "/"
#     port        = "80"
#     protocol    = "HTTP"
#     matcher     = "200"
#     interval    = 30
#     timeout     = 5
#     healthy_threshold   = 5
#     unhealthy_threshold = 2
#   }
# }

# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.main.arn
#   }
# }

resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb_econstruction" {
  name               = "econstruction-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets

  enable_deletion_protection = false
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb_econstruction.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_target_group" "app" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-0df8c184d5f6ae949"
  instance_type = "t2.micro"
  subnet_id     = element(var.public_subnets, count.index)
  security_groups = [aws_security_group.alb_sg.id]

  user_data = <<-EOF
                  #!/bin/bash
                  yum update -y
                  yum install -y httpd
                  systemctl start httpd
                  systemctl enable httpd
                  echo "<h1>Server $(hostname -f)</h1>" > /var/www/html/index.html
                EOF

  tags = {
    Name = "WebServer-${count.index + 1}"
  }
}

resource "aws_lb_target_group_attachment" "web" {
  count            = length(aws_instance.web)
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}
