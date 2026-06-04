# ==================================================
# Microservice Module
# Creates per-service AWS resources
# ==================================================

resource "aws_ecr_repository" "this" {
  name                 = "taskflow-${var.name}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-${var.name}-ecr"
    Environment = var.environment
    Service     = var.name
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/taskflow/${var.name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.name}-logs"
    Environment = var.environment
    Service     = var.name
  }
}
