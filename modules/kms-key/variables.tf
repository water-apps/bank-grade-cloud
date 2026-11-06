variable "description" {
  type = string
}

variable "admin_role_arns" {
  description = "Roles that administer the key: normally only the deployment pipeline's role, so key policy changes go through a reviewed pull request. They get no cryptographic permissions."
  type        = list(string)
}

variable "user_role_arns" {
  description = "Roles that use the key. They can't change it."
  type        = list(string)
}

variable "viewer_role_arns" {
  description = "People and tools that may read the key's configuration, for example auditors and the evidence collector"
  type        = list(string)
  default     = []
}

variable "rotation_period_in_days" {
  type    = number
  default = 365
}
