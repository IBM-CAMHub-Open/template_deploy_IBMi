#####################################################################
##
##      Created 7/31/19 by admin.
##
#####################################################################
output "Ansible playbook log" {
  value = "${var.ansible_working_directory}/ansible_${random_id.ansible_task_unique.hex}.log"
}
