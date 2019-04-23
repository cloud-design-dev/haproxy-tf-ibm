data "ibm_compute_ssh_key" "deploymentKey" {
  label = "ryan_tycho"
}

resource "ibm_network_vlan" "haproxy_public" {
  name       = "haproxy_public"
  datacenter = "${var.datacenter["us-south3"]}"
  type       = "PUBLIC"
}

resource "ibm_network_vlan" "haproxy_private" {
  name       = "haproxy_private"
  datacenter = "${var.datacenter["us-south3"]}"
  type       = "PRIVATE"
}

resource "ibm_subnet" "floating_ip_subnet" {
  type       = "Portable"
  private    = false
  ip_version = 4
  capacity   = 4
  vlan_id    = "${ibm_network_vlan.haproxy_public.id}"
  notes      = "HAProxy VLANs"
}

resource "ibm_subnet" "apache_ip_subnet" {
  type       = "Portable"
  private    = true
  ip_version = 4
  capacity   = 8
  vlan_id    = "${ibm_network_vlan.haproxy_private.id}"
}

resource "ibm_compute_vm_instance" "haproxy_nodes" {
  count                = "${var.node_count["haproxy"]}"
  hostname             = "haproxy${count.index+1}"
  domain               = "${var.domainname}"
  user_metadata        = "${file("install.yml")}"
  os_reference_code    = "${var.os["u16"]}"
  datacenter           = "${var.datacenter["us-south3"]}"
  network_speed        = 1000
  hourly_billing       = true
  private_network_only = false
  flavor_key_name      = "${var.vm_flavor["medium"]}"
  disks                = [200]
  local_disk           = false
  public_vlan_id       = "${ibm_network_vlan.haproxy_public.id}"
  private_vlan_id      = "${ibm_network_vlan.haproxy_private.id}"
  ssh_key_ids          = ["${data.ibm_compute_ssh_key.deploymentKey.id}"]

  tags = [
    "ryantiffany",
  ]
}

resource "ibm_compute_vm_instance" "web_nodes" {
  depends_on           = ["ibm_compute_vm_instance.haproxy_nodes"]
  count                = "${var.node_count["web"]}"
  hostname             = "web${count.index+1}"
  domain               = "${var.domainname}"
  user_metadata        = "${file("install.yml")}"
  os_reference_code    = "${var.os["u16"]}"
  datacenter           = "${var.datacenter["us-south3"]}"
  network_speed        = 1000
  hourly_billing       = true
  private_network_only = true
  flavor_key_name      = "${var.vm_flavor["medium"]}"
  disks                = [200]
  local_disk           = false
  private_vlan_id      = "${ibm_network_vlan.haproxy_private.id}"
  ssh_key_ids          = ["${data.ibm_compute_ssh_key.deploymentKey.id}"]

  tags = [
    "ryantiffany",
  ]
}

resource "dnsimple_record" "floating_ip_record" {
  domain = "${var.domainname}"
  name   = "float"
  value  = "${cidrhost(ibm_subnet.floating_ip_subnet.subnet_cidr,2)}"
  type   = "A"
  ttl    = 900
}

resource "dnsimple_record" "web_node_records" {
  count  = "${var.node_count["web"]}"
  domain = "${var.domainname}"
  name   = "web${count.index+1}.ans"
  value  = "${element(ibm_compute_vm_instance.web_nodes.*.ipv4_address_private,count.index)}"
  type   = "A"
  ttl    = 900
}

resource "dnsimple_record" "haproxy_node_records" {
  count  = "${var.node_count["haproxy"]}"
  domain = "${var.domainname}"
  name   = "nginx-lb${count.index+1}"
  value  = "${element(ibm_compute_vm_instance.haproxy_nodes.*.ipv4_address,count.index)}"
  type   = "A"
  ttl    = 900
}

resource "local_file" "ansible_hosts" {
  depends_on = ["ibm_compute_vm_instance.web_nodes"]

  content = <<EOF
[web]
web1 ansible_host=web1.ans.${var.domainname} ansible_user=ryan
web2 ansible_host=web2.ans.${var.domainname} ansible_user=ryan
web3 ansible_host=web3.ans.${var.domainname} ansible_user=ryan

[web:vars]
host_key_checking = False
ssh_args = -F  /Users/ryan/Sync/Coding/Ansible/ssh.cfg -o ControlMaster=auto -o ControlPersist=30m
control_path = ~/.ssh/ansible-%%r@%%h:%%p

[haproxy]
haproxy1 ansible_host=nginx-lb1.${var.domainname} ansible_user=ryan
haproxy2 ansible_host=nginx-lb2.${var.domainname} ansible_user=ryan

[local]
control ansible_connection=local
EOF

  filename = "${path.cwd}/Ansible/inventory.env"
}

data "template_file" "web1_template" {
  depends_on = ["local_file.ansible_hosts"]
  template   = "${file("${path.cwd}/TemplateFiles/web.tpl")}"

  vars = {
    web_ip_gateway = "${cidrhost(ibm_subnet.apache_ip_subnet.subnet_cidr,1)}"
    web_ip         = "${cidrhost(ibm_subnet.apache_ip_subnet.subnet_cidr,2)}"
  }
}

resource "local_file" "web1_template" {
  content = <<EOF
${data.template_file.web1_template.rendered}
EOF

  filename = "${path.cwd}/Ansible/Playbooks/web1_ip.yml"
}

data "template_file" "web2_template" {
  depends_on = ["local_file.ansible_hosts"]
  template   = "${file("${path.cwd}/TemplateFiles/web.tpl")}"

  vars = {
    web_ip_gateway = "${cidrhost(ibm_subnet.apache_ip_subnet.subnet_cidr,1)}"
    web_ip         = "${cidrhost(ibm_subnet.apache_ip_subnet.subnet_cidr,3)}"
  }
}

resource "local_file" "web2_template" {
  content = <<EOF
${data.template_file.web2_template.rendered}
EOF

  filename = "${path.cwd}/Ansible/Playbooks/web2_ip.yml"
}

data "template_file" "web3_template" {
  depends_on = ["local_file.ansible_hosts"]
  template   = "${file("${path.cwd}/TemplateFiles/web.tpl")}"

  vars = {
    web_ip_gateway = "${cidrhost(ibm_subnet.apache_ip_subnet.subnet_cidr,1)}"
    web_ip         = "${cidrhost(ibm_subnet.apache_ip_subnet.subnet_cidr,4)}"
  }
}

resource "local_file" "web3_template" {
  content = <<EOF
${data.template_file.web3_template.rendered}
EOF

  filename = "${path.cwd}/Ansible/Playbooks/web3_ip.yml"
}

data "template_file" "lb1_template" {
  depends_on = ["local_file.ansible_hosts"]
  template   = "${file("${path.cwd}/TemplateFiles/floating.tpl")}"

  vars = {
    lb_ip_gateway = "${cidrhost(ibm_subnet.floating_ip_subnet.subnet_cidr,1)}"
    lb_netmask    = "${cidrnetmask(ibm_subnet.floating_ip_subnet.subnet_cidr)}"
    lb_ip         = "${cidrhost(ibm_subnet.floating_ip_subnet.subnet_cidr,2)}"
  }
}

resource "local_file" "lb1_template" {
  content = <<EOF
${data.template_file.lb1_template.rendered}
EOF

  filename = "${path.cwd}/Ansible/Playbooks/nginx_lb1.yml"
}

data "template_file" "lb2_template" {
  depends_on = ["local_file.ansible_hosts"]
  template   = "${file("${path.cwd}/TemplateFiles/floating.tpl")}"

  vars = {
    lb_ip_gateway = "${cidrhost(ibm_subnet.floating_ip_subnet.subnet_cidr,1)}"
    lb_netmask    = "${cidrnetmask(ibm_subnet.floating_ip_subnet.subnet_cidr)}"
    lb_ip         = "${cidrhost(ibm_subnet.floating_ip_subnet.subnet_cidr,2)}"
  }
}

resource "local_file" "lb2_template" {
  content = <<EOF
${data.template_file.lb2_template.rendered}
EOF

  filename = "${path.cwd}/Ansible/Playbooks/nginx_lb2.yml"
}

data "template_file" "nginx_templates" {
  depends_on = ["local_file.ansible_hosts"]
  template   = "${file("${path.cwd}/TemplateFiles/nginx.tpl")}"

  vars = {
    lb_ip   = "${cidrhost(ibm_subnet.floating_ip_subnet.subnet_cidr,2)}"
    web1_ip = "${cidrhost(ibm_subnet.apache_ip_subnet.subnet_cidr,2)}"
    web2_ip = "${cidrhost(ibm_subnet.apache_ip_subnet.subnet_cidr,3)}"
    web3_ip = "${cidrhost(ibm_subnet.apache_ip_subnet.subnet_cidr,4)}"
  }
}

resource "local_file" "nginx_lb_conf" {
  content = <<EOF
${data.template_file.nginx_templates.rendered}
EOF

  filename = "${path.cwd}/Ansible/Files/load_balancer.conf"
}
