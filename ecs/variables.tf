variable "aws_region" {
  default = "us-east-1"
}
variable "project_name" {
  description = "project name"
  type        = string
  default     = "movie-project"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

# RDS variables ======================= #
variable "db" {
  description = "Database configuration"
  type = object({
    db_name     = string
    username = string
  })

}

variable "db_password" {
  type      = string
  sensitive = true
}

# ECS ================================== #

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8000
}

variable "container_api" {
  description = "Django API"
  type = object({
    name     = string
    image_uri = string
    port = number
  })

}

variable "django_secret_key" {
  sensitive = true
}

# ALB ================================== #

variable "alb_listener_port" {
  description = "Port ALB listens on"
  type        = number
  default     = 80
}

