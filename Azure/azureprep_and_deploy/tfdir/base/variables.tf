# azure variables

variable "arm_location" {
  description = "The Azure location."
  default     = "westus2"
}

variable "name_prefix" {
  description = "The name prefix for all your resources"
  default     = "zs"
  type        = string
}

variable "network_address_space" {
  description = "VNET CIDR"
  default     = "10.1.0.0/16"
}

variable "environment" {
  description = "Environment"
  default     = "Development"
}

variable "subnet_count" {
  description = "Default number of worker subnets to create"
  default     = 1
}

variable "server_admin_username" {
  default   = "ubuntu"
  type      = string
}

variable "tls_key_algorithm" {
  default   = "RSA"
  type      = string
}

variable "byo_pip_address" {
  default     = false
  type        = bool
  description = "Bring your own Azure Public IP address for the NAT GW"
}

variable "byo_pip_name" {
  default     = ""
  type        = string
  description = "User provided Azure Public IP address name for the NAT GW"
}

variable "byo_pip_rg" {
  default     = ""
  type        = string
  description = "User provided Azure Public IP address resource group for the NAT GW"
}

variable "vm_count" {
  description = "number of Workload VMs to deploy"
  type    = number
  default = 2
   validation {
          condition     = var.vm_count >= 1 && var.vm_count <= 250
          error_message = "Input vm_count must be a whole number between 1 and 9."
        }
}