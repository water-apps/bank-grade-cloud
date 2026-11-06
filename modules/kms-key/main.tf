# Customer-managed key with separation of duties (Chapter 7): administrators
# can manage the key but not decrypt; users can encrypt and decrypt but not
# change the key. Include the pipeline role that creates the key in
# admin_role_arns, or the key policy lockout check will refuse it.

data "aws_iam_policy_document" "key" {
  statement {
    sid       = "KeyAdministration"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]
    principals {
      type        = "AWS"
      identifiers = var.admin_role_arns
    }
  }

  statement {
    sid       = "KeyUse"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    principals {
      type        = "AWS"
      identifiers = var.user_role_arns
    }
  }
}

resource "aws_kms_key" "this" {
  description             = var.description
  enable_key_rotation     = true
  rotation_period_in_days = var.rotation_period_in_days
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.key.json
}
