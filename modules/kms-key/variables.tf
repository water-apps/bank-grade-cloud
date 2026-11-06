variable "description" {
  type = string
}

variable "admin_role_arns" {
  description = "Roles that administer the key. They get no cryptographic permissions."
  type        = list(string)
}

variable "user_role_arns" {
  description = "Roles that use the key. They can't change it."
  type        = list(string)
}

variable "rotation_period_in_days" {
  type    = number
  default = 365
}
