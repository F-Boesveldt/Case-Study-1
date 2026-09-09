variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "project_name" {
  type = string
}

variable "monitoring_subnet_id" {
  type = string
}

variable "admin_ssh_public_key" {
  type      = string
  sensitive = true
}
