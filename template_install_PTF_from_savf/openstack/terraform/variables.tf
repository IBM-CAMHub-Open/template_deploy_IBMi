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
  description = "The working directory of Ansible. A new one is to be created if it doesn't exist."
}

variable "repository_library" {
  type = "string"
  description = "The directory of repository system to store SAVF files. An example is /QSYS.LIB/ANSIBLE.LIB or /tmp. Ensure the PTF installation file is named QSI*****.FILE"
}

variable "ibmi_repo_user" {
  description = "The user to connect to Ansible server."
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
  description = "The directory of ansible command. For example, /usr/local/bin/. Leave it as blank if ansible command is in PATH"
}

variable "PTFs" {
  type = "list"
  description = "PTF to be installed. An example is 5770SS1-SI11111"
}

variable "IBMi_systems" {
  type = "list"
  description = "Target IBMi to install PTFs. An example is '10.10.10.1 ansible_ssh_user=quser ansible_ssh_pass=pwd. If ssh has configured non-password signon from ansible server, ansible_ssh_password is optional."
  default = ["10.10.10.1 ansible_ssh_user=quser ansible_ssh_pass=pwd"]
}

variable "NeedIPL" {
  type = "string"
  default = "false" 
  description = "Need IPL target systems after PTF installation or not. Set it to true if the system is to be IPLed."
}