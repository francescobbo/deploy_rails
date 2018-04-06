provider "aws" {
  version = "~> 1.14"
  region = "${var.aws_region}"
}

provider "template" {
  version = "~> 1.0"
}
