# Azure instance creation script

## POC objectives

Validate the possible use of a script to create VM instances on Azure in the context of optimizing cloud resource management and deployment efficiency.

## Infra architecture

- **Logical components**: Azure Virtual Machines, Azure Resource Manager, Azure CLI
- **Ports/protocols**: HTTP/HTTPS for communication with Azure services, SSH for VM access
- **Cloud type**: Public Cloud (Microsoft Azure)

## Scenario

Describe step-by-step the scenario. Write it using this format (BDD style).

### STEP 01
```
//given -> Azure subscription and Azure CLI installed

//when -> the script is executed with specified parameters (e.g., VM size, image, region)

//then -> a new VM instance is created in the specified region with the specified configuration
```

### STEP 2
```
//given -> a newly created VM instance

//when -> the script configures the VM with necessary settings

//then -> the VM is ready for use with all specified configurations
```

### STEP 3 IF STILL TIME LEFT ???
```
//given -> multiple VM instances running

//when -> the script is executed to list and manage running instances

//then -> the script provides detailed information and management options for all running instances

```

## Cost

- **Analysis of load-related costs**: The primary costs will be coming from the number and size of VM instances created.
- **Option to reduce or adapt costs**:
  - Optimize VM sizes and shut down unnecessary instances to reduce costs.
  - Monitor and analyze usage regularly to adjust resources as needed.
  - Take advantage of Azure cost management tools to track and predict expenses.

## Return of experience

- **Take a position on the POC that has been produced**: Example : The POC successfully demonstrated the feasibility and efficiency of using a script to automate the creation and management of VM instances on Azure.
- **Did it validate the announced objectives?**: Example : Yes, the POC validated the objectives by showcasing how automated scripts can consolidate the deployment and management of cloud resources, improving efficiency and resource optimization.
