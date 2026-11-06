# Customer-managed key with separation of duties (Chapter 7).
# - Administration, including changing this policy, is for the pipeline role
#   only, so every change is a reviewed pull request. People get read access.
# - Users can decrypt and generate data keys, and can create grants only for
#   AWS services (RDS, EBS and EKS need grants to use the key for you).
# - Nobody gets both. policy/kms_key_policy.rego tests that.
# Include the role that creates the key in admin_role_arns, or the key policy
# lockout check will refuse it.

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
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*", "kms:DescribeKey"]
    principals {
      type        = "AWS"
      identifiers = var.user_role_arns
    }
  }

  statement {
    sid       = "GrantsForAWSServicesOnly"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:CreateGrant", "kms:ListGrants", "kms:RevokeGrant"]
    principals {
      type        = "AWS"
      identifiers = var.user_role_arns
    }
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  dynamic "statement" {
    for_each = length(var.viewer_role_arns) > 0 ? [1] : []
    content {
      sid       = "ReadOnly"
      effect    = "Allow"
      resources = ["*"]
      actions   = ["kms:DescribeKey", "kms:GetKeyPolicy", "kms:GetKeyRotationStatus", "kms:ListResourceTags"]
      principals {
        type        = "AWS"
        identifiers = var.viewer_role_arns
      }
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
