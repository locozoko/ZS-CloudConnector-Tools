#/bin/bash
set -e
red=`tput setaf 1`
purple=`tput setaf 5`
blue=`tput setaf 4`
reset=`tput sgr0`

# Script description
echo "${blue} ____    ___   ___    _    _      ___   ____  ";
echo ")___ (  (  _( / _(   )_\  ) |    ) __( /  _ \ ";
echo "  / /_  _) \  ))_   /( )\ | (__  | _)  )  ' / ";
echo " )____()____) \__( )_/ \_()____( )___( |_()_\ ";
echo "                                              ";
echo "This script generates AWS Secrets then Starts a Deployment
The following actions are taken:
================
1. Prompts for Cloud Connector API Key and Admin Credentials
2. Prompts for terraform information
3. Create a NEW AWS VPC and puts the chosen (ZSCC) resources into it
================${reset}
"
# Check to make sure the script is in the Zscaler Cloud Connector terraform template folder
FILE1=zsec
FILE2=terraform.tfvars
if test -f "$FILE1"; then
    echo ""
    if test -f "$FILE2"; then 
        # User input for Zscaler Cloud Information
        # if .zsecrc is not present we'll assume that AWS env was never set
        if [[ ! -e ./.zsecrc ]]; then
            read -p "${purple}AWS Access Key Id:${reset} " aws_key
            read -p "${purple}AWS Secret Access Key:${reset} " aws_secret
            echo "${purple}Here's an up-to-date list of all the Azure Regions:${reset} "
            aws ec2 describe-regions --output table --query 'Regions[*].[RegionName]'
            read -p "${purple}AWS Region :${reset} " aws_region
            echo "export AWS_ACCESS_KEY_ID=${aws_key}" > .zsecrc
            echo "export AWS_SECRET_ACCESS_KEY=${aws_secret}" >> .zsecrc
            echo "export AWS_DEFAULT_REGION=$aws_region" >> .zsecrc
        fi
        echo ""
        read -p "${purple}Cloud Connector API Key:${reset} " cc_api_key
        read -p "${purple}Cloud Connector Admin:${reset} " cc_user
        read -p "${purple}Cloud Connector Password:${reset} " -s cc_pass
        echo -e "\n"
        read -p "${purple}Cloud Connector Provisioning URL:${reset} " cc_prov_url     
        randomsuffix=$(echo $RANDOM)
        # Create AWS Secret for Cloud Connectors
        echo "${purple}Creating Cloud Connector Secrets in AWS Secrets Manager...${reset}"
        aws secretsmanager create-secret --name ZSCALER/CLOUDCONNECTOR-$randomsuffix \
        --description "Zscaler Cloud Connector Secrets" \
        --secret-string '{"api_key":"'"$cc_api_key"'","username":"'"$cc_user"'","password":"'"$cc_pass"'"}'
        # Set the variables for AWS Region and ZSCC Secrets
        echo ""
        
        echo "${purple}AWS Region: ${blue}$aws_region" | tee zsccawsprep-$randomsuffix.output
        echo "${purple}Cloud Connector Secret: ${blue}ZSCALER/CLOUDCONNECTOR/SECRETS/$randomsuffix" | tee -a zsccawsprep-$randomsuffix.output
        echo ""
        echo "${purple}Output has been saved to ${blue}zsccawsprep-$randomsuffix.output${purple} in the current directory${reset}"
        # Add the variables to the terraform.tfvars file to not be double prompted for same information
        echo " ">> terraform.tfvars
        echo " ">> terraform.tfvars
        echo "#####################################################################################################################" >> terraform.tfvars
        echo "                ##### Variables added automatically from the prep deployment script  #####" >> terraform.tfvars
        echo "#####################################################################################################################" >> terraform.tfvars
        echo " ">> terraform.tfvars
        echo "cc_vm_prov_url = \"$cc_prov_url\"" >> terraform.tfvars
        echo "secret_name = \"ZSCALER/CLOUDCONNECTOR-${randomsuffix}\"" >> terraform.tfvars
        echo "http-probe-port = 50000" >> terraform.tfvars
        echo "http-probe-port = 50000" | tee -a zsccawsprep-$randomsuffix.output
        echo "provisioning template url= \"$cc_prov_url\"" | tee -a zsccawsprep-$randomsuffix.output
    else   
        echo "${red}This script must be run in the root directory of the AWS Terraform Cloud Connector template..."
        echo "Quitting...${reset}"
    exit
    fi
else
    echo "${red}This script must be run in the root directory of the AWS Terraform Cloud Connector template..."
    echo "Quitting...${reset}"
    exit
fi

# run the terraform deployment bash script
./zsec up