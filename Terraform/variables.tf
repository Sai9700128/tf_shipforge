# ==================================================
# General Variables
# ==================================================
variable "project_name" {
  description = "Name of the project - used for resource naming"
  type        = string
  default     = "gitops-demo"
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}


variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
}

# ==================================================
# VPC Variables
# ==================================================
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# ==================================================
# EKS Variables
# ==================================================
variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  # default     = "1.31"
}

variable "eks_node_instance_types" {
  description = "Instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

# ==================================================
# ECR Variables
# ==================================================
variable "ecr_repo_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "gitops-app"
}

# ==================================================
# RDS Variables
# ==================================================


variable "db_password" {
  description = "Password for RDS MySQL"
  type        = string
  sensitive   = true
}

# ==================================================
# Microservices Variables
# ==================================================
variable "services" {
  description = "Map of all microservices with their config"
  type = map(object({
    port = number
  }))
}
