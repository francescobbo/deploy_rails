resource "aws_security_group" "lb_sg" {
  name        = "AppLB"
  description = "Application Load Balancer SG"
  vpc_id      = "${data.terraform_remote_state.network.vpc_id}"

  # Allow HTTP from anywhere.
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # The load balancer only needs to communicate with the application instances.
  # For now, let's allow all outbound communication, we'll fix it later.
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# A Load Balancer will receive incoming requests through its Listeners, which
# will send them to Target Groups.
resource "aws_lb" "app" {
  name            = "app"

  # This LB will receive a publicly addressable IPv4 and IPv6.
  internal        = false
  subnets         = ["${data.terraform_remote_state.network.public_subnet_ids}"]
  ip_address_type = "dualstack"

  security_groups = ["${aws_security_group.lb_sg.id}"]
}

# A Target Group is a group of instances that will handle requests from a
# Listener.
resource "aws_lb_target_group" "app" {
  vpc_id   = "${data.terraform_remote_state.network.vpc_id}"

  # The application instances will be listening on port 80.
  port     = 80
  protocol = "HTTP"

  # The Target Group will start sending traffic only to instances that pass
  # an health check. It will stop sending it if the instances fails the health
  # check a number of times.
  health_check {
    # Number of checks to pass before being considered healthy.
    healthy_threshold = 2

    # Number of checks to fail before being considered unhealthy.
    unhealthy_threshold = 3

    # Wait time before declaring a failed health check.
    # Min: 5, must be smaller than interval.
    timeout = "${var.health_check_timeout}"

    # The endpoint to use as a test. You want to use something lightweight, to
    # avoid generating excessive load on your instances.
    path = "${var.health_check_path}"

    # Time between two health checks. (Min: 5)
    interval = "${var.health_check_interval}"
  }
}

# A Listener is an open port with configurations on a Load Balancer. It
# also specifies how to route incoming requests.
# HTTPS is definitely feasible, but way more involved. To keep things simple,
# we'll only listen for HTTP connections.
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = "${aws_lb.app.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.app.arn}"
    type             = "forward"
  }
}
