output "aws_region" {
  value = "${var.aws_region}"
}

output "vpc_id" {
  value = "${aws_vpc.app.id}"
}

output "vpn_ip" {
  value = "${aws_eip.openvpn.public_ip}"
}

output "public_subnet_ids" {
  value = "${aws_subnet.public.*.id}"
}

output "private_subnet_ids" {
  value = "${aws_subnet.private.*.id}"
}

output "admin_key_name" {
  value = "${aws_key_pair.admin.key_name}"
}
