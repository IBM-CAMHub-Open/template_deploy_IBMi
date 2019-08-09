#####################################################################
##
##      Created 3/21/19 by admin. for template_deploy_IBMi
##
#####################################################################

variable "vm_name" {
  description = "The name of the instance to be deployed."
}

variable "fixed_ip_v4" {
  description = "The IP of deployed VM"
}

variable "openstack_image_name" {
  description = "The name of the image to be used for deploy operations."
}

variable "openstack_flavor_name" {
  description = "The name of the flavor to be used for deploy operations."
}

variable "openstack_network_name" {
  description = "The name of the network to be used for deploy operations."
}

variable "key_pair_name" {
  description = "The name of public key"
}

variable "run_cmd" {
  type = "list"
  description = "The commands to be ran on the deployed VM. An example is system 'crtlib testlib'. Seperate multiple commands by comma."
  default = [""]
}