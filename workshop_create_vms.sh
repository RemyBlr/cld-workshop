#!/bin/bash

# Check if number of VMs is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <number_of_VMs> [VM_name_prefix]"
  exit 1
fi

################## Variables ##################
VM_COUNT=$1
VM_PREFIX=${2:-"myVM"}

RESOURCE_GROUP="myResourceGroup2"
LOCATION="switzerlandnorth"
VNET="myVnet"

PUBLIC_SUBNET="PublicSubnet"
PRIVATE_SUBNET="PrivateSubnet"

PUBLIC_NSG="PublicNSG"
PRIVATE_NSG="PrivateNSG"

ROUTE_TABLE="myRouteTable"

# Paths for SSH keys
PRIVATE_KEY_PATH="$HOME/.ssh/CldPrivateKey"
SSH_KEY_PATH="$HOME/.ssh/CldSSHKey"

################## Functions ##################

# Function to generate SSH keys if they don't exist
generate_ssh_keys() {
    if [ ! -f "$PRIVATE_KEY_PATH" ]; then
        ssh-keygen -t rsa -b 2048 -f "$PRIVATE_KEY_PATH" -N ""
        echo "Private key generated at $PRIVATE_KEY_PATH"
    fi

    if [ ! -f "$SSH_KEY_PATH" ]; then
        ssh-keygen -t rsa -b 2048 -f "$SSH_KEY_PATH" -N ""
        echo "SSH key generated at $SSH_KEY_PATH"
    fi
}

# Function to create a resource group if it doesn't exist
create_resource_group() {
    if ! az group show --name $RESOURCE_GROUP &> /dev/null; then
        az group create --name $RESOURCE_GROUP --location $LOCATION
        echo "Resource group $RESOURCE_GROUP created."
    else
        echo "Resource group $RESOURCE_GROUP already exists."
    fi
}

# Function to create a virtual network and subnets if they don't exist
create_virtual_network() {
    if ! az network vnet show --resource-group $RESOURCE_GROUP --name $VNET &> /dev/null; then
        az network vnet create --resource-group $RESOURCE_GROUP --name $VNET --address-prefix 10.0.0.0/16 --subnet-name $PUBLIC_SUBNET --subnet-prefix 10.0.1.0/24
        echo "Virtual network $VNET with subnet $PUBLIC_SUBNET created."

        az network vnet subnet create --resource-group $RESOURCE_GROUP --vnet-name $VNET --name $PRIVATE_SUBNET --address-prefix 10.0.2.0/24
        echo "Private subnet $PRIVATE_SUBNET created."
    else
        echo "Virtual network $VNET already exists."
    fi
}

# Function to create a network security group (NSG) if it doesn't exist
create_nsg() {
    local nsg_name=$1
    if ! az network nsg show --resource-group $RESOURCE_GROUP --name $nsg_name &> /dev/null; then
        az network nsg create --resource-group $RESOURCE_GROUP --name $nsg_name
        echo "Network security group $nsg_name created."
    else
        echo "Network security group $nsg_name already exists."
    fi
}

# Function to create NSG rules if they don't exist
create_nsg_rules() {
    local nsg_name=$1
    local rule_name=$2
    local source_prefix=$3
    local dest_prefix=$4
    if ! az network nsg rule show --resource-group $RESOURCE_GROUP --nsg-name $nsg_name --name $rule_name &> /dev/null; then
        az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $nsg_name --name $rule_name --protocol Tcp --direction Inbound --priority 1000 --source-address-prefix "$source_prefix" --source-port-range '*' --destination-address-prefix "$dest_prefix" --destination-port-range 22 --access Allow
        echo "NSG rule $rule_name for $nsg_name created."
    fi
}

# Function to associate NSGs with subnets if not already associated
associate_nsg_with_subnet() {
    local subnet_name=$1
    local nsg_name=$2
    local subnet_nsg=$(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $VNET --name $subnet_name --query "networkSecurityGroup.id" --output tsv)
    if [[ "$subnet_nsg" != *"$nsg_name"* ]]; then
        az network vnet subnet update --resource-group $RESOURCE_GROUP --vnet-name $VNET --name $subnet_name --network-security-group $nsg_name
        echo "Associated NSG $nsg_name with subnet $subnet_name."
    fi
}

# Function to create a route table if it doesn't exist
create_route_table() {
    if ! az network route-table show --resource-group $RESOURCE_GROUP --name $ROUTE_TABLE &> /dev/null; then
        az network route-table create --resource-group $RESOURCE_GROUP --name $ROUTE_TABLE
        echo "Route table $ROUTE_TABLE created."
    fi
}

# Function to create a route if it doesn't exist
create_route() {
    if ! az network route-table route show --resource-group $RESOURCE_GROUP --route-table-name $ROUTE_TABLE --name myRoute &> /dev/null; then
        az network route-table route create --resource-group $RESOURCE_GROUP --route-table-name $ROUTE_TABLE --name myRoute --address-prefix 0.0.0.0/0 --next-hop-type Internet
        echo "Route myRoute in $ROUTE_TABLE created."
    fi
}

# Function to create the SSH server VM
create_ssh_server_vm() {
    # Create a public IP address for the SSH server
    az network public-ip create --resource-group $RESOURCE_GROUP --name myPublicIP

    # Create a network interface for the SSH server
    az network nic create --resource-group $RESOURCE_GROUP --name myNic --vnet-name $VNET --subnet $PUBLIC_SUBNET --network-security-group $PUBLIC_NSG --public-ip-address myPublicIP

    # Create the SSH server VM
    az vm create --resource-group $RESOURCE_GROUP --name mySSHServer --nics myNic --image Ubuntu2204 --admin-username azureuser --ssh-key-values "${SSH_KEY_PATH}.pub"
    echo "SSH server VM created."
}

# Function to create the specified number of VMs
create_vms() {
    for i in $(seq 1 $VM_COUNT); do
        VM_NAME="${VM_PREFIX}-${i}"

        if ! az vm show --resource-group $RESOURCE_GROUP --name $VM_NAME &> /dev/null; then
            az network public-ip create --resource-group $RESOURCE_GROUP --name "${VM_NAME}PublicIP"
            az network nic create --resource-group $RESOURCE_GROUP --name "${VM_NAME}Nic" --vnet-name $VNET --subnet $PUBLIC_SUBNET --network-security-group $PUBLIC_NSG --public-ip-address "${VM_NAME}PublicIP"
            az vm create --resource-group $RESOURCE_GROUP --name $VM_NAME --nics "${VM_NAME}Nic" --image Ubuntu2204 --admin-username azureuser --ssh-key-values "${PRIVATE_KEY_PATH}.pub"
            echo "Created VM: $VM_NAME"
        else
            echo "VM $VM_NAME already exists."
        fi
    done
}

################## Main ##################

# Generate SSH keys if they don't exist
generate_ssh_keys

# Create the resource group
create_resource_group

# Create the virtual network and subnets
create_virtual_network

# Create the network security groups (NSGs)
create_nsg $PUBLIC_NSG
create_nsg $PRIVATE_NSG

# Create NSG rules
create_nsg_rules $PUBLIC_NSG "AllowSSH" "*" "*"
create_nsg_rules $PRIVATE_NSG "AllowSSHFromPublic" "10.0.1.0/24" "*"

# Associate NSGs with subnets
associate_nsg_with_subnet $PUBLIC_SUBNET $PUBLIC_NSG
associate_nsg_with_subnet $PRIVATE_SUBNET $PRIVATE_NSG

# Create the route table and route
create_route_table
create_route

# Create the SSH server VM
create_ssh_server_vm

# Create the specified number of VMs
create_vms

echo "VMs created successfully"
