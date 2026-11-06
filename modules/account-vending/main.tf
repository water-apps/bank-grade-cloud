# Creates one AWS account in the named organisational unit, with the four
# tags every account must carry (Chapter 4). The account baseline is applied
# to the new account by the next stage of the vending pipeline, which assumes
# the OrganizationAccountAccessRole into it (see modules/account-baseline).

data "aws_organizations_organization" "this" {}

data "aws_organizations_organizational_units" "top" {
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

locals {
  ou_id = one([for ou in data.aws_organizations_organizational_units.top.children : ou.id if ou.name == var.ou])

  tags = {
    "owner"       = var.owner
    "criticality" = var.criticality
    "critical-op" = var.critical_op
    "data-class"  = var.data_class
    "services"    = join(" ", var.services)
  }
}

resource "aws_organizations_account" "this" {
  name              = var.name
  email             = "aws+${var.name}@${var.email_domain}"
  parent_id         = local.ou_id
  role_name         = "OrganizationAccountAccessRole"
  close_on_deletion = false
  tags              = local.tags

  lifecycle {
    ignore_changes = [role_name]

    precondition {
      condition     = local.ou_id != null
      error_message = "No top-level organisational unit named ${var.ou}."
    }
  }
}
