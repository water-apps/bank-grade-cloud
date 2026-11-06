variable "name" {
  description = "Account name, e.g. payments-prod"
  type        = string
}

variable "ou" {
  description = "Name of the top-level organisational unit to place the account in, e.g. workloads-production"
  type        = string
}

variable "owner" {
  description = "Owning team's email address"
  type        = string
}

variable "criticality" {
  description = "critical, high, medium or low"
  type        = string
  validation {
    condition     = contains(["critical", "high", "medium", "low"], var.criticality)
    error_message = "criticality must be critical, high, medium or low."
  }
}

variable "critical_op" {
  description = "The CPS 230 critical operation this account supports, or none"
  type        = string
}

variable "data_class" {
  description = "Highest data classification held in the account"
  type        = string
  validation {
    condition     = contains(["public", "internal", "confidential", "confidential-customer"], var.data_class)
    error_message = "data_class must be public, internal, confidential or confidential-customer."
  }
}

variable "services" {
  description = "Managed services the workload depends on, for the provider dependency map. (Not called providers: that name is reserved in module blocks.)"
  type        = list(string)
  default     = []
}

variable "email_domain" {
  description = "Domain for the account's root email address"
  type        = string
  default     = "bank.example"
}
