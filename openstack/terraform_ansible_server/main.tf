#####################################################################
##
##      The template is to deploy a new ansible server node. for terraform_ansible_server
##
#####################################################################
provider "openstack" {
  insecure    = true
}

resource "openstack_compute_instance_v2" "ansible_server" {
  name      = "${var.ansible_server_name}"
  image_name  = "${var.openstack_image_name}"
  flavor_name = "${var.openstack_flavor_name}"
  key_pair  = "${openstack_compute_keypair_v2.auth.id}"
     
  network {
  name = "${var.openstack_network_name}"
  fixed_ip_v4 = "${var.fixed_ip_v4}"  # Generated\n\nMust be IP Address
  }
    
  provisioner "local-exec" {
    command = "sleep 120"
  }
}

resource "tls_private_key" "remote_server_key" {
    algorithm = "RSA"
}

resource "openstack_compute_keypair_v2" "auth" {
    name = "${var.openstack_key_pair_name}"
    public_key = "${tls_private_key.remote_server_key.public_key_openssh}"
}

resource "null_resource" "install_ansible"{

  depends_on = ["openstack_compute_instance_v2.ansible_server"]
  
  provisioner "file" {
    destination = "/tmp/installation.sh"
    content     = <<EOT
#!/bin/bash
LOGFILE="/tmp/install_ansible.log"
retryInstall () {
  n=0
  max=5
  command=$1
  while [ $n -lt $max ]; do
    $command && break
    let n=n+1
    if [ $n -eq $max ]; then
      echo "---Exceed maximal number of retries---"
      exit 1
    fi
    sleep 15
  done
}
UNAME=$(uname | tr "[:upper:]" "[:lower:]")
PLATFORM=""
if [ "$UNAME" == "linux" ]; then
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        PLATFORM=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'// | tr "[:upper:]" "[:lower:]" )
    else
        PLATFORM=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1 | tr "[:upper:]" "[:lower:]")
    fi
fi
string="[*] Checking installation of: ansible"
line="......................................................................."
if [[ $PLATFORM == *"ubuntu"* ]]; then
    wait_apt_lock
    sudo apt-get update
    wait_apt_lock
    echo "---start installing Ansible---" | tee -a $LOGFILE 2>&1
    retryInstall "sudo apt-get install -y software-properties-common" >> $LOGFILE 2>&1 || { echo "---Failed to install Ansible---" | tee -a $LOGFILE; exit 1; }
    #retryInstall "sudo apt-add-repository --yes --update ppa:ansible/ansible" >> $LOGFILE 2>&1 || { echo "---Failed to install Ansible---" | tee -a $LOGFILE; exit 1; }
    #retryInstall "sudo apt-get install -y ansible" >> $LOGFILE 2>&1 || { echo "---Failed to install Ansible---" | tee -a $LOGFILE; exit 1; }
    retryInstall "sudo apt-get install -y python-pip python-dev libffi-dev libssl-dev sshpass" >> $LOGFILE 2>&1 || { echo "---Failed to install pip---" | tee -a $LOGFILE; exit 1; }
    retryInstall "sudo pip install ansible==2.7.10" >> $LOGFILE 2>&1 || { echo "---Failed to install Ansible---" | tee -a $LOGFILE; exit 1; }
    echo "---finish installing Ansible---" | tee -a $LOGFILE 2>&1
  else
    echo "---start installing Ansible---" | tee -a $LOGFILE 2>&1
    #retryInstall "yum install -y ansible" >> $LOGFILE 2>&1 || { echo "---Failed to install Ansible---" | tee -a $LOGFILE; exit 1; }
    retryInstall "yum install -y python-pip gcc libffi-devel python-devel openssl-devel" >> $LOGFILE 2>&1 || { echo "---Failed to install pip---" | tee -a $LOGFILE; exit 1; }
    retryInstall "pip install ansible==2.7.10" >> $LOGFILE 2>&1 || { echo "---Failed to install Ansible---" | tee -a $LOGFILE; exit 1; }
    echo "---finish installing Ansible---" | tee -a $LOGFILE 2>&1
  fi
EOT
}

  provisioner "file" {
    destination = "/tmp/add_remote_server_key.sh"
    content     = <<EOT
#!/bin/bash
if (( $# != 3 )); then
echo "usage: arg 1 is user, arg 2 is public key, arg3 is Private Key"
exit -1
fi
userid="$1"
ssh_key="$2"
private_ssh_key="$3"
echo "Userid: $userid"
echo "ssh_key: $ssh_key"
echo "private_ssh_key: $private_ssh_key"
user_home=$(eval echo "~$userid")
#user_auth_key_file=$user_home/.ssh/authorized_keys
user_auth_key_file=$user_home/.ssh/id_rsa.pub
#user_auth_key_file_public=$user_home/.ssh/id_rsa.pub
user_auth_key_file_private=$user_home/.ssh/id_rsa
user_auth_key_file_private_temp=$user_home/.ssh/id_rsa_temp
echo "$user_auth_key_file"
if ! [ -f $user_auth_key_file ]; then
echo "$user_auth_key_file does not exist on this system, creating."
mkdir $user_home/.ssh
chmod 700 $user_home/.ssh
touch $user_home/.ssh/id_rsa.pub
chmod 600 $user_home/.ssh/id_rsa.pub
else
echo "user_home : $user_home"
fi
echo "$user_auth_key_file"
echo "$ssh_key" >> "$user_auth_key_file"
if [ $? -ne 0 ]; then
echo "failed to add to $user_auth_key_file"
exit -1
else
echo "updated $user_auth_key_file"
fi
# echo $private_ssh_key  >> $user_auth_key_file_private_temp
# decrypt=`cat $user_auth_key_file_private_temp | base64 --decode`
# echo "$decrypt" >> "$user_auth_key_file_private"
echo "$private_ssh_key"  >> "$user_auth_key_file_private"
chmod 600 $user_auth_key_file_private
if [ $? -ne 0 ]; then
echo "failed to add to $user_auth_key_file_private"
exit -1
else
echo "updated $user_auth_key_file_private"
fi
rm -rf $user_auth_key_file_private_temp
EOT
}
  
  provisioner "remote-exec" {
     inline = [
     	  "chmod +x /tmp/installation.sh; bash /tmp/installation.sh",
     	   "bash -c 'chmod +x /tmp/add_remote_server_key.sh'",
         "bash -c '/tmp/add_remote_server_key.sh  \"root\" \"${tls_private_key.remote_server_key.public_key_openssh}\" \"${tls_private_key.remote_server_key.private_key_pem}\" >> /tmp/VM_add_ssh_key.log 2>&1'",
      ]
  }
  
  connection {
    type = "ssh"
    user = "${var.ansible_server_connection_user}"
    password = "${var.ansible_server_connection_password}"
    host = "${var.fixed_ip_v4}"
  }
}

resource "null_resource" "put_ansible_playbooks" {
  depends_on = ["null_resource.install_ansible"]
  
  connection {
    type = "ssh"
    user = "${var.ansible_server_connection_user}"
    password = "${var.ansible_server_connection_password}"
    host = "${var.fixed_ip_v4}"
  }

  provisioner "remote-exec" {
    inline = [
     	  "mkdir -p ${var.ansible_home_directory}/template"]
  }
  
    # Produce a YAML file to override defaults.
  provisioner "file" {
    content = <<EOF
---
# save obj to savf and fetch it back to root.
- hosts: repo
  vars:
    targets:
      lpp:
        product:
        option:
    path: '/Users/nothing/Desktop/ansible/'
  tasks:
  - include_tasks: template/CreateTempLib.yaml
  - include_tasks: template/CreateSavf.yaml  
  - include_tasks: template/SaveLppToSavf.yaml
  - include_tasks: template/FetchSavfToRoot.yaml
  - include_tasks: template/ClearTemp.yaml
EOF

    destination = "${var.ansible_home_directory}/SaveLppDemo.yaml"
  } 
  
  # Produce a YAML file to override defaults.
  provisioner "file" {
    content = <<EOF
---
# restore licpgm to target lpar
- hosts: ibmi
  vars:
    targets:
      lpp:
        product: 
        option: 
    path: '/Users/nothing/Desktop/ansible/'
  tasks:
  - include_tasks: template/CreateTempLib.yaml
  - include_tasks: template/CopySavfToTarget.yaml  
  - include_tasks: template/RstLppOnTarget.yaml
  - include_tasks: template/ClearTemp.yaml
EOF

    destination = "${var.ansible_home_directory}/RstLppDemo.yaml"
  } 
  
  provisioner "file" {
    content = <<EOF
# Create temp lib "ansible" on target lpar.
- name: create temp lib ansilble
  command: system "CRTLIB ANSIBLE"
  register: crt_result
  ignore_errors: True
  
- name: create temp dir ansilble
  file: path=/home/ansible state=directory
  
- name: delete exsiting lib "ansible" on target lpar
  command: system "DLTLIB ANSIBLE"
  when: "'CPF2111' in crt_result.stderr"
  
- name: re-create temp lib "ansible" on target lpar
  command: system "CRTLIB ANSIBLE"
  when: crt_result.stderr
EOF

    destination = "${var.ansible_home_directory}/template/CreateTempLib.yaml"
  } 
  
  provisioner "file" {
    content = <<EOF
# Create savf in ansible
- name: create savf in ansible lib
  command: system "CRTSAVF FILE(ANSIBLE/{{ item.key }})"
  with_dict: "{{targets}}"
EOF

    destination = "${var.ansible_home_directory}/template/CreateSavf.yaml"
  } 
  
  provisioner "file" {
    content = <<EOF
# Save licpgms to savf
- name: save licpgm to savf
  command: system "SAVLICPGM LICPGM({{ item.value.product }}) DEV(*SAVF) OPTION({{ item.value.option }}) SAVF(ANSIBLE/{{ item.key }})"
  with_dict: "{{targets}}"
EOF

    destination = "${var.ansible_home_directory}/template/SaveLppToSavf.yaml"
  } 
  
  provisioner "file" {
    content = <<EOF
---
# Fetch the savfs back to root 
- name: fetch savfs back to root
  fetch:
    src: "/QSYS.LIB/ANSIBLE.LIB/{{ item.key }}.FILE"
    dest: "{{ path }}/{{ item.key }}.FILE"
    flat: yes
  with_dict: "{{targets}}"
EOF

    destination = "${var.ansible_home_directory}/template/FetchSavfToRoot.yaml"
  }
  
  provisioner "file" {
    content = <<EOF
---
# Clear temp file and lib
- name: delete ansible lib
  command: system "DLTLIB ANSIBLE"
  ignore_errors: True
  
- name: delete ansible dir
  file: path=/home/ansible state=absent
  ignore_errors: True
EOF

    destination = "${var.ansible_home_directory}/template/ClearTemp.yaml"
  }
  
  provisioner "file" {
    content = <<EOF
---
# Copy the savfs to targets 
- name: Copy the savfs to targets 
  copy: src='{{ path }}/{{ item.key }}.FILE' dest=/home/ansible/
  with_dict: "{{targets}}"
- name: mv savf to lib
  command: 'mv /home/ansible/{{ item.key }}.FILE /QSYS.LIB/ANSIBLE.LIB/'
  with_dict: "{{targets}}"
EOF

    destination = "${var.ansible_home_directory}/template/CopySavfToTarget.yaml"
  }
  
  provisioner "file" {
    content = <<EOF
---
# Copy the savfs to targets 
- name: restore licpgm
  command: system "RSTLICPGM LICPGM({{ item.value.product }}) DEV(*SAVF) OPTION({{ item.value.option }}) SAVF(ANSIBLE/{{ item.key }})"
  with_dict: "{{targets}}"
EOF

    destination = "${var.ansible_home_directory}/template/RstLppOnTarget.yaml"
  }
}

resource "null_resource" "install_ansible_finished" {
  depends_on = ["null_resource.put_ansible_playbooks"]

  provisioner "local-exec" {
    command = "echo 'Ansible Binaries installed and playbooks template uploaded'"
  }
}