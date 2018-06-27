/*
# Fill in your values below if you want to use a service principal to run the Terraform
# Otherwise, you can log in via the Azure CLI - e.g.: az login
provider "azurerm" {
  subscription_id = "REPLACE-WITH-YOUR-SUBSCRIPTION-ID"
  client_id       = "REPLACE-WITH-YOUR-CLIENT-ID"
  client_secret   = "REPLACE-WITH-YOUR-CLIENT-SECRET"
  tenant_id       = "REPLACE-WITH-YOUR-TENANT-ID"
}
*/

# Variables are often kept in their own file - variables.tf - but for this example I will keep them in one file to match how ARM templates usually work
variable "resource_group_name" {
  description = "The name of the resource group in which to create the resources."
}

variable "resource_group_location" {
  description = "The location to create the resource group and resources."
}

variable "virtualMachineName" {
  description = "The name of the VM."
}

variable "virtualMachineSize" {
  description = "VM Size to use."
}

variable "adminUsername" {
  description = "User name to use for the admin account"
}

variable "adminPublicKey" {
  description = "ssh-rsa public key value for the admin account"
}

# These values are not expected to change much so they are included in the main tf file
locals {
  virtualNetworkName       = "${var.resource_group_name}-vnet"
  networkInterfaceName     = "${var.virtualMachineName}-nic"
  networkSecurityGroupName = "${var.resource_group_name}-nsg"
  publicIpAddressName      = "${var.resource_group_name}-${var.virtualMachineName}-ip"
  addressPrefix            = "10.0.0.0/16"
  subnetName               = "default"
  subnetPrefix             = "10.0.1.0/24"
}

# Create the resources
resource "azurerm_resource_group" "basicvm" {
  name     = "${var.resource_group_name}"
  location = "${var.resource_group_location}"
}

resource "azurerm_virtual_network" "basicvm" {
  name                = "${local.virtualNetworkName}"
  address_space       = ["${local.addressPrefix}"]
  location            = "${var.resource_group_location}"
  resource_group_name = "${azurerm_resource_group.basicvm.name}"
}

resource "azurerm_subnet" "basicvm" {
  name                      = "${local.subnetName}"
  resource_group_name       = "${azurerm_resource_group.basicvm.name}"
  virtual_network_name      = "${azurerm_virtual_network.basicvm.name}"
  network_security_group_id = "${azurerm_network_security_group.basicvm.id}"
  address_prefix            = "${local.subnetPrefix}"
}

resource "azurerm_network_security_group" "basicvm" {
  name                = "${local.networkSecurityGroupName}"
  location            = "${var.resource_group_location}"
  resource_group_name = "${azurerm_resource_group.basicvm.name}"

  security_rule {
    name                       = "default-allow-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "22"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "basicvm" {
  name                = "${local.networkInterfaceName}"
  location            = "${var.resource_group_location}"
  resource_group_name = "${azurerm_resource_group.basicvm.name}"

  ip_configuration {
    name                          = "ipConfig"
    subnet_id                     = "${azurerm_subnet.basicvm.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.basicvm.id}"
  }
}

resource "azurerm_public_ip" "basicvm" {
  name                         = "${local.publicIpAddressName}"
  location                     = "${var.resource_group_location}"
  resource_group_name          = "${azurerm_resource_group.basicvm.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_virtual_machine" "basicvm" {
  name                  = "${var.virtualMachineName}"
  location              = "${var.resource_group_location}"
  resource_group_name   = "${azurerm_resource_group.basicvm.name}"
  network_interface_ids = ["${azurerm_network_interface.basicvm.id}"]
  vm_size               = "${var.virtualMachineSize}"

  # Comment this next line to leave the OS disk when deleting the VM
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "14.04.5-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.virtualMachineName}-osDisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.virtualMachineName}"
    admin_username = "${var.adminUsername}"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.adminUsername}/.ssh/authorized_keys"
      key_data = "${var.adminPublicKey}"
    }
  }
}

# Look up the Public IP address because it is only allocated after assigned to a VM
data "azurerm_public_ip" "basicvm" {
  name                = "${azurerm_public_ip.basicvm.name}"
  resource_group_name = "${azurerm_resource_group.basicvm.name}"
}

# Output the public IP address
output "public_ip_address" {
  value = "${data.azurerm_public_ip.basicvm.ip_address}"
}

# Output the command to use to ssh into the new VM
output "ssh_command" {
  value = "ssh ${var.adminUsername}@${data.azurerm_public_ip.basicvm.ip_address}"
}
