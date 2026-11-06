# New EBS volumes are encrypted by default (Chapter 4).
resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}
