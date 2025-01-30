# Variables for SSH keys and template names
variable "ssh_key" {
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGgVhlH0TFnfQFaCNk5ZHRBYiQgXjS+GiWKUK4iChAdMxHAupZf6kMVTWJZi5tHfsUqYdopwPAmoqpmYc/5AXrkYXyepRHNf/gGSp3Q1BrWH6+jhPBF/2fx65NrUqFTm3muuD3aPvepWA4oobcrT9FJN7HPZQ6N+N32GpM3IY5pbDhlTOkAwR6HLEFXdem8hJ7/GlV5Aw8qiQxhOsqLScN5deJlLsncsQfdSxEFhgrWrNOvAZaItk2q/jzq6I+zQE6WS8pGYu0vRA5hHNXxVdh+PnMavmA2rTzh4g+ATfAqjeA2gYlfQH5Nz9HhzXQGciQDZpUlsjGWWX0OcQ7+1tB buffalo@buffalo-IdeaPad-1"  # Just set the path as a string
}

variable "proxmox_host" {
  default = "pve"
}

variable "db_template" {
  default = "ubuntu-cloud-init-template"
}

variable "app_template" {
  default = "ubuntu-cloud-init-template"
}

variable "db_server_ip" {
  type = string
}

variable "db_server_netmask" {
  type = number
}

variable "db_server_gateway" {
  type = string
}

variable "app_server_ip" {
  type = string
}

variable "app_server_netmask" {
  type = number
}

variable "app_server_gateway" {
  type = string
}

# variable "ciuser"{
#   type = string
# }

# variable "cipassword"{
#   type = string
# }