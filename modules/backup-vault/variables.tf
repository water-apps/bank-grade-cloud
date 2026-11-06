variable "name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "org_id" {
  description = "AWS Organizations ID allowed to copy backups into this vault"
  type        = string
}

variable "min_retention_days" {
  type    = number
  default = 35
}

variable "max_retention_days" {
  type    = number
  default = 400
}

variable "changeable_for_days" {
  description = "Grace period before the lock becomes compliance mode and can't be changed"
  type        = number
  default     = 3
}
