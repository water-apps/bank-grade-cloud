# KEY-01: key administrators can't use the key, and nobody gets kms:*.
package main

import rego.v1

admin_actions := {"kms:Put*", "kms:PutKeyPolicy", "kms:ScheduleKeyDeletion", "kms:*"}

use_actions := {"kms:Decrypt", "kms:*", "kms:Decrypt*"}

as_set(x) := {x} if is_string(x)

as_set(x) := {v | some v in x} if is_array(x)

principals(st) := as_set(st.Principal.AWS)

actions(st) := as_set(st.Action)

key_statements(rc) := json.unmarshal(rc.change.after.policy).Statement

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_kms_key"
  some st in key_statements(rc)
  st.Effect == "Allow"
  "kms:*" in actions(st)
  msg := sprintf("%s: key policy grants kms:* (statement %s)", [rc.address, st.Sid])
}

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_kms_key"
  sts := key_statements(rc)
  some a in sts
  some u in sts
  a.Effect == "Allow"
  u.Effect == "Allow"
  count(actions(a) & admin_actions) > 0
  count(actions(u) & use_actions) > 0
  some p in principals(a) & principals(u)
  msg := sprintf("%s: %s can both administer and decrypt with this key", [rc.address, p])
}
