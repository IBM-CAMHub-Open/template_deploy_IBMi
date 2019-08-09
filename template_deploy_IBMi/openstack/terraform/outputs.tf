#####################################################################
##
##      Created 3/21/19 by admin. for template_deploy_IBMi
##
#####################################################################
output "deployed-IBMi-ip" {
  value = "${openstack_compute_instance_v2.IBMi-vm.network.0.fixed_ip_v4}"
}