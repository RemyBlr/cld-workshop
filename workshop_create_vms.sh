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

# Check if virtual network exists

# Check if NSGs exist

   # Create NSGs if they don't exist

# Check if NSG rules exist (public subnet)

   # Create NSG rules if they don't exist

# Check if NSG rules exist (private subnet)

   # Create NSG rules if they don't exist

# Associate NSGs with subnets

# Check if route table exists

   # Create route table if it doesn't exist

# Associate route table with subnets

################## Create VMs ##################

# Loop to create VMs

   # Check if VM exists

        # Create public IP adr for SSH server

        # Create network interface

        # Create VM
