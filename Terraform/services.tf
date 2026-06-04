# ==================================================
# Microservices — one module call, 50 services
# ==================================================

module "service" {
  for_each = var.services
  source   = "./modules/microservice"

  name         = each.key
  port         = each.value.port
  project_name = var.project_name
  environment  = var.environment
}
