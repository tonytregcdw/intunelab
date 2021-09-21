### The Ansible inventory file
resource "local_file" "AnsibleInventory" {
 content = templatefile("azinventory.tmpl",
 {
  azwin1001-pip = azurerm_public_ip.r1-win1001-pip.ip_address
  azwinuser = var.adminusername
  azwinpass = random_password.vmpassword.result
 }
 )
 filename = "inventory.yaml"
}
### Azure resources
resource "local_file" "AzureResources" {
 content = templatefile("group_vars/azresources.tmpl",
 {
  var_azurerg = azurerm_resource_group.wvdrg.name
  var_vmname = azurerm_windows_virtual_machine.r1-win1001-vm.name
  var_vmpip = azurerm_public_ip.r1-win1001-pip.ip_address
 }
 )
 filename = "group_vars/azresources.yaml"
}
