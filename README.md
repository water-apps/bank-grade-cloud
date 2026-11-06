# Bank-Grade Cloud: companion code

Working code for *Bank-Grade Cloud: Building AWS, Azure and Kubernetes Platforms That Pass APRA Review* by Varun Kaushik.

The book's main idea is that a regulated platform has to produce its own evidence. This repository shows how, in four kinds of code:

- the guardrails that **prevent** problems: Terraform modules and service control policies
- the **tests** that run on every pull request: Rego policies for Conftest, with tests of their own
- the **register** that links each written control to its code and evidence
- the tools that build **evidence packs** and **access reviews** from what the platform collects

All of it was written for the book. None of it comes from a client. It is published under the MIT licence, so you can use it freely.

## Start here

```bash
pip install -r requirements.txt
make test                                      # format, policy tests, Python tests, terraform validate
make evidence CONTROL=DATA-01 PERIOD=2026-Q3   # build an evidence pack from the sample data
make access-review QUARTER=2026-Q3 AS_OF=2026-10-01
```

`make test` needs Terraform 1.6 or later and Open Policy Agent. If you use OpenTofu, run `make test TF=tofu`.

## What's where, by chapter

| Chapter | Topic | In this repository |
| --- | --- | --- |
| 3 | Turning a control into code | `controls/register.yaml`, `controls/exceptions.yaml`, `policy/s3_public_access.rego`, `policy/policy_test.rego` |
| 4 | Landing zones | `modules/account-vending`, `modules/account-baseline`, `examples/vend-payments-prod`, `policy/account_tags.rego`, `policies/scp/approved-regions.json` |
| 5 | Networking | `policies/scp/no-internet-gateways.json` |
| 6 | Identity and access | `policies/scp/no-iam-users.json`, `tools/access_review` |
| 7 | Keys and secrets | `modules/kms-key`, `policy/kms_key_policy.rego` |
| 8 | Kubernetes | `k8s/kyverno`, `k8s/network` |
| 9 | GitOps | `k8s/argocd`, `k8s/flux` |
| 11 | Observability | `modules/log-archive` |
| 12 | Backup and DR | `modules/backup-vault` |
| 14 | Cost control | `policy/protected_controls.rego` |
| 15 | Evidence on demand | `tools/evidence`, `samples/collected` |
| Appendix A | Control-to-code map | `controls/register.yaml` |

## Running the policy tests against your own plan

```bash
terraform plan -out tf.plan
terraform show -json tf.plan > plan.json
conftest test plan.json --policy policy/
```

## About the sample data

`samples/` holds example output from evidence collectors and an identity export, so the tools can be run and tested anywhere. The account numbers, names and figures are invented. Collectors depend on your environment, so they aren't included. Chapter 15 describes what each one gathers, and the files in `samples/collected/` show the format they should write.

## Before you use this in production

- **Compliance mode is permanent.** `modules/log-archive` and `modules/backup-vault` lock data for the retention period, and nobody can undo that, not even the root user. Try them on test resources first, and agree retention periods with your records team.
- **Test service control policies on a staging OU first.** The region policy exempts global services. Check its list against the AWS documentation for the services you use.
- **Check the mapping to the standards.** How APRA's standards apply to your organisation is for your risk and compliance team to decide. This code helps you build what they can say yes to. It is not compliance advice.

## Editions

Each edition of the book has a matching tag in this repository, starting with `first-edition`. Use the tag that matches your copy; `main` keeps moving.

## Licence

MIT. Copyright (c) 2026 Water Apps Pty Ltd. See `LICENSE`.
