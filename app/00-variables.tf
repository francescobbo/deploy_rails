variable "health_check_interval" {
  default = 6
}

# Must be smaller than interval. Min: 5
variable "health_check_timeout" {
  default = 5
}

variable "health_check_path" {
  default = "/"
}

# The instance type where to run the application.
variable "app_instance_type" {
  default = "t2.nano"
}

# Enable EC2 detailed monitoring. It provides a lot of usefult metrics, but
# for a price.
variable "detailed_monitoring" {
  default = false
}

# EBS Optimized instances perform better for I/O heavy applications but the
# price doubles.
variable "ebs_optimized_instances" {
  default = false
}
