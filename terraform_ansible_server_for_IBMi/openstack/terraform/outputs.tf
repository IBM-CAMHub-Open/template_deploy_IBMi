#####################################################################
##
##      The template is to deploy a new ansible server node. for terraform_ansible_server
##
#####################################################################

output "Ansible Public SSH Key for other machines" {
  value = "${tls_private_key.remote_server_key.public_key_openssh}"
}

output "Ansible server ip for client connection" {
  value = "${var.fixed_ip_v4}"
}

output "Ansible playbook directory" {
  value = "${var.ansible_home_directory}"
}
