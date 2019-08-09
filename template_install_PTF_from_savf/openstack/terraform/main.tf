#####################################################################
##
##      Created 7/26/19 by admin.
##
#####################################################################

terraform {
  required_version = "> 0.8.0"
}

resource "random_id" "ansible_task_unique" {
  byte_length = 8
}

resource "null_resource" "put_playbook"{

  connection {
    type = "ssh"
    user = "${var.ansible_server_connection_user}"
    password = "${var.ansible_server_connection_password}"
    host = "${var.ansible_server_ip}"
  }

  provisioner "remote-exec" {
    inline = [
          "mkdir -p ${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/inventory"]
  }
  
  provisioner "local-exec" {
    command = "echo 'Log file is on Ansible Server ${var.ansible_working_directory}/ansible_${random_id.ansible_task_unique.hex}.log'"
}

  provisioner "file" {
    content = <<EOF
# Fetch.
- hosts: all
  vars:
    source_lib: "${var.repository_library}"
    temp_dir_local: "${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}"
    ptf: ""
    ptf_name: "Q{{ ptf.split('-')[1]}}"
  tasks:
  - name: fetch savfs back to root
    fetch:
      src: "/{{ source_lib }}/{{ ptf_name }}.FILE"
      dest: "{{ temp_dir_local }}/{{ ptf_name }}.FILE"
      flat: yes
    register: fetch_savf_result
    ignore_errors: True
EOF
    destination = "${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/FetchSavfToLocal.yaml"
  }

    # Produce a YAML file to override defaults.
  provisioner "file" {
    content = <<EOF
# Fetch.
- hosts: all
  vars:
    temp_dir_local: "${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}"
    ptf: ""
    product: "{{ptf.split('-')[0]}}"
    ptf_name: "{{ ptf.split('-')[1]}}"
    savf_name: "Q{{ ptf_name }}"
  tasks:
  - name: create tempoaray directory if it doesn't exist
    file:  path="/home/Ansible" state=directory
    ignore_errors: True
  - name: create temporary library if it doesn't exist
    command: system "crtlib ansible"
    ignore_errors: True
  - name: check product installed or not, if not installed, skip it.
    command: system "APYPTF LICPGM({{product}}) SELECT(SI11111)"
    register: check_prodct_result
    ignore_errors: True
  - name: copy SAVF to target IFS directory
    copy: src='{{ temp_dir_local }}/{{ savf_name }}.FILE' dest=/tmp/
    ignore_errors: True
    when: "'CPF3606' not in check_prodct_result.stderr"
  - name: move SAVF from IFS to library
    command: 'mv /tmp/{{ savf_name}}.FILE /QSYS.LIB/ANSIBLE.LIB/'
    ignore_errors: True
    when: "'CPF3606' not in check_prodct_result.stderr"
  - name: load ptf
    command: system "LODPTF LICPGM({{product}}) DEV(*SAVF) SELECT({{ptf_name}}) SPRPTF(*APYPERM) SAVF(ANSIBLE/{{savf_name}})"
    register: load_result
    ignore_errors: True
    when: "'CPF3606' not in check_prodct_result.stderr"
EOF
    destination = "${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/LodPTF.yaml"
  }

      # Produce a YAML file to override defaults.
  provisioner "file" {
    content = <<EOF
- hosts: all
  tasks:
  - name: Install PTF
    command: system 'INSPTF LICPGM((*ALL ))  DEV(*NONE) INSTYP(*IMMDLY)'
    ignore_errors: True
  - name: IPL the system
    command: system "PWRDWNSYS OPTION(*CNTRLD) RESTART(*YES)"
    when: ("${var.NeedIPL}" == "true")
EOF
    destination = "${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/INSPTF.yaml"
  }

  provisioner "local-exec" {
    command = "echo 'Ansible playbook uploaded to ansible server'"
}
}

resource "null_resource" "put_repository_inventory"{

  depends_on = ["null_resource.put_playbook"]

    connection {
    type = "ssh"
    user = "${var.ansible_server_connection_user}"
    password = "${var.ansible_server_connection_password}"
    host = "${var.ansible_server_ip}"
  }

    # Produce a YAML file to override defaults.
  provisioner "file" {
    content = <<EOF
  ${var.ibmi_repo_ip} ansible_ssh_user=${var.ibmi_repo_user} ansible_ssh_pass=${var.ibmi_repo_password}
EOF
  destination = "${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/repo_inventory"
  }

 provisioner "local-exec" {
    command = "echo 'Ansible repository inventory uploaded'"
}
}

resource "null_resource" "put_ibmi_inventory"{

  depends_on = ["null_resource.put_playbook"]

  count = "${length(var.IBMi_systems)}"

    connection {
    type = "ssh"
    user = "${var.ansible_server_connection_user}"
    password = "${var.ansible_server_connection_password}"
    host = "${var.ansible_server_ip}"
  }

    # Produce a YAML file to override defaults.
  provisioner "file" {
    content = <<EOF
${var.IBMi_systems[count.index]}
EOF
    destination = "${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/inventory/${count.index}"
  }
}

resource "null_resource" "fetch_savf_file_from_repository"{

  depends_on = ["null_resource.put_repository_inventory"]

  count = "${length(var.PTFs)}"

  connection {
    type = "ssh"
    user = "${var.ansible_server_connection_user}"
    password = "${var.ansible_server_connection_password}"
    host = "${var.ansible_server_ip}"
  }

  provisioner "remote-exec" {
    inline = [
          "${var.ansible_bin_path}ansible-playbook -i \"${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/repo_inventory\" \"${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/FetchSavfToLocal.yaml\" --extra-vars ptf=\"${var.PTFs[count.index]}\" >> \"${var.ansible_working_directory}/ansible_${random_id.ansible_task_unique.hex}.log\""]
  }

    provisioner "remote-exec" {
    inline = [
          "rm -rf ${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/repo_inventory"]
  }

}

resource "null_resource" "load_ptf_on_target_system"{
  depends_on = ["null_resource.fetch_savf_file_from_repository"]
  depends_on = ["null_resource.put_ibmi_inventory"]

  count = "${length(var.PTFs)}"

  connection {
    type = "ssh"
    user = "${var.ansible_server_connection_user}"
    password = "${var.ansible_server_connection_password}"
    host = "${var.ansible_server_ip}"
  }

 provisioner "local-exec" {
    command = "echo 'Loading PTF'"
}

  provisioner "remote-exec" {
    inline = [
          "${var.ansible_bin_path}ansible-playbook -i \"${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/inventory\" \"${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/LodPTF.yaml\" --extra-vars ptf=\"${var.PTFs[count.index]}\" >> \"${var.ansible_working_directory}/ansible_${random_id.ansible_task_unique.hex}.log\""]
  }
  }

resource "null_resource" "install_ptf_on_target_system"{
  depends_on = ["null_resource.load_ptf_on_target_system"]

  connection {
    type = "ssh"
    user = "${var.ansible_server_connection_user}"
    password = "${var.ansible_server_connection_password}"
    host = "${var.ansible_server_ip}"
  }

  provisioner "remote-exec" {
    inline = [
          "${var.ansible_bin_path}ansible-playbook -i \"${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/inventory\" \"${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/INSPTF.yaml\" >> \"${var.ansible_working_directory}/ansible_${random_id.ansible_task_unique.hex}.log\""]
  }

 provisioner "local-exec" {
    command = "echo 'Applied PTFs'"
}

}

resource "null_resource" "remove_savf_file_from_ansible"{
  depends_on = ["null_resource.install_ptf_on_target_system"]
  connection {
    type = "ssh"
    user = "${var.ansible_server_connection_user}"
    password = "${var.ansible_server_connection_password}"
    host = "${var.ansible_server_ip}"
  }

  provisioner "remote-exec" {
    inline = [
          "rm -rf ${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}"]
  }

 provisioner "local-exec" {
    command = "echo 'Ansible temporary working directory deleted.'"
}

}

