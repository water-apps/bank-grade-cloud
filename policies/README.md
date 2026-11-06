# Service control policies

| File | Attach to | Control | Chapter |
| --- | --- | --- | --- |
| protect-s3-public-access-block.json | Organisation root | DATA-01.2 | 3 |
| approved-regions.json | Organisation root | ACC-02 | 4 |
| no-internet-gateways.json | Workload OUs (not the network or ingress accounts) | NET-01 | 5 |
| no-iam-users.json | Organisation root | IAM-01 | 6 |

Attach each one to the policy staging OU first and test on real accounts
before it reaches production (Chapter 4). Check the exempted actions in
approved-regions.json against the AWS documentation for your services.
