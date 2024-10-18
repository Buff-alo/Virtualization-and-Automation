# variables.tf

variable "pm_api_url" {
  type        = string
  description = "The API URL for Proxmox."
}

variable "pm_api_token_id" {
  type        = string
  description = "The API Token ID for Proxmox."
}

variable "pm_api_token_secret" {
  type        = string
  description = "The API Token Secret for Proxmox."
}

variable "pm_tls_insecure" {
  type        = bool
  description = "Whether to skip TLS certificate validation."
  default     = true
}