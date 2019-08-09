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
          "mkdir -p ${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}"]
  }
  
    provisioner "local-exec" {
    command = "echo 'Log file is on Ansible Server ${var.ansible_working_directory}/ansible_${random_id.ansible_task_unique.hex}.log'"
}

    # Produce a YAML file to override defaults.
  provisioner "file" {
    content = <<EOF
# Fetch.
- hosts: ibmi
  vars:
    temp_dir: "/home/Ansible/${random_id.ansible_task_unique.hex}"
    ptf: ""

  tasks:
  - name: create tempoaray directory if it doesn't exist
    file:  path="{{temp_dir}}/media" state=directory
    ignore_errors: True

  - name: copy media to target IFS directory
    synchronize:
      src: "${var.repository_directory}/{{ ptf }}"
      dest: "{{ temp_dir }}/"
      compress: yes
      checksum: yes
    delegate_to: ${var.ibmi_repo_ip}
    ignore_errors: True
  - name: find all media files in the target directory
    find: paths="{{temp_dir }}/{{ptf}}" recurse=no patterns='*.bin,*.BIN,*.iso,*.ISO'
    register: media_file_to_copy
    ignore_errors: True
  - name: copy bin files from ptf directory to media directory
    command: cp {{item.path}} {{temp_dir }}/media
    with_items: "{{ media_file_to_copy.files }}"
    ignore_errors: True

EOF
    destination = "${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/CopyMediaToTarget.yaml"
  }

    # Produce a YAML file to override defaults.
  provisioner "file" {
    content = <<EOF
# Fetch.
- hosts: ibmi
  vars:
    temp_dir_target: "home/Ansible/${random_id.ansible_task_unique.hex}/media"

  tasks:

  - name: create virtual device description
    command: system "CRTDEVOPT DEVD(OPTVRT01) RSRCNAME(*VRT) ONLINE(*YES)"
    register: fetch_result

  - name: create image catelog
    command: system "CRTIMGCLG IMGCLG(ptfcatalog) DIR('{{temp_dir_target}}') ADDVRTVOL(*DIR)"
    ignore_errors: True

  - name: vary on virtual device description
    command: system "QSYS/VRYCFG CFGOBJ(OPTVRT01) CFGTYPE(*DEV) STATUS(*ON)"
    ignore_errors: True

  - name: load image into image catelog
    command: system "LODIMGCLG IMGCLG(ptfcatalog) DEV(OPTVRT01) OPTION(*LOAD)"
    ignore_errors: True

  - name: verify image catelog in order
    command: system "VFYIMGCLG IMGCLG(ptfcatalog) TYPE(*PTF) SORT(*YES)"
    ignore_errors: True

  - name: install ptf
    command: system "INSPTF LICPGM((*ALL)) DEV(OPTVRT01) INSTYP(*IMMDLY)"
    ignore_errors: True

  - name: unload image catelog
    command: system "LODIMGCLG IMGCLG(ptfcatalog)  OPTION(*UNLOAD)"
    ignore_errors: True

  - name: vary off virtual device description
    command: system "QSYS/VRYCFG CFGOBJ(OPTVRT01) CFGTYPE(*DEV) STATUS(*OFF)"
    ignore_errors: True

  - name: delete image catelog
    command: system "DLTIMGCLG IMGCLG(PTFCATALOG) KEEP(*NO)"
    ignore_errors: True

  - name: delete virtual device description
    command: system "DLTDEVD DEVD(OPTVRT01)"
    ignore_errors: True

  - name: IPL the system
    command: system "PWRDWNSYS OPTION(*CNTRLD) RESTART(*YES)"
    when: ("${var.NeedIPL}" == "true")
EOF
    destination = "${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/InstallPTFFromMedia.yaml"
  }

  provisioner "local-exec" {
    command = "echo 'Ansible playbook uploaded to ansible server'"
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

  provisioner "remote-exec" {
    inline = [
          "mkdir -p ${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/inventory"]
  }

    # Produce a YAML file to override defaults.
  provisioner "file" {
    content = <<EOF
[repo]
${var.ibmi_repo_ip} ansible_ssh_user=${var.ibmi_repo_user} ansible_ssh_pass=${var.ibmi_repo_password}

[ibmi]
${var.IBMi_systems[count.index]}
EOF

    destination = "${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/inventory/${count.index}"
}
}


resource "null_resource" "copy_media_to_target_system"{
  depends_on = ["null_resource.put_ibmi_inventory"]

  count = "${length(var.PTFs)}"

  connection {
    type = "ssh"
    user = "${var.ansible_server_connection_user}"
    password = "${var.ansible_server_connection_password}"
    host = "${var.ansible_server_ip}"
  }

  provisioner "remote-exec" {
    inline = [
          "${var.ansible_bin_path}ansible-playbook -i \"${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/inventory\" \"${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/CopyMediaToTarget.yaml\" --extra-vars ptf=\"${var.PTFs[count.index]}\" >> \"${var.ansible_working_directory}/ansible_${random_id.ansible_task_unique.hex}.log\""]
  }

 provisioner "local-exec" {
    command = "echo 'Copy installation media files'"
}

}

resource "null_resource" "install_ptf_on_target_system"{
  depends_on = ["null_resource.copy_media_to_target_system"]

  connection {
    type = "ssh"
    user = "${var.ansible_server_connection_user}"
    password = "${var.ansible_server_connection_password}"
    host = "${var.ansible_server_ip}"
  }

  provisioner "remote-exec" {
    inline = [
          "${var.ansible_bin_path}ansible-playbook -i \"${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/inventory\" \"${var.ansible_working_directory}/${random_id.ansible_task_unique.hex}/InstallPTFFromMedia.yaml\" >> \"${var.ansible_working_directory}/ansible_${random_id.ansible_task_unique.hex}.log\""]
  }

 provisioner "local-exec" {
    command = "echo 'Applied PTFs'"
}

}

resource "null_resource" "remove_media_file_from_ansible"{
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
