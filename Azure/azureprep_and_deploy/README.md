# Zscaler Cloud Connector Azure Prep and Deployment Script

Deploy Zscaler Cloud Connectors and Prerequisites in Azure Cloud Shell with Terraform in just a few clicks!

## Description

This script takes the prerequisites prep script to the "next level" by also deploying Cloud Connector to Azure.
Think of this as a CloudConnector-in-a-Box perfect for labs, testing, or even a POV.
The underlying terraform template is the default one found in the Cloud Connector Admin Console.

## Getting Started

### Dependencies

* This project only runs in the Azure Cloud Shell
* You will be prompted to mount storage if using Azure Cloud Shell the first time (it's just a single click)
* Installs unzip into the Azure Cloud Shell, as required by the ZSCC Terraform Template
* Requires a valid Azure admin account to access Azure Cloud Shell
* Requires a valid Cloud Connector admin account and API Key

### Installing

* Simply copy this repo to your macos device or into the Azure cloud shell:
```
git clone https://github.com/locozoko/cloudconnector-tools.git
```
* Navigate to the cloudconnector-tools/Azure/azureprep_and_deploy directory

### Executing program

Running this simple script will automatically create all the resources in Azure for prerequisites.
It will then deploy the Cloud Connector of your choice (single or 2 with load balancer) into a NEW VNet.

Optionally, uncomment and modify items 6-22 in the tarraform.tfvars file to customize the deployment.
This allows you to change the Subnet CIDR or do things like deploy the resources into an existing VNet.
DO NOT ALTER ITEMS 1-5 AS THIS SCRIPT WILL MODIFY THOSE BASED ON YOUR INPUT!
ALSO, DO NOT DEPLOY INTO AN EXISTING SUBNET WITH EXISTING RESOURCES THAT REQUIRE INBOUND CONNECTIVITY
AS A NAT GATEWAY AND ROUTE WILL BE ATTACHED TO THAT SUBNET.

* Log into Azure Portal: https://portal.azure.com
* Open the Cloud Shell (if opening for first time, Azure will prompt you to create a storage mount)
* If you haven't done so already, clone this repo into the Azure cloud shell:
```
git clone https://github.com/locozoko/cloudconnector-tools.git
cd cloudconnector-tools/Azure/azureprep_and_deploy
```
* Run this script with the 3 parameters to seelect deployment type, Azure Region, and a prefix for the resource that will be created:
```
bash prep_and_deploycc_azurecloudshell.sh
```
* Confirm the Azure tenant and subscription looks correct
* Provide the desired Azure Region to create the resource in
* Provide the Cloud Connector credentials and API Key
* Provide the desired prefix to use for resource names (defaults to "zscalercc" if left empty)
* Upon successfully creation of resources, the script will output the information to the screen and into a output.log file
* You will then be prompted for the Cloud Connector deployment type: base | base_cc | base_cc_lb | cc_lb (see below for details)

## Help & Authors

Contributors names and contact info:

Zoltan Kovacs (zkovacs@zscaler.com)
Blanco Lam (blam@zscaler.com)

## Version History

* 0.2
    * Adding ability to define input as parameters instead of just interactively
* 0.1
    * Initial Release

## License

This project is licensed under the [NAME HERE] License - see the LICENSE.md file for details





# Zscaler Cloud Connector Cluster Infrastructure Setup

**Terraform configurations and modules for deploying Zscaler Cloud Connector Cluster in Azure.**

## Prerequisites (You will be prompted for Azure application credentials and region during deployment)

1. Azure Subscription Id
[link to Azure subscriptions](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade)
2. Application (client) ID  See: https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal)
3. Directory (tenant) ID
4. Client Secret Value
5. Azure Region (e.g. westus2)
6. The public IP address (Azure Public IP) from which Cloud Connector will access the Zscaler Cloud
7. User created Azure Managed Identity.
    Role Assignment:  Network Contributor (minimum: Microsoft.Network/networkInterfaces/read)
    Scope: Subscription or Resource Group (where Cloud Connector VMs will be deployed)
8. Azure Vault URL with Zscaler Cloud Connector Credentials (E.g. https://zscaler-cc-demo.vault.azure.net)
   Add an access policy to the above Key Vault as below
   1. Secret Permissions: Get, List
   2. Select Principal: The Managed Identity created in the above step
9. A valid Zscaler Cloud Connector provisioning URL
10. Accept the Cloud Connector VM image terms for the Subscription(s) where Cloud Connector is to be deployed. This can be done via the Azure Portal    Cloud Shell or az cli / powershell with a valid admin user/service principal.
    Run Command: az vm image terms accept --urn zscaler1579058425289:zia_cloud_connector:zs_ser_cc_03:latest

## Cloning the repo (Internal Zscaler Use Only)

`git clone https://bitbucket.corp.zscaler.com/scm/ec/bac_utils.git`

## Deploying the cluster
(The automated tool can run only from MacOS and Linux. Make sure Distro has Unzip installed. E.g. apt-get install unzip)   
 
**1. Greenfield Deployments**

(Use this if you are building an entire cluster from ground up.
 Particularly useful for a Customer Demo/PoC/dev-test/QA environment)

Edit the terraform.tfvars file under azure/deployment/terraform to setup your Cloud Connector(Details are documented inside the file)
```
bash
cd azure/deployment/terraform
./zsec up
```
**Greenfield Deployment Type:**

```
Deployment Type: (base | base_1cc | base_cc_lb ):
**base** - Creates: 1 Resource Group containing; 1 VNET w/ 2 subnets (bastion + workload); 1 Ubuntu server workload w/ 1 Network Interface + NSG; 1 Ubuntu Bastion Host w/ 1 PIP + 1 Network Interface + NSG; generates local key pair .pem file for ssh access

**base_cc** - Base Deployment + Creates 1 Cloud Connector VM w/ 1 PIP; 1 NAT Gateway; 1 Mgmt Subnet + Network Interface + NSG, 1 Service Subnet + Network Interface + NSG

**base_cc_lb** - Base Deployment + Creates 2 Cloud Connectors in availability set with 1 PIP; 1 NAT Gateway; 1 Mgmt Subnet + Network Interfaces + NSG, 1 Service Subnet + Network Interfaces + NSG; 1 Internal Azure LB. Number of Workload and Cloud Connectors deployed customizable within terraform.tfvars cc_count and vm_count variables
```

## Destroying the cluster
```
./zsec destroy
```

## Notes

1. For auto approval set environment variable **AUTO_APPROVE** or add `export AUTO_APPROVE=1`
2. For deployment set environment variable **DTYPE** to the required deployment type or add `export DTYPE=base_cc_lb`
3. To provide new credentials or location, delete the autogenerated .zsecrc file in your current working directory and re-run zsec.

**2. Brownfield Deployments**

```
Deployment Type: (cc_lb):
**cc_lb** - Creates 1 Resource Group containing: 1 VNET w/ 1 subnet; 2 Cloud Connectors in availability set with 1 PIP; 1 NAT Gateway; Mgmt Network Interfaces + NSG, Service Network Interfaces + NSG; 1 Internal Azure LB; generates local key pair .pem file for ssh access. Number of Cloud Connectors deployed and ability to use existing resources (resource group(s), VNET/Subnets, PIP, NAT GW) customizable withing terraform.tfvars custom variables

Deployment type cc_lb provides numerous customization options within terraform.tfvars to enable/disable bring-your-own resources for
Cloud Connector deployment in existing environments. Custom paramaters include: BYO existing Resource Group, PIP, NAT Gateway and associations,
VNET, subnet and address space.
```

The following Cloud Connector terraform modules are also provided for a brownfield deployment
 ```

ls azure/deployment/terraform/tfdir/modules
terraform-zscc-azure (for single CC deployments)
terraform-zscc-lb-azure (for multi CC deployments; includes Azure LB)
```
