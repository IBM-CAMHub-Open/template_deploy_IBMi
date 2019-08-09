#####################################################################
##
##      The template is to deploy a new ansible server node. for terraform_ansible_server
##
#####################################################################

variable "ansible_server_name" {
  type = "string"
  description = "Generated"
}

variable "openstack_image_name" {
  type = "string"
  description = "Generated"
}

variable "openstack_flavor_name" {
  type = "string"
  description = "Generated"
}

variable "openstack_key_name" {
  type = "string"
  description = "Give a name to the key to be added as openstack public key"
}

variable "ansible_server_connection_user" {
  type = "string"
}

variable "ansible_server_connection_password" {
  type = "string"
}

variable "ansible_home_directory" {
  type = "string"
}

variable "openstack_network_name" {
  type = "string"
  description = "Generated"
}

variable "fixed_ip_v4" {
  type = "string"
  description = "Generated. Must be IP Address"
}

