# A Security Group is an AWS stateful firewall.
# By default instances are blind to the internet unless there's a rule in their
# SG allowing that communication.
#
# Here we are configuring the "Firewall" for the OpenVPN instance that needs
# UDP port 1194 to work and port 22 to be SSHed and configured.
# We only allow SSH connections from a few trusted range of IPs.
resource "aws_security_group" "openvpn" {
  name        = "OpenVPN"
  description = "OpenVPN Access Point SG"
  vpc_id      = "${aws_vpc.app.id}"

  # Allow SSH access.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.trusted_cidr_list}"
  }

  # Allow UDP port 1194 for OpenVPN traffic.
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all sort of outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Search for an AMI (Amazon Machine Image) that runs Ubuntu.
data "aws_ami" "amazon_linux" {
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

data "template_file" "openvpn_userdata" {
  template = "${file("templates/openvpn_userdata")}"

  vars {
    elastic_ip = "${aws_eip.openvpn.public_ip}"
    network_ip = "${element(split("/", var.vpc_cidr), 0)}"
    subnet_mask = "${cidrnetmask(var.vpc_cidr)}"
  }
}

# This instance will run an OpenVPN server allowing you to connect to the VPC
# from your office or home and share the same IP space.
resource "aws_instance" "openvpn" {
  ami                    = "${data.aws_ami.amazon_linux.id}"
  instance_type          = "${var.vpn_instance_type}"

  # Must run in a public subnet (visible on the Internet)
  subnet_id              = "${aws_subnet.public.0.id}"
  vpc_security_group_ids = ["${aws_security_group.openvpn.id}"]

  # Needed for NATs and VPn servers.
  source_dest_check      = false

  # Allow admin to SSH using their private key.
  key_name               = "${aws_key_pair.admin.key_name}"

  # Configure an OpenVPN server on first startup.
  user_data              = "${data.template_file.openvpn_userdata.rendered}"

  tags {
    Name = "OpenVPN"
  }
}

# An Elastic IPv4 (static IP) to associate to the OpenVPN Server
resource "aws_eip" "openvpn" {
  vpc = true
}

resource "aws_eip_association" "openvpn_assoc" {
  instance_id   = "${aws_instance.openvpn.id}"
  allocation_id = "${aws_eip.openvpn.id}"
}
