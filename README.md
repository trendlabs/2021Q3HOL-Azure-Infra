# Trend Micro 2021Q3 Hands-on lab Infra in Azure

## Overview
- Automate the Hands-on lab infra in Azure
- Lab diagram is in the ./data folder

## How to use

### Requirements (see below section for install these required packages)
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
- Install terraform, git, azure-cli using chocolatey	(restart Powershell after that)
```powershell
choco install terraform git azure-cli -y
```
- Login to azure cli to get ID value (below command will open a browser tab asking for login to Azure portal). 
```
az login
```
Returned result is in JSON, find the block similar to the below (note the **"Microsoft Azure Enterprise"**)
```
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "xxxxyyyy-XXXX-YYYY-ZZZZ-xxxxyyyyzzzz",
    "id": "xxxxyyyy-XXXX-YYYY-ZZZZ-xxxxyyyyzzzz",
    "isDefault": false,
    "managedByTenants": [
      {
        "tenantId": "xxxxyyyy-XXXX-YYYY-ZZZZ-xxxxyyyyzzzz"
      }
    ],
    "name": "Microsoft Azure Enterprise",
    "state": "Enabled",
    "tenantId": "xxxxyyyy-XXXX-YYYY-ZZZZ-xxxxyyyyzzzz",
    "user": {
      "name": "xyz@zxy.com",
      "type": "user"
    }
  }
```  
**Note:** Take note the above id (which is the *azure_subcription_id* in terraform.vars below)

- Create a service principle with the above ID value (https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
```
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<above subcription id value>"
```
If the command executed successfully, you will receive something as below
```
{
  "appId": "xxxxyyyy-XXXX-YYYY-ZZZZ-xxxxyyyyzzzz",
  "displayName": "azure-cli-2021-08-14-13-34-24",
  "name": "xxxxyyyy-XXXX-YYYY-ZZZZ-xxxxyyyyzzzz",
  "password": "random string generated by azure",
  "tenant": "xxxxyyyy-XXXX-YYYY-ZZZZ-xxxxyyyyzzzz"
}
```
in the output, note the below for terraform to run
 - appId (which is the *azure_client_id* in terraform.vars below)
 - password (which is the *azure_client_secret* in terraform.vars below)
 - tenant (which is the *azure_tenant_id* in terraform.vars below)

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
