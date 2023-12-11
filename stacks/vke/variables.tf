variable "vultr_api_key" {
  description = "Vultr API key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Vultr region to create the k8s dev cluster in"
  type        = string
  default     = "ewr"
}

variable "plan" {
  description = "Vultr node type to use for cluster nodes"
  type        = string
  default     = "vc2-1c-2gb"
}

variable "autoscaler_max" {
  description = "Max size of k8s dev cluster"
  type        = number
  default     = 2
}
