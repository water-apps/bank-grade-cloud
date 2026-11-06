# ACC-01: every vended account carries the four required tags.
package main

import rego.v1

required_tags := ["owner", "criticality", "critical-op", "data-class"]

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_organizations_account"
  some t in required_tags
  not rc.change.after.tags[t]
  msg := sprintf("%s: missing required tag %s", [rc.address, t])
}
