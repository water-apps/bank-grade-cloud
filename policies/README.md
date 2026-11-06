# Service control policies

| File | Attach to | Control | Chapter |
| --- | --- | --- | --- |
| protect-s3-public-access-block.json | Organisation root | DATA-01.2 | 3 |
| approved-regions.json | Organisation root | ACC-02 | 4 |
| no-internet-gateways.json | Workload OUs (not the network or ingress accounts) | NET-01 | 5 |
| no-iam-users.json | Organisation root | IAM-01 | 6 |
| protect-evidence-controls.json | Organisation root | COST-01, LOG-01 | 11, 14 |

Exemptions are by role name. Make sure only the platform pipeline can create
or change roles with those names: deny iam:CreateRole, iam:UpdateAssumeRolePolicy
and iam:PutRolePolicy on arn:aws:iam::*:role/platform-guardrails and
arn:aws:iam::*:role/break-glass to everyone else, as the companion SCP does not
do this for you. SCPs don't apply to the management account, so keep workloads
out of it.

Attach each one to the policy staging OU first and test on real accounts
before it reaches production (Chapter 4). Check the exempted actions in
approved-regions.json against the AWS documentation for your services.
