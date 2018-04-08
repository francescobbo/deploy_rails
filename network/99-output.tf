output "vpc_id" {
  value = "${aws_vpc.app.id}"
}

output "vpn_ip" {
  value = "${aws_eip.openvpn.public_ip}"
}

output "subnet_public0_id" {
  value = "${aws_subnet.public.*.id[0]}"
}

output "subnet_public1_id" {
  value = "${aws_subnet.public.*.id[1]}"
}

output "subnet_public2_id" {
  value = "${aws_subnet.public.*.id[2]}"
}

output "subnet_private0_id" {
  value = "${aws_subnet.private.*.id[0]}"
}

output "subnet_private1_id" {
  value = "${aws_subnet.private.*.id[1]}"
}

output "subnet_private2_id" {
  value = "${aws_subnet.private.*.id[2]}"
}
