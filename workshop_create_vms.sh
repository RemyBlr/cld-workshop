#!/bin/bash

# Check if number of VMs is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <number_of_VMs> [VM_name_prefix]"
  exit 1
fi

################## Variables ##################
VM_COUNT=$1
VM_PREFIX=${2:-"myVM"}

RESOURCE_GROUP="myResourceGroup"
LOCATION="eastus"
VNET="myVnet"

PUBLIC_SUBNET="PublicSubnet"
PRIVATE_SUBNET="PrivateSubnet"

PUBLIC_NSG="PublicNSG"
PRIVATE_NSG="PrivateNSG"

ROUTE_TABLE="myRouteTable"

################## Checks ##################

# Check if the resource group exists
if ! az group show --name $RESOURCE_GROUP &> /dev/null; then
    az group create --name $RESOURCE_GROUP --location $LOCATION
    echo "Resource group $RESOURCE_GROUP created."
else
    echo "Resource group $RESOURCE_GROUP already exists."
fi

# Check if virtual network exists
# Redirect tp /dev/null to suppress output
if ! az network vnet show --resource-group $RESOURCE_GROUP --name $VNET &> /dev/null; then
    # Create virtual network (public)
    az network vnet create --resource-group $RESOURCE_GROUP --name $VNET --address-prefix 10.0.0.0/16 --subnet-name $PUBLIC_SUBNET --subnet-prefix 10.0.1.0/24
    echo "Virtual network $VNET with subnet $PUBLIC_SUBNET created."

    # Create virtual network (private)
    az network vnet subnet create --resource-group $RESOURCE_GROUP --vnet-name $VNET --name $PRIVATE_SUBNET --address-prefix 10.0.2.0/24
    echo "Private subnet $PRIVATE_SUBNET created."
else
    echo "Virtual network $VNET already exists."
fi

# Check if NSGs exist (public)
if ! az network nsg show --resource-group $RESOURCE_GROUP --name $PUBLIC_NSG &> /dev/null; then
    # Create NSGs if they don't exist
    az network nsg create --resource-group $RESOURCE_GROUP --name $PUBLIC_NSG
    echo "Network security group $PUBLIC_NSG created."
fi

# Check if NSGs exist (public)
if ! az network nsg show --resource-group $RESOURCE_GROUP --name $PRIVATE_NSG &> /dev/null; then
    # Create NSGs if they don't exist
    az network nsg create --resource-group $RESOURCE_GROUP --name $PRIVATE_NSG
    echo "Network security group $PRIVATE_NSG created."
fi

# Check if NSG rules exist (public subnet)
if ! az network nsg rule show --resource-group $RESOURCE_GROUP --nsg-name $PUBLIC_NSG --name AllowSSH &> /dev/null; then
     # Create NSG rules if they don't exist
    az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $PUBLIC_NSG --name AllowSSH --protocol Tcp --direction Inbound --priority 1000 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 --access Allow
    echo "NSG rule AllowSSH for $PUBLIC_NSG created."
fi

# Check if NSG rules exist (private subnet)
if ! az network nsg rule show --resource-group $RESOURCE_GROUP --nsg-name $PRIVATE_NSG --name AllowSSHFromPublic &> /dev/null; then
     # Create NSG rules if they don't exist
    az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $PRIVATE_NSG --name AllowSSHFromPublic --protocol Tcp --direction Inbound --priority 1000 --source-address-prefix '10.0.1.0/24' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 22 --access Allow
    echo "NSG rule AllowSSHFromPublic for $PRIVATE_NSG created."
fi

# Associate NSGs with subnets (public)
PUBLIC_SUBNET_NSG=$(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $VNET --name $PUBLIC_SUBNET --query "networkSecurityGroup.id" --output tsv)
if [[ "$PUBLIC_SUBNET_NSG" != *"$PUBLIC_NSG"* ]]; then
    az network vnet subnet update --resource-group $RESOURCE_GROUP --vnet-name $VNET --name $PUBLIC_SUBNET --network-security-group $PUBLIC_NSG
    echo "Associated NSG $PUBLIC_NSG with subnet $PUBLIC_SUBNET."
fi

# Associate NSGs with subnets (private)
PRIVATE_SUBNET_NSG=$(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $VNET --name $PRIVATE_SUBNET --query "networkSecurityGroup.id" --output tsv)
if [[ "$PRIVATE_SUBNET_NSG" != *"$PRIVATE_NSG"* ]]; then
    az network vnet subnet update --resource-group $RESOURCE_GROUP --vnet-name $VNET --name $PRIVATE_SUBNET --network-security-group $PRIVATE_NSG
    echo "Associated NSG $PRIVATE_NSG with subnet $PRIVATE_SUBNET."
fi

# Check if route table exists
if ! az network route-table show --resource-group $RESOURCE_GROUP --name $ROUTE_TABLE &> /dev/null; then
    # Create route table if it doesn't exist
    az network route-table create --resource-group $RESOURCE_GROUP --name $ROUTE_TABLE
    echo "Route table $ROUTE_TABLE created."
fi

# Associate route table with subnets
if ! az network route-table route show --resource-group $RESOURCE_GROUP --route-table-name $ROUTE_TABLE --name myRoute &> /dev/null; then
    az network route-table route create --resource-group $RESOURCE_GROUP --route-table-name $ROUTE_TABLE --name myRoute --address-prefix 0.0.0.0/0 --next-hop-type Internet
    echo "Route myRoute in $ROUTE_TABLE created."
fi

################## Create VMs ##################

# Loop to create VMs
for i in $(seq 1 $VM_COUNT); do

    VM_NAME="${VM_PREFIX}-${i}"

    # Check if VM exists
    if ! az vm show --resource-group $RESOURCE_GROUP --name $VM_NAME &> /dev/null; then

        # Create public IP adr for SSH server
        az network public-ip create --resource-group $RESOURCE_GROUP --name "${VM_NAME}PublicIP"

        # Create network interface
        az network nic create --resource-group $RESOURCE_GROUP --name "${VM_NAME}Nic" --vnet-name $VNET --subnet $PUBLIC_SUBNET --network-security-group $PUBLIC_NSG --public-ip-address "${VM_NAME}PublicIP"

        # Create VM
        az vm create --resource-group $RESOURCE_GROUP --name $VM_NAME --nics "${VM_NAME}Nic" --image Ubuntu2204 --admin-username azureuser --generate-ssh-keys
        echo "Created VM: $VM_NAME"
    else
        echo "VM $VM_NAME already exists."
    fi
done

echo "VMs created successfully"
