## 1.1.0 (September 7, 2021)
NOTES:
* Updated README to include prerequisites to accept vm image terms
* Additional details for minimum Managed Identity custom role permissions
* Removed ccvm_instance_size selection
* Variable naming syntax standardization
* General README and descriptions cleanup
* Renamed base_1cc to base_cc
* Removed uneccesary base deployment resource creations
* Removed byo_pip_address for base greenfield deployment types
* Modified base deployment types for single /24 CC subnet configuration

ENHANCEMENTS:
* New cc_lb deployment type for just cloud connector + lb deployment brownfield deployments. Mirror of Azure Marketplace deployment w/ customization capabilities
* Custom variable options added to enable/disable bring-your-own resources for Cloud Connector deployment in existing environments. Custom paramaters include: BYO existing Resource Group, PIP, NAT Gateway and associations, VNET, subnet and address space.
* Added network_address_space and cc_subnet variable to terraform.tfvars for users to easily modify/define their own VNET and subnet sizes

BUGS:
* base deployment variables and output syntax fixes


## 1.0.1 (August 24, 2021)
ENHANCEMENTS:
* ccvm-instance-size validation constraints added


## 1.0.0 (August 24, 2021)

NOTES:
* Initial code revision check-in

ENHANCEMENTS:
* terraform-zscc-lb-azure module for multi-cloud connector deployments behind Azure LB
* terraform.tfvars additions: http-probe-port for CC listener service + LB health probing; cc_count + vm_count customizations for scaled deployment testing; ccvm-instance-size for Azure VM size selections

FEATURES:
* Customer solutioned POV templates for greenfield/brownfield Azure Cloud Connector Deployments
* Sanitized README file
* ZSEC updated for new deployment type selections

BUG FIXES: 
* N/A
