resource "aws_security_group" "app_instance" {
  name        = "App"
  description = "App Instance SG"
  vpc_id      = "${data.terraform_remote_state.network.vpc_id}"

  # Allow HTTP from the Load Balancer SG.
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.lb_sg.id}"]
  }

  # Allow all outbound traffic from the Application instances.
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Let's launch a cluster of Ubuntu instances for example.
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# A Launch Configuration defines the parameters to start the new instance.
# It resembles more or less the Wizard for starting a new EC2 instances. In
# particular it defines: instance type, AMI, security groups, EBS disks and more.
resource "aws_launch_configuration" "app" {
  image_id          = "${data.aws_ami.ubuntu.id}"
  instance_type     = "${var.app_instance_type}"
  key_name          = "${data.terraform_remote_state.network.admin_key_name}"

  security_groups   = ["${aws_security_group.app_instance.id}"]

  enable_monitoring = "${var.detailed_monitoring}"
  ebs_optimized     = "${var.ebs_optimized_instances}"
}

resource "aws_autoscaling_group" "app" {
  # Sets which configuration are we scaling.
  launch_configuration      = "${aws_launch_configuration.app.name}"

  # The minumum number of instances we want to be running all the time.
  # A good default is one per Availability Zone.
  min_size                  = "${length(data.terraform_remote_state.network.private_subnet_ids)}"

  # The maximum number of instances. Theorically you may want to scale to
  # infinity. But autoscaling may be triggered by a DoS attack and you may not
  # want to pay an infinite AWS bill. This value will be your safeguard against
  # excessive scaling.
  max_size                  = 10

  # The ASG will check the health of the instance. This parameter specifies
  # how much time to wait before starting to poll. It may take some time before
  # your App is ready to receive traffic. You don't want the ASG to kill it
  # before it has a chance to fully initialise itself.
  health_check_grace_period = 600

  # The check will be executed by the attached Load Balancer.
  health_check_type         = "ELB"

  # Launch instances in the private subnets. Traffic will only be received by
  # the Load Balancer.
  vpc_zone_identifier       = ["${data.terraform_remote_state.network.private_subnet_ids}"]

  # Attach newly created instances to the Target Group for the app. It will make
  # the instances responding to web traffic!
  target_group_arns         = ["${aws_lb_target_group.app.arn}"]

  # When scaling down, which instance should be deleted?
  # Setting OldestLaunchConfiguration allows us to implement rolling deployments
  # ClosestToNextInstanceHour will help save some $$ when scaling down.
  termination_policies      = ["OldestLaunchConfiguration", "ClosestToNextInstanceHour"]
}
