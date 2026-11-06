# COST-01: cost changes can't remove the controls that produce evidence.
package main

import rego.v1

protected := {"aws_config_configuration_recorder", "aws_cloudtrail",
              "aws_flow_log", "aws_backup_vault_lock_configuration"}

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
