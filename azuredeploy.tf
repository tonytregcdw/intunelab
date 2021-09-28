#reference existing infrastructure network for ADDS and file share connectivity
data "azurerm_virtual_network" "TT_Infrastructure_RG-vnet" {
  name                 = "TT_Infrastructure_RG-vnet"
  resource_group_name  = "TT_Infrastructure_RG"
}
#Resource Groups
data "azurerm_resource_group" "TT_Infrastructure_RG" {
  name                 = "TT_Infrastructure_RG"
}
#Resource Groups
resource "azurerm_resource_group" "w10endpointrg" {
  name     = var.azure-rg-1
  location = var.loc1
  tags = {
    Environment = var.environment_tag
    Function = "baselabv1-resourcegroups"
  }
}
#Resource Groups
resource "azurerm_resource_group" "w10endpointg2" {
  name     = var.azure-rg-2
  location = var.loc1
  tags = {
    Environment = var.environment_tag
    Function = "baselabv1-resourcegroups"
  }
}
#VNETs and Subnets
#Hub VNET and Subnets
resource "azurerm_virtual_network" "region1-vnet1-hub1" {
  name                = var.region1-vnet1-name
  location            = var.loc1
  resource_group_name = azurerm_resource_group.w10endpointrg.name
  address_space       = [var.region1-vnet1-address-space]
  dns_servers         = ["10.20.1.4", "8.8.8.8"]
   tags     = {
       Environment  = var.environment_tag
       Function = "baselabv1-network"
   }
}
resource "azurerm_subnet" "region1-vnet1-snet1" {
  name                 = var.region1-vnet1-snet1-name
  resource_group_name  = azurerm_resource_group.w10endpointrg.name
  virtual_network_name = azurerm_virtual_network.region1-vnet1-hub1.name
  address_prefixes     = [var.region1-vnet1-snet1-range]
}
#VNET Peering to existing infrastructure
resource "azurerm_virtual_network_peering" "peer1" {
  name                      = "region1-vnet1-to-infra-vnet1"
  resource_group_name       = azurerm_resource_group.w10endpointrg.name
  virtual_network_name      = azurerm_virtual_network.region1-vnet1-hub1.name
  remote_virtual_network_id = "${data.azurerm_virtual_network.TT_Infrastructure_RG-vnet.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
resource "azurerm_virtual_network_peering" "peer2" {
  name                      = "infra-vnet1-to-region1-vnet1"
  resource_group_name       = "${data.azurerm_resource_group.TT_Infrastructure_RG.name}"
  virtual_network_name      = "${data.azurerm_virtual_network.TT_Infrastructure_RG-vnet.name}"
  remote_virtual_network_id = azurerm_virtual_network.region1-vnet1-hub1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

#RDP Access Rules for Lab
#Get Client IP Address for NSG
data "http" "clientip" {
  url = "https://ipv4.icanhazip.com/"
}
#Lab NSG
resource "azurerm_network_security_group" "region1-nsg" {
  name                = "region1-nsg"
  location            = var.loc1
  resource_group_name = azurerm_resource_group.w10endpointrg2.name

  security_rule {
    name                       = "RDP-In"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "${chomp(data.http.clientip.body)}/32"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "WINRM-In"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = "${chomp(data.http.clientip.body)}/32"
    destination_address_prefix = "*"
  }  
   tags     = {
       Environment  = var.environment_tag
       Function = "baselabv1-security"
   }
}
#NSG Association to all Lab Subnets
resource "azurerm_subnet_network_security_group_association" "vnet1-snet1" {
  subnet_id                 = azurerm_subnet.region1-vnet1-snet1.id
  network_security_group_id = azurerm_network_security_group.region1-nsg.id
}
#Create KeyVault ID
resource "random_id" "kvname" {
  byte_length = 5
  prefix = "keyvault"
}
#Keyvault Creation
data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "kv1" {
  depends_on = [ azurerm_resource_group.w10endpointrg2 ]
  name                        = random_id.kvname.hex
  location                    = var.loc1
  resource_group_name         = var.azure-rg-2
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "get",
    ]

    secret_permissions = [
      "get", "backup", "delete", "list", "purge", "recover", "restore", "set",
    ]

    storage_permissions = [
      "get",
    ]
  }
   tags     = {
       Environment  = var.environment_tag
       Function = "baselabv1-security"
   }
}
#Create KeyVault VM password
resource "random_password" "vmpassword" {
  length = 20
  special = true
  override_special = "_%$!+"  
}
#Create Key Vault Secret
resource "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  value        = random_password.vmpassword.result
  key_vault_id = azurerm_key_vault.kv1.id
  depends_on = [ azurerm_key_vault.kv1 ]
}

resource "azurerm_public_ip" "r1-win1001-pip" {
  name                = "r1-win1001-pip"
  resource_group_name = azurerm_resource_group.w10endpointrg.name
  location            = var.loc1
  allocation_method   = "Static"
  sku = "Standard"

   tags     = {
       Environment  = var.environment_tag
       Function = "baselabv1-activedirectory"
   }
}

#Create w10 NIC and associate the Public IP
resource "azurerm_network_interface" "r1-win1001-nic" {
  name                = "r1-win1001-nic"
  location            = var.loc1
  resource_group_name = azurerm_resource_group.w10endpointrg.name

  ip_configuration {
    name                          = "r1-win1001-ipconfig"
    subnet_id                     = azurerm_subnet.region1-vnet1-snet1.id
    private_ip_address_allocation = "Dynamic"
	  public_ip_address_id = azurerm_public_ip.r1-win1001-pip.id
  }
  
   tags     = {
       Environment  = var.environment_tag
       Function = "baselabv1-activedirectory"
   }
}
#Create windows 10 VM
resource "azurerm_windows_virtual_machine" "r1-win1001-vm" {
  name                = "r1-win1001-vm"
  depends_on = [ azurerm_key_vault.kv1 ]
  resource_group_name = azurerm_resource_group.w10endpointrg.name
  location            = var.loc1
  size                = var.vmsize-win10gold
  admin_username      = var.adminusername
  admin_password      = azurerm_key_vault_secret.vmpassword.value
  network_interface_ids = [
    azurerm_network_interface.r1-win1001-nic.id,
  ]

  tags     = {
       Environment  = var.environment_tag
       Function = "baselabv1-activedirectory"
   }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "rs5-enterprise-g2"
    version   = "latest"
  }
}

#Run ansible setup script on r1-win1001-vm
resource "azurerm_virtual_machine_extension" "r1-win1001-basesetup" {
  name                 = "r1-win1001-basesetup"
  virtual_machine_id   = azurerm_windows_virtual_machine.r1-win1001-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "powershell.exe -Command \"./ConfigureRemotingForAnsible.ps1; exit 0;\""
    }
  PROTECTED_SETTINGS

  settings = <<SETTINGS
    {
        "fileUris": [
          "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
        ]
    }
  SETTINGS
}

