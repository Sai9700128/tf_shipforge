variable "name" {
  description = "Name of the microservice"
  type        = string
}

variable "port" {
  description = "Port the service listens on"
  type        = number
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}
