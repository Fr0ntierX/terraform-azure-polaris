# Core Configuration
variable "name" {
  type        = string
  description = "Base name for all resources"
}

variable "location" {
  type        = string
  description = "Azure region for deployment"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

# Compute Resources
variable "container_cpu" {
  type        = number
  default     = 1
  description = "CPU cores for main workload container"
}

variable "container_memory" {
  type        = number
  default     = 4
  description = "Memory size in GB for main workload container"
}

# Networking Configuration
variable "new_vnet_enabled" {
  type        = bool
  default     = true
  description = "Whether to create a new virtual network (true) or use an existing one (false)"
}

variable "networking_type" {
  type    = string
  default = "Public"
  validation {
    condition     = contains(["Public", "Private"], var.networking_type)
    error_message = "The networking_type must be either 'Public' or 'Private'."
  }
  description = "Networking type for the container group (Public or Private)"
}

variable "dns_name_label" {
  type        = string
  default     = ""
  description = "DNS name label for public IP (leave empty for auto-generated name)"
}

variable "vnet_name" {
  type        = string
  default     = ""
  description = "Name of the existing virtual network when create_new_vnet=false"
}

variable "vnet_resource_group" {
  type        = string
  default     = ""
  description = "Resource group containing the virtual network (for existing VNet, leave empty to use the module's resource group)"
}

variable "vnet_address_space" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "Address space for a new virtual network"
}

variable "subnet_name" {
  type        = string
  default     = "default"
  description = "Name of the subnet (either to be created or existing)"
}

variable "subnet_address_prefix" {
  type        = string
  default     = "10.0.1.0/24"
  description = "Address prefix for a new subnet"
}

# Security & Encryption
variable "enable_key_vault" {
  type        = bool
  default     = true
  description = "Enable confidential computing with hardware-based attestation and secure key release"
}

variable "polaris_proxy_source_ranges" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "IP ranges allowed to access the Polaris proxy"
}

variable "polaris_proxy_enable_input_encryption" {
  type        = bool
  default     = false
  description = "Enable encryption for input data"
}

variable "polaris_proxy_enable_output_encryption" {
  type        = bool
  default     = false
  description = "Enable encryption for output data"
}

variable "attestation_policy" {
  type        = any
  description = "Custom attestation policy for secure key release."
  default     = null
}

# Polaris Proxy Configuration
variable "polaris_proxy_image_version" {
  type        = string
  default     = "latest"
  description = "Polaris proxy image version/tag"
}

variable "polaris_proxy_port" {
  type        = number
  default     = 3000
  description = "Port exposed by the Polaris proxy container"
}

variable "polaris_proxy_enable_cors" {
  type        = bool
  default     = false
  description = "Enable CORS for API endpoints"
}

variable "maa_endpoint" {
  description = "MAA endpoint for SKR container"
  type        = string
  default     = "sharedweu.weu.attest.azure.net"
}

variable "polaris_proxy_enable_logging" {
  type        = bool
  default     = true
  description = "Enable enhanced logging"
}

# Workload Configuration
variable "workload_image" {
  type        = string
  description = "Container image for the workload container"
}

variable "workload_port" {
  type        = number
  default     = 8000
  description = "Port exposed by the workload container"
}

variable "workload_env_vars" {
  type        = map(string)
  default     = {}
  description = "Environment variables for the workload container"
}

variable "workload_arguments" {
  type        = list(string)
  default     = []
  description = "Command arguments for the workload container"
}

# Container Registry
variable "registry_login_server" {
  type        = string
  default     = ""
  description = "Custom container registry login server (if using)"
}

variable "registry_username" {
  type        = string
  default     = ""
  description = "Custom container registry username"
}

variable "registry_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Custom container registry password"
}