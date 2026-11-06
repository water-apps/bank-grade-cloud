# Tests for the tests (Chapter 3): each policy has an input that must pass
# and one that must fail. Run with: opa test policy/ -v
package main

import rego.v1

pab(addr, v) := {"address": addr, "type": "aws_s3_bucket_public_access_block",
  "change": {"actions": ["create"], "after": {
    "block_public_acls": true, "block_public_policy": v,
    "ignore_public_acls": true, "restrict_public_buckets": true}}}

test_s3_public_access_pass if {
  count(deny) == 0 with input as {"resource_changes": [pab("aws_s3_bucket_public_access_block.ok", true)]}
}

account_pab(v, actions) := {"address": "module.baseline.aws_s3_account_public_access_block.this", "type": "aws_s3_account_public_access_block",
  "change": {"actions": actions, "after": {"block_public_acls": true, "block_public_policy": true, "ignore_public_acls": v, "restrict_public_buckets": true}}}

test_account_level_pass if {
  count(deny) == 0 with input as {"resource_changes": [account_pab(true, ["create"])]}
}

test_account_level_setting_off_fails if {
  deny["module.baseline.aws_s3_account_public_access_block.this: ignore_public_acls must be true"] with input as {"resource_changes": [account_pab(false, ["update"])]}
}

test_account_level_delete_fails if {
  deny["module.baseline.aws_s3_account_public_access_block.this: the account-level public access block can't be removed"] with input as {"resource_changes": [{"address": "module.baseline.aws_s3_account_public_access_block.this", "type": "aws_s3_account_public_access_block", "change": {"actions": ["delete"], "after": null}}]}
}

test_s3_public_access_fail if {
  deny["aws_s3_bucket_public_access_block.bad: block_public_policy must be true"] with input as {"resource_changes": [pab("aws_s3_bucket_public_access_block.bad", false)]}
}

test_protected_delete_fails if {
  count(deny) == 1 with input as {"resource_changes": [{"address": "aws_cloudtrail.org", "type": "aws_cloudtrail", "change": {"actions": ["delete"], "after": null}}]}
}

trail(after) := {"address": "aws_cloudtrail.org", "type": "aws_cloudtrail", "change": {"actions": ["update"], "after": after}}

test_trail_benign_update_passes if {
  count(deny) == 0 with input as {"resource_changes": [trail({"enable_logging": true, "enable_log_file_validation": true, "is_multi_region_trail": true, "name": "org-trail"})]}
}

test_trail_logging_off_fails if {
  deny["aws_cloudtrail.org: enable_logging must stay true"] with input as {"resource_changes": [trail({"enable_logging": false, "enable_log_file_validation": true, "is_multi_region_trail": true})]}
}

test_trail_validation_off_fails if {
  deny["aws_cloudtrail.org: enable_log_file_validation must stay true"] with input as {"resource_changes": [trail({"enable_logging": true, "enable_log_file_validation": false, "is_multi_region_trail": true})]}
}

test_config_disable_fails if {
  count(deny) == 1 with input as {"resource_changes": [{"address": "aws_config_configuration_recorder_status.this", "type": "aws_config_configuration_recorder_status", "change": {"actions": ["update"], "after": {"is_enabled": false}}}]}
}

acct(tags) := {"address": "module.payments_prod.aws_organizations_account.this", "type": "aws_organizations_account",
  "change": {"actions": ["create"], "after": {"tags": tags}}}

full_tags := {"owner": "payments-platform@bank.example", "criticality": "critical", "critical-op": "payments", "data-class": "confidential-customer"}

test_account_tags_pass if {
  count(deny) == 0 with input as {"resource_changes": [acct(full_tags)]}
}

test_account_tags_fail if {
  deny["module.payments_prod.aws_organizations_account.this: missing required tag critical-op"] with input as {"resource_changes": [acct(object.remove(full_tags, ["critical-op"]))]}
}

key(policy) := {"address": "module.key.aws_kms_key.this", "type": "aws_kms_key",
  "change": {"actions": ["create"], "after": {"policy": json.marshal(policy)}}}

admin := "arn:aws:iam::111111111111:role/key-admin"

app := "arn:aws:iam::111111111111:role/payments-app"

test_key_policy_separated_passes if {
  count(deny) == 0 with input as {"resource_changes": [key({"Statement": [
    {"Sid": "KeyAdministration", "Effect": "Allow", "Principal": {"AWS": [admin]}, "Action": ["kms:Create*", "kms:Put*", "kms:ScheduleKeyDeletion"], "Resource": "*"},
    {"Sid": "KeyUse", "Effect": "Allow", "Principal": {"AWS": app}, "Action": ["kms:Decrypt", "kms:GenerateDataKey"], "Resource": "*"}]})]}
}

test_key_policy_admin_can_decrypt_fails if {
  deny[sprintf("module.key.aws_kms_key.this: %s can both administer and decrypt with this key", [admin])] with input as {"resource_changes": [key({"Statement": [
    {"Sid": "KeyAdministration", "Effect": "Allow", "Principal": {"AWS": admin}, "Action": ["kms:Put*"], "Resource": "*"},
    {"Sid": "KeyUse", "Effect": "Allow", "Principal": {"AWS": [admin, app]}, "Action": "kms:Decrypt", "Resource": "*"}]})]}
}

test_key_policy_star_fails if {
  deny["module.key.aws_kms_key.this: key policy grants kms:* (statement Everything)"] with input as {"resource_changes": [key({"Statement": [
    {"Sid": "Everything", "Effect": "Allow", "Principal": {"AWS": app}, "Action": "kms:*", "Resource": "*"}]})]}
}
