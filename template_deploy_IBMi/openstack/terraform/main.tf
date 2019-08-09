################################################################
# Template to deploy Single IBM i VM
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# Copyright IBM Corp. 2017.
#
################################################################

provider "openstack" {
  insecure = true
  version  = "~> 0.3"
}

locals {
  userdata = <<USERDATA
#!/bin/sh
${lower(join(" && ", var.run_cmd))}
USERDATA
}

resource "openstack_compute_instance_v2" "IBMi-vm" {
  name      = "${var.vm_name}"
  image_name  = "${var.openstack_image_name}"
  flavor_name = "${var.openstack_flavor_name}"
  key_pair  = "${var.key_pair_name}"
  user_data = "${base64encode(local.userdata)}"
  
  network {
    name = "${var.openstack_network_name}"
    fixed_ip_v4 = "${var.fixed_ip_v4}"  # Generated\n\nMust be IP Address
  } 
  
  provisioner "local-exec" {
    command = "sleep 600"
  }
}

