# Your private network in the AWS Cloud.
resource "aws_vpc" "app" {
  cidr_block = "${var.vpc_cidr}"

  # Enable IPv6 addressing in the VPC. (will be useful later)
  assign_generated_ipv6_cidr_block = true
}

# A Gateway that allows your private network to communicate with the rest of the
# Internet. It is needed for any ingress or egress communication from the VPC.
# It is thus necessary to SSH to the instances, to open a web page on an
# application running there, or even to install the latest OS updates!
# A few applications may not need Internet connectivity at all (for example,
# bulk background data processing), and preventing it completely may be the
# safest thing to do.
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.app.id}"
}

# Another Internet Gateway, but for IPv6 communication only and only for egress
# connections. It allows resources in the private subnet to access IPv6
# available resources on the public Internet without the need for a NAT gateway.
resource "aws_egress_only_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.app.id}"
}

# A Terraform magic trick to get the list of AZs in the region we're running.
data "aws_availability_zones" "zones" {}

# Public subnets will host instances and other resources that are directly
# addressable from the Internet.
resource "aws_subnet" "public" {
  # To be super higly available, let's have a subnet in each AZ.
  count = "${length(data.aws_availability_zones.zones.names)}"

  availability_zone = "${data.aws_availability_zones.zones.names[count.index]}"

  vpc_id     = "${aws_vpc.app.id}"
  cidr_block = "${cidrsubnet(var.vpc_cidr, 8, count.index)}"
}

resource "aws_subnet" "private" {
  count = "${length(data.aws_availability_zones.zones.names)}"

  availability_zone = "${data.aws_availability_zones.zones.names[count.index]}"

  vpc_id     = "${aws_vpc.app.id}"
  cidr_block = "${cidrsubnet(var.vpc_cidr, 8, count.index + 3)}"
}

# What defines a subnet to be public or private is it's route table.
# A public subnet will have a route to the Internet Gateway, making its
# resources available on the Internet (in and egress).
# A private subnet will not have this link, but may still have an egress only
# IPv6 IGW.
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.app.id}"

  # Route any non-VPC IPv4 traffic to the IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  # Route any non-VPC IPv6 traffic to the IPv6 IGW
  route {
    ipv6_cidr_block = "::/0"
    egress_only_gateway_id = "${aws_egress_only_internet_gateway.gw.id}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.app.id}"

  # Route any non-VPC IPv6 traffic to the IPv6 IGW
  route {
    ipv6_cidr_block = "::/0"
    egress_only_gateway_id = "${aws_egress_only_internet_gateway.gw.id}"
  }
}

# Attach the public route table to the public subnets
resource "aws_route_table_association" "public" {
  count = "${length(data.aws_availability_zones.zones.names)}"

  subnet_id      = "${aws_subnet.public.*.id[count.index]}"
  route_table_id = "${aws_route_table.public.id}"
}

# Attach the private route table to the private subnets
resource "aws_route_table_association" "private" {
  count = "${length(data.aws_availability_zones.zones.names)}"

  subnet_id      = "${aws_subnet.private.*.id[count.index]}"
  route_table_id = "${aws_route_table.private.id}"
}
