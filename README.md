# **# **Deployment steps****

cd cloud_infrastructure/cloud_setup

rm -rf .terraform

rm terraform.lock.hcl

terraform init --backend-config=backend-config.hcl

terraform workspace select {work_spacename}

terraform init --backend-config=backend-config.hcl

terraform apply --var-file="tfvars/dev.tfvars" -lock=false
