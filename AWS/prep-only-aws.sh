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
echo "This script generates AWS Secrets.
The following actions are taken:
================
1. Prompts for Cloud Connector API Key and Admin Credentials
2. Creates Secrets in AWS Secrets Manager for the Cloud Connector
================${reset}
"

# Prompt for AWS access information
read -p "${purple}AWS Access Key Id:${reset} " aws_key
read -p "${purple}AWS Secret Access Key:${reset} " aws_secret
echo ""
read -p "${purple}Cloud Connector API Key:${reset} " cc_api_key
read -p "${purple}Cloud Connector Admin:${reset} " cc_user
read -p "${purple}Cloud Connector Password:${reset} " -s cc_pass
echo -e "\n"
read -p "${purple}The above resources will be created. Continue? [y|n]: ${reset}" confirm
echo ""
if [ $confirm = "y" ]
then
    # Create AWS Secret for Cloud Connectors
    randomsuffix=$(echo $RANDOM)
    echo "${purple}Creating Cloud Connector Secrets in AWS Secrets Manager...${reset}"
    aws secretsmanager create-secret --name ZSCALER/CLOUDCONNECTOR-$randomsuffix \
     --description "Zscaler Cloud Connector Secrets" \
    --secret-string '{"api_key":"'"$cc_api_key"'","username":"'"$cc_user"'","password":"'"$cc_pass"'"}'
    echo "Cloud Connector Secret: ZSCALER/CLOUDCONNECTOR/SECRETS/$randomsuffix" | tee -a zsccawsprep-$randomsuffix.output
else
    echo "Quitting script..."
    exit
fi