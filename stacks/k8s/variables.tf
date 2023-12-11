variable "vultr_api_key" {
  description = "Vultr API key"
  type        = string
  sensitive   = true
}

variable "domain_filter" {
  description = "Domain to filter to restrict external DNS from operating outside of a given hosted zone"
  type        = string
}

variable "hostname" {
  description = "Hostname where nginx pod should exist"
  type        = string
}
