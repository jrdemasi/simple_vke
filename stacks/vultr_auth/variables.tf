variable "vultr_api_key" {
  description = "Vultr API key"
  type        = string
  sensitive   = true
}

variable "email" {
  description = "Email to attach to account for external DNS"
  type        = string
}

