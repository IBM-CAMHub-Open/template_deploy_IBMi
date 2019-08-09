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

variable "openstack_key_pair_name" {
  type = "string"
  description = "Generated"
}

variable "ansible_server_connection_user" {
  type = "string"
  default = "root"
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
  default = "net50"
}

variable "fixed_ip_v4" {
  type = "string"
  description = "Generated. Must be IP Address"
}

