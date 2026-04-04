terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "kiwitcms" {
  name     = "kiwitcms-resources"
  location = var.location
}

resource "azurerm_virtual_network" "kiwitcms" {
  name                = "kiwitcms-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.kiwitcms.location
  resource_group_name = azurerm_resource_group.kiwitcms.name
}

resource "azurerm_subnet" "kiwitcms" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.kiwitcms.name
  virtual_network_name = azurerm_virtual_network.kiwitcms.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "kiwitcms" {
  name                = "kiwitcms-nic"
  location            = azurerm_resource_group.kiwitcms.location
  resource_group_name = azurerm_resource_group.kiwitcms.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.kiwitcms.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.kiwitcms.id
  }
}

resource "azurerm_public_ip" "kiwitcms" {
  name                = "kiwitcms-public-ip"
  location            = azurerm_resource_group.kiwitcms.location
  resource_group_name = azurerm_resource_group.kiwitcms.name
  allocation_method   = "Dynamic"
}

resource "azurerm_linux_virtual_machine" "kiwitcms" {
  name                = "kiwitcms-machine"
  resource_group_name = azurerm_resource_group.kiwitcms.name
  location            = azurerm_resource_group.kiwitcms.location
  size                = var.size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.kiwitcms.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io docker-compose-plugin
              systemctl start docker
              systemctl enable docker
              mkdir -p /home/adminuser/kiwitcms
              cat <<EOT > /home/adminuser/kiwitcms/docker-compose.yml
              ${file("../../docker-compose.yml")}
              EOT
              cat <<EOT > /home/adminuser/kiwitcms/.env
              KIWI_DB_PASSWORD=${var.db_password}
              KIWI_DB_HOST=db
              KIWI_DB_NAME=kiwitcms
              KIWI_DB_USER=kiwitcms
              EOT
              chown -R adminuser:adminuser /home/adminuser/kiwitcms
              cd /home/adminuser/kiwitcms
              docker compose up -d
              EOF
  )
}

variable "location" {
  default = "East US"
}

variable "size" {
  default = "Standard_B1s"
}

variable "ssh_public_key" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}
