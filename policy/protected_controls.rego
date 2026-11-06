# COST-01: changes through the pipeline can't remove or switch off the
# controls that produce evidence. Changes made outside the pipeline are
# stopped by policies/scp/protect-evidence-controls.json instead.
package main

import rego.v1

protected := {"aws_config_configuration_recorder", "aws_cloudtrail",
              "aws_flow_log", "aws_backup_vault_lock_configuration",
              "aws_s3_bucket_object_lock_configuration"}

deny contains msg if {
  some rc in input.resource_changes
  rc.type in protected
  "delete" in rc.change.actions
  msg := sprintf("%s is a protected control and can't be deleted", [rc.address])
}

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_config_configuration_recorder_status"
  rc.change.after.is_enabled == false
  msg := sprintf("%s: AWS Config must stay enabled", [rc.address])
}

trail_settings := ["enable_logging", "enable_log_file_validation", "is_multi_region_trail"]

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_cloudtrail"
  not "delete" in rc.change.actions
  some s in trail_settings
  rc.change.after[s] == false
  msg := sprintf("%s: %s must stay true", [rc.address, s])
}
