# Trend Micro 2021Q3 Hands-on lab Infra in Azure

## Overview
- Automate the Hands-on lab infra in Azure
- Lab diagram is in the ./data folder

## How to use

### Requirements
- Windows or Linux machine
- Terraform CLI: https://learn.hashicorp.com/tutorials/terraform/install-cli
- Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
- Git: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
- Azure account

### Initialize on Windows
- Open Powershell as Administrator, Install chocolatey, after that reopen Powershell as Administrator
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```
- Install terraform, git, azure-cli using chocolatey	
```powershell
choco install terraform git azure-cli -y
```
- Login to azure cli to get ID value
```
az login
```
- Create a service principle with the above ID value (https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
```
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<above id value>"
```
in the output, note the below for terraform to run
 - appId is the client_id defined above.
 - password is the client_secret defined above.
 - tenant is the tenant_id defined above.

### Let's start
- Review and update values in terraform.tfvars.example to match your Azure environment
- Save as new file, name it: terraform.tfvars  
- When you are ready, open terminal and run below commands:
```
  $ git clone https://github.com/trendlabs/2021Q3HOL-Azure-Infra.git
  $ cd 2021Q3HOL-Azure-Infra
  $ terraform init
  $ terraform plan -out=tfplan
  $ terraform apply -auto-approve tfplan
```
if there are some errors during the apply process, you need to review variables you set in the terraform.tfvars to make sure everything is correctly set, the run the last command again, or destroy (with command below) and run 2 last commands again
*Note: terraform needs about 45-60min to provision labs (depends on the number of labs)*
- After infra provisioned, make sure a file ***terraform.tfstate*** generated in the same folder. This file is critical for your to clean up all the labs after the session
- When you finish the hands-on, to clean-up all the infra, run below:
```
  $ terraform destroy -auto-approve
```

## Lab access
- After provisioning , you can access the lab guide in folder "outputs" - find the file relevant to your resource-group names, each participant will have a public IP stated in the file together with user/password
