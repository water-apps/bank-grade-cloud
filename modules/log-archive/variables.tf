variable "bucket_name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "retention_years" {
  description = "Set from the records policy, not the budget (Chapter 11)"
  type        = number
  default     = 7
}

variable "archive_after_days" {
  description = "Move objects to archival storage after this many days (Chapter 14)"
  type        = number
  default     = 90
}
