
# Azure Bastion - Region 1
resource "azurerm_subnet" "region1-vnet1-snet-bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.w10endpointrg.name
  virtual_network_name = azurerm_virtual_network.region1-vnet1-hub1.name
  address_prefixes     = [var.region1-vnet1-bastion-range]
}

resource "azurerm_public_ip" "region1-bastion-01-pip" {
  name                = "pip-AzureBastion-lab"
  location            = var.loc1
  resource_group_name = azurerm_resource_group.w10endpointrg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    Terraform              = "Yes"
  }
}
resource "azurerm_bastion_host" "region1-bastion-01" {
  name                = "host-bastion-lab"
  location            = var.loc1
  resource_group_name = azurerm_resource_group.w10endpointrg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.region1-vnet1-snet-bastion.id
    public_ip_address_id = azurerm_public_ip.region1-bastion-01-pip.id
  }
  tags = {
    Terraform              = "Yes"
  }
}
