#####################################################################
##
##      Created 7/27/19 by admin.
##
#####################################################################
variable "ansible_server_connection_user" {
  description = "The user to connect to Ansible server."
  type = "string"
}

variable "ansible_server_connection_password" {
  type = "string"
  description = "The password to connect to Ansible server."
}

variable "ansible_server_ip" {
  type = "string"
  description = "The IP or system name of the Ansible server."
}

variable "ansible_working_directory" {
  type = "string"
  description = "The working directory of Ansible."
}

variable "repository_directory" {
  type = "string"
  description = "The directory in repository system to store PTF files. An example is /qopensys/repo"
}

variable "ibmi_repo_user" {
  description = "The user to connect to Ansible server."
  default = "qciuser"
  type = "string"
}

variable "ibmi_repo_password" {
  type = "string"
  description = "The password to connect to Ansible server."
}

variable "ibmi_repo_ip" {
  type = "string"
  description = "The IP or system name of the Ansible server."
}

variable "ansible_bin_path" {
  type = "string"
  description = "The directory of ansible command. For example, /usr/local/bin/. Leave it as blank if ansible command is in PATH."
}

variable "PTFs" {
  type = "list"
  default = []
  description = "PTF packages to be installed. An example is C9123720"
}

variable "IBMi_systems" {
  type = "list"
  default = ["10.10.10.1 ansible_ssh_user=qciuser ansible_ssh_pass=pwd"]
  description = "Target IBMi to install PTFs. An example is '10.10.10.1 ansible_ssh_user=quser ansible_ssh_pass=pwd. If ssh has configured non-password login, ansible_ssh_password can be omitted."
}

variable "NeedIPL" {
  type = "string"
  default = "false" 
  description = "Need IPL target systems after PTF installation or not. Set it to true if the system is to be IPLed."
}