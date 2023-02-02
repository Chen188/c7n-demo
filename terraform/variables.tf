variable "region_main" {
  description = "Main AWS region"
  type        = string
  default     = "us-east-1"
}

variable "region_secondary" {
  description = "Secondary AWS region"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "Instance type - webserver"
  type        = string
  default     = "t3.small"
}

variable "env" {
  description = "Environment"
  type        = string
  default     = "Test"
}