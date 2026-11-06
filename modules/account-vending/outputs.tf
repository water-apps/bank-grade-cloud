output "account_id" {
  value = aws_organizations_account.this.id
}

output "tags" {
  value = local.tags
}
