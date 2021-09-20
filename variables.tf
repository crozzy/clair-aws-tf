variable "prefix" {
  description = "Prefix for instances"
  type        = string
  default     = "clair-stage"
}

variable "aws_profile" {
  description = "AWS profile used for deployment"
  type        = string
  default     = "default"
}

variable "region" {
  description = "Region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "clair_image" {
  description = "image to use for clair"
  type = string
  default = "quay.io/projectquay/clair:nightly"
}

variable "rds_vpc_cidr" {
  description = "CIDR for the VPC where RDS is going to be created"
  type        = string
  default     = "172.34.0.0/16"
}

variable "openshift_cidrs" {
  description = "CIDR for openshift access to RDS"
  type        = list
  default     = ["10.0.0.0/8", "172.30.0.0/16"]
}

variable "db_password" {
  description = "Password for Clair DB"
  type        = string
  sensitive   = true
}

variable "openshift_vpc_id" {
  description = "VPC ID of the openshift cluster"
  type        = string
}

variable "openshift_route_suffix" {
  description = "Route suffix for the Openshift cluster"
  type        = string
}
