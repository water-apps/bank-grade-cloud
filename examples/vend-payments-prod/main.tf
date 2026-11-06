# Chapter 4: requesting an account is a pull request that adds a block like this.
module "payments_prod" {
  source = "../../modules/account-vending"

  name        = "payments-prod"
  ou          = "workloads-production"
  owner       = "payments-platform@bank.example"
  criticality = "critical"
  critical_op = "payments"
  data_class  = "confidential-customer"
  services    = ["aws-eks", "aws-rds", "aws-msk"]
}

output "account_id" {
  value = module.payments_prod.account_id
}
