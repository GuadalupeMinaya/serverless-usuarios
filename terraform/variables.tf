variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "usuarios-api"
}

variable "lwa_layer_version" {
  type    = string
  default = "27"
}

variable "db_url" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "jwt_secret" {
  type      = string
  sensitive = true
}