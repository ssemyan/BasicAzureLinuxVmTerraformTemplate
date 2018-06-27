# Basic Azure Linux Vm Terraform Template
This is a basic Terraform Template to create a Linux VM. 

This code is referenced in the blog post [Terraform for the ARM Template Developer](https://blogs.msdn.microsoft.com/cloud_solution_architect/2018/06/27/terraform-for-the-arm-template-developer) that compares how to create and manage Azure resources with [Terraform](https://www.terraform.io/) vs how it is done using ARM templates. This code is a Terraform version of the code from a previous article  [Creating Azure Resources with ARM Templates Step by Step](https://blogs.msdn.microsoft.com/cloud_solution_architect/2016/11/11/creating-azure-resources-with-arm-templates-step-by-step). The code for that article can be found here: https://github.com/ssemyan/BasicAzureLinuxVmArmTemplate  

Before you can use these files, you will need to install Terraform and allow access to your Azure account. This is described here: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure

To use these files to create a Linux VM (Ubuntu 14.04) in a new or existing resource group, update the `template.tf` file with your own values (including the SSH key for the VM) and then use the following commands:

    terraform init
    terraform apply
     
To delete the resources created, use this command:

    terraform destroy