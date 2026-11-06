# DATA-01.3: every S3 bucket public access block has all four settings on.
package main

import rego.v1

required := ["block_public_acls", "block_public_policy",
             "ignore_public_acls", "restrict_public_buckets"]

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_s3_bucket_public_access_block"
  some setting in required
  rc.change.after[setting] != true
  msg := sprintf("%s: %s must be true", [rc.address, setting])
}
