resource "aws_vpc" "app" {
  cidr_block = "${var.vpc_cidr}"
}

data "aws_availability_zones" "zones" {}

resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.app.id}"
  cidr_block = "${cidrsubnet(var.vpc_cidr, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.zones.names[count.index]}"

  count = "${length(data.aws_availability_zones.zones.names)}"
}

resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.app.id}"
  cidr_block = "${cidrsubnet(var.vpc_cidr, 8, count.index + 3)}"
  availability_zone = "${data.aws_availability_zones.zones.names[count.index]}"

  count = "${length(data.aws_availability_zones.zones.names)}"
}
