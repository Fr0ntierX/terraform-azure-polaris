variable "name" {
  description = "Base name for all resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "vm_size" {
  description = "VM size for confidential computing"
  type        = string
  default     = "Standard_DC4as_v5"
}

variable "boot_disk_type" {
  description = "OS disk type"
  type        = string
  default     = "Premium_LRS"
}

variable "boot_disk_size" {
  description = "OS disk size in GB"
  type        = number
  default     = 50
}

variable "public_ip_type" {
  description = "Public IP allocation type (Static, Dynamic, or NONE)"
  type        = string
  default     = "Static"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
}

variable "enable_kms" {
  description = "Enable Key Vault integration"
  type        = bool
  default     = false
}

variable "polaris_proxy_image" {
  description = "Polaris proxy container image"
  type        = string
  default     = "fr0ntierx/polaris-proxy"
}

variable "polaris_proxy_image_version" {
  description = "Polaris proxy container version"
  type        = string
  default     = "latest"
}

variable "polaris_proxy_port" {
  description = "Polaris proxy port"
  type        = number
  default     = 3000
}

variable "polaris_proxy_source_ranges" {
  description = "Allowed source IP ranges"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "polaris_proxy_enable_input_encryption" {
  description = "Enable input encryption for Polaris proxy"
  type        = bool
  default     = false
}

variable "polaris_proxy_enable_output_encryption" {
  description = "Enable output encryption for Polaris proxy"
  type        = bool
  default     = false
}

variable "polaris_proxy_enable_cors" {
  description = "Enable CORS for Polaris proxy"
  type        = bool
  default     = false
}

variable "polaris_proxy_enable_logging" {
  description = "Enable logging for Polaris proxy"
  type        = bool
  default     = false
}

variable "workload_port" {
  description = "Workload container port"
  type        = number
  default     = 8000
}

variable "workload_image" {
  description = "Workload container image"
  type        = string
}

variable "workload_entrypoint" {
  description = "Workload container entrypoint"
  type        = string
  default     = ""
}

variable "workload_arguments" {
  description = "Workload container arguments"
  type        = list(string)
  default     = []
}

variable "workload_env_vars" {
  description = "Workload environment variables"
  type        = map(string)
  default     = {}
}

# Add attestation-specific variables similar to GCP approach
variable "attestation_federated_identity_enabled" {
  description = "Enable federated credentials for attestation"
  type        = bool
  default     = true
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = null
}