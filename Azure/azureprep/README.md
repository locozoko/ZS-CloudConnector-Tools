# Azure Prerequisites Prep Scripts

Scripts that configure the Cloud Connector prerequisites for Azure deployment.

## Description

Creating the prerequisite resources in Azure can be done manually via the Azure Portal as documented in: https://help.zscaler.com/cloud-connector/deploying-cloud-connector-microsoft-azure.

The scripts in this project allow you to either manually run the resource creation by referencing Azure CLI commands
or it can generate all the required resources in your Azure account automatically based on a few pieces of input

## Getting Started

### Dependencies

* All testing was completed on macos and Azure Cloud Shell.
* Scripts should work with slight modifications on Windows if using WSL with an linux OS such as Ubuntu
* Scripts will check for appropriate dependences and try to install them: unzip, homebrew, Azure CLI
* Requires a valid Azure admin account to be logged into the Azure CLI
* Requires a valid Cloud Connector admin account and API Key

### Installing

* Simply copy this repo to your macos device or into the Azure cloud shell:
```
https://github.com/locozoko/cloudconnector-tools.git
```
* Navigate to the cloudconnector-tools/Azure/azureprep directory

### Executing program

#### prep_azure_linuxmacos.sh
This script was created to run from a macos or linux machine and will automatically generate all the required prerequisite resources

* Log into Azure CLI
```
az login
```
* Run this script
```
./prep_azure_linuxmacos.sh
```
* Confirm the Azure tenant and subscription looks correct
* Provide the desired Azure Region to create the resource in
* Provide the Cloud Connector credentials and API Key
* Provide the desired prefix to use for resource names (defaults to "zscalercc" if left empty)
* Select the deployment tool you will use for the Cloud Connectors: arm or terraform
* Upon successfully creation of resources, the script will output the information to the screen and into a output.log file
* When ready to deploy the Cloud Connectors via arm or terraform, provide the information from this script's output

#### prep_azurecli_commands.txt
This file is not a script but information those who might not want to use a bash script to automatically create resources

* All the Azure CLI commands equivalent to the Azure Web Portal are listed in this file
* Replace the Example Names, Ids, with desired ones and execute them from a machine with Azure CLI or the Azure Cloud Shell

#### prep_azurecloudshell.sh
This script was created to run from the Azure Cloud Shell and will automatically generate all the required prerequisite resources
* Log into Azure Portal: https://portal.azure.com
* Open the Cloud Shell (if opening for first time, Azure will prompt you to create a storage mount)
```
az login
```
* Run this script
```
./prep_azure_linuxmacos.sh
```
* Confirm the Azure tenant and subscription looks correct
* Provide the desired Azure Region to create the resource in
* Provide the Cloud Connector credentials and API Key
* Provide the desired prefix to use for resource names (defaults to "zscalercc" if left empty)
* Select the deployment tool you will use for the Cloud Connectors: arm or terraform
* Upon successfully creation of resources, the script will output the information to the screen and into a output.log file
* When ready to deploy the Cloud Connectors via arm or terraform, provide the information from this script's output

## Help & Authors

Contributors names and contact info:

Zoltan Kovacs (zkovacs@zscaler.com)
Blanco Lam (blam@zscaler.com)

## Version History

* 0.2
    * Various bug fixes and optimizations
    * See [commit change]() or See [release history]()
* 0.1
    * Initial Release

## License

This project is licensed under the [NAME HERE] License - see the LICENSE.md file for details