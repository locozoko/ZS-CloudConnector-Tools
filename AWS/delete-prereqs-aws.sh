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
echo "This script delete the AWS Secret created with the prep script
The following actions are taken:
================
1. Confirms the secret to be deleted *Only if running from the same directory as prep script!
2. Deletes the secret using the AWS CLI
================${reset}
"

# Display the AWS Secrets to be deleted
secretid=$(cat zsccawsprep-*.output | grep "Cloud Connector Secret" | cut -d '/' -f4)
echo ""
echo "The following AWS Secret was found: " ${purple} ZSCALER/CLOUDCONNECTOR-$secretid ${reset}
echo ""
while true; do
    read -p "${red}Do you wish to delete this AWS Secret [y|n]? ${reset}" yn
    case $yn in
        [Yy]* ) aws secretsmanager delete-secret --secret-id ZSCALER/CLOUDCONNECTOR-$secretid --recovery-window-in-days 7; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done