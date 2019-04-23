## Dnsimple config
```
variable dnsimple_token {}
variable dnsimple_account {}
provider "dnsimple" {
  token   = "${var.dnsimple_token}"
  account = "${var.dnsimple_account}"
}

```

## Ansible inventory

```
resource "ansible_group" "web" {
  depends_on = ["ibm_compute_vm_instance.web_nodes"]
  inventory_group_name = "web"
}

resource "ansible_host" "web1_hostentry" {
  depends_on = ["ansible_group.web"]
    inventory_hostname = "web1"
    groups = ["web"]
    vars {
        ansible_host = "web1.${var.domainname}"
        ansible_user = "ryan"
    }
}

resource "ansible_host" "web2_hostentry" {
  depends_on = ["ansible_host.web1_hostentry"]
    inventory_hostname = "web2"
    groups = ["web"]
    vars {
        ansible_host = "web2.${var.domainname}"
        ansible_user = "ryan"
    }
}

resource "ansible_host" "web3_hostentry" {
  depends_on = ["ansible_host.web2_hostentry"]
    inventory_hostname = "web3"
    groups = ["web"]
    vars {
        ansible_host = "web3.${var.domainname}"
        ansible_user = "ryan"
    }
}
```

```
resource "local_file" "output" {
content = <<EOF
"${ibm_compute_vm_instance.node.0.ipv4_address_private}"
EOF

    filename = "./file.txt"
}

resource "local_file" "rendered" {
  content = <<EOF
${data.template_file.init.rendered}
EOF

  filename = "./rendered.env"
}
```

```
# Use a built-in function cidrhost with index 2 (first usable IP).
output "floating_ip" {
  value = "${cidrhost(ibm_subnet.floating_ip_subnet.subnet_cidr,2)}"
}


output "floating_netmask" {
  value = "${cidrnetmask(ibm_subnet.floating_ip_subnet.subnet_cidr)}"
}


resource "null_resource" "config_upload" {
  depends_on = ["dnsimple_record.floating_ip_record"]

  provisioner "file" {
   source      = "postinstall.sh"
    destination = "/home/ryan/postinstall.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ryan/postinstall.sh",
      "/home/ryan/postinstall.sh",
    ]
  }

  connection {
    host      = "${ibm_compute_vm_instance.nginx_lb_nodes.0.ipv4_address}"
    type     = "ssh"
    user     = "ryan"
    private_key = "${file("~/.ssh/id_rsa")}"
    }
}

```