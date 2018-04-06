resource "aws_key_pair" "admin" {
  key_name   = "admin"
  public_key = "${var.admin_public_key}"
}
