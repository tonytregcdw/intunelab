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
