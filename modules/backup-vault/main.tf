# Central backup vault in the backup account, under separate administration
# from the workloads it protects (Chapter 12). Setting changeable_for_days puts
# the lock into compliance mode after the grace period. Test on a
# non-production vault first: compliance mode can't be undone.

resource "aws_backup_vault" "central" {
  name        = var.name
  kms_key_arn = var.kms_key_arn
}

resource "aws_backup_vault_lock_configuration" "central" {
  backup_vault_name   = aws_backup_vault.central.name
  min_retention_days  = var.min_retention_days
  max_retention_days  = var.max_retention_days
  changeable_for_days = var.changeable_for_days
}

data "aws_iam_policy_document" "copy_in" {
  statement {
    sid       = "AllowCopyFromOrganisation"
    effect    = "Allow"
    actions   = ["backup:CopyIntoBackupVault"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [var.org_id]
    }
  }
}

resource "aws_backup_vault_policy" "central" {
  backup_vault_name = aws_backup_vault.central.name
  policy            = data.aws_iam_policy_document.copy_in.json
}
