variable "environment_tag" {
    type = string
    description = "Environment tag value"
}
variable "azure-rg-1" {
    type = string
    description = "resource group 1"
}
variable "azure-rg-2" {
    description = "resource group 2"
    type = string
}
variable "loc1" {
    description = "The location for this Lab environment"
    type= string
}
variable "region1-vnet1-name" {
    description = "VNET1 Name"
    type= string
}
variable "region1-vnet1-address-space" {
  description = "VNET address space"
  type = string
}
variable "region1-vnet1-snet1-name" {
  description = "subnet name"
  type = string
}
variable "region1-vnet1-snet1-range" {
  description = "subnet range"
  type = string
}
variable "region1-vnet1-bastion-range" {
  description = "subnet range"
  type = string
}
variable "vmsize-ws2019gold" {
  description = "size of vm for ws2019gold"
  type = string
}
variable "vmsize-win10gold" {
  description = "size of vm for w10gold"
  type = string
}
variable "adminusername" {
  description = "administrator username for virtual machines"
  type = string
}
variable "wkspace-name" {
  description = "The name of the WVD workspace to be created"
  default = "wvd-wkspace"
}
variable "hppooled-name" {
  description = "The name of the WVD pooled hostpool to be created"
  default = "wvd-pool-hp"
}
variable "appgrp-name" {
  description = "The name of the WVD app group to be created"
  default = "wvd-desktop-ag"
}