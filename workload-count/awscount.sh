#!/bin/bash
set -e
echo ""
allprofiles=$(cat ~/.aws/credentials | grep "\[" | sed 's/[][]//g')
echo "Available AWS Profiles: "
echo "$allprofiles"
echo ""
read -p "Profile to use: " PRO 

export AWS_PROFILE=${PRO}

accounts=$(aws sts get-caller-identity --query 'Account' --output text)

source_profile=${AWS_PROFILE}  # The "source_profile" in your aws-cli config
i=1
sum=0

for account in $accounts; do
  # Sample command 1: Get the current account id (should match)
  this_account=$(  aws sts get-caller-identity \
                     --output text \
                     --query 'Account')
  echo "Account: $account ($this_account)"
  # Count EC2 instances per account
  for region in `aws ec2 describe-regions --output text | cut -f4`
  do
    count=$(aws ec2 describe-instances --region $region --query 'Reservations[*].Instances[*].[InstanceId]' --output text | wc -l | xargs)
     echo -e "EC2 instances in $region: $count"
     sum=$((sum + count)) 
    i=$((i + 1))
  done
done
current=$(date)
echo
echo "----------------------" | tee -a awscount.log
echo "Timestamp: $current"  | tee -a awscount.log
echo "Profile: $PRO" | tee -a awscount.log
echo "Total EC2 instances in AWS Account $account: $sum" | tee -a awscount.log
echo "----------------------" | tee -a awscount.log
echo ""

unset AWS_PROFILE
