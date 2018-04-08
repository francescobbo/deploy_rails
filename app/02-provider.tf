provider "aws" {
  version = "~> 1.14"
  region = "${data.terraform_remote_state.network.aws_region}"
}
