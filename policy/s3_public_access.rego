# DATA-01.1 and DATA-01.3: S3 Block Public Access settings are all on, at
# account level and on every bucket-level public access block.
package main

import rego.v1

required := ["block_public_acls", "block_public_policy",
             "ignore_public_acls", "restrict_public_buckets"]

pab_types := {"aws_s3_account_public_access_block", "aws_s3_bucket_public_access_block"}

deny contains msg if {
  some rc in input.resource_changes
  rc.type in pab_types
  not "delete" in rc.change.actions
  some setting in required
  rc.change.after[setting] != true
  msg := sprintf("%s: %s must be true", [rc.address, setting])
}

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_s3_account_public_access_block"
  "delete" in rc.change.actions
  msg := sprintf("%s: the account-level public access block can't be removed", [rc.address])
}
