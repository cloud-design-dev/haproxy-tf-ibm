resource "null_resource" "update_web_nodes" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.cwd}/inventory.env ~/Sync/Coding/Ansible/Playbooks/update.yml --limit=web"
  }
}

resource "null_resource" "add_web1_portable_ip" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.cwd}/inventory.env ${path.cwd}/Playbooks/web1_ip.yml --limit=web1"
  }
}

resource "null_resource" "add_web2_portable_ip" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.cwd}/inventory.env ${path.cwd}/Playbooks/web2_ip.yml --limit=web2"
  }
}

resource "null_resource" "add_web3_portable_ip" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.cwd}/inventory.env ${path.cwd}/Playbooks/web3_ip.yml --limit=web3"
  }
}

resource "null_resource" "configure_lb1" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.cwd}/inventory.env ${path.cwd}/Playbooks/nginx_lb1.yml --limit=nginx-lb1"
  }
}

resource "null_resource" "configure_lb2" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.cwd}/inventory.env ${path.cwd}/Playbooks/nginx_lb2.yml --limit=nginx-lb2"
  }
}
