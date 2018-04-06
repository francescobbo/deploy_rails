# Where do you want to run your infrastructure?
# In a very far future you may need to scale to multiple regions and you will
# be very grateful that Terraform exists.
# eu-central-1 is the AWS Frankfurt region, just my favourite default.
variable "aws_region" {
  default = "eu-central-1"
}

# The address space of the AWS VPC. 16 bits is fairly large with 65k addresses,
# but you can grow up to 10.0.0.0/8 with 16 million addresses.
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

# Change this to a few IP address you control statically and trust.
variable "trusted_cidr_list" {
  default = ["0.0.0.0/0"]
}

# The public key of someone you can trust, possibly yourself. The key will be
# used for SSH authentication on the OpenVPN and application instances.
variable "admin_public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5WgSLUKoPwCqv9qXcCxLhY4/1T66Ff7tPsdd+lrMP3OkAYmgOdkKO3ewNw4DNEQpO74YAbKwbsWkFwuE4RSt9Zb3z8PTb1J1jeiWDdUh9coM4ZWlXIx3vOEQZDBfnmQeb/Yjy7z+DyzrmfNIiVykFAVglaRKO4e0xCStk7t3LWZOrTi7TRru2GYeN5Lzo+lMHK4cYY48Mbt2M3gFJByk5w1xCtfGHtGuTmm6AmtWWD/0JlMRV5Ne1gI+Ujtn6pqtJCnd/X9HWbJKs35eouSq2De+TEq0qVT1FAlyuKVvHkv5k6XExRYDHJXSZ/y9N5r+x23rlbPjyVIxMwGDE686z aomega08@aomega08-VirtualBox"
}

# t2.nano is incredibly cheap, and is probably all we need to run a simple
# OpenVPN server. However this terraform stack will route all private traffic
# through this instace. It may become a network bottleneck. If that's the case,
# you can simply scale up to another, more powerful, instance type.
variable "vpn_instance_type" {
  default = "t2.nano"
}
