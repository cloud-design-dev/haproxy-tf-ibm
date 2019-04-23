---
  - hosts: nginx
    become: true
    tasks:
      - name: Adding Portable IP to LB nodes
        blockinfile:
          path: /etc/network/interfaces.d/50-cloud-init.cfg
          block: |
            auto eth1:1
            iface eth1:1 inet static
            address ${lb_ip}/30
            netmask: ${lb_netmask}
            gateway: ${lb_ip_gateway}
      - name: Install keepalived
        apt:
          name: keepalived
          state: present
      - name: Config keepalived 
        copy:
          dest: /etc/keepalived/keepalived.conf
          content: | 
            vrrp_instance VI_1 {
                state MASTER
                interface eth1
                virtual_router_id 51
                priority 101
                advert_int 1
                authentication {
                    auth_type PASS
                    auth_pass 1111
                }
                virtual_ipaddress {
                    ${lb_ip}
                }
            }
      - name: Restart networking
        command: ifup eth1:1
      - name: Start service keepalived, if not started
        service:
          name: keepalived
          state: started
      - name: Install nginx
        apt:
          name: nginx
          state: present
      - name: Put load balancer conf in place
        copy: 
          src: '../Files/load_balancer.conf'
          dest: /etc/nginx/conf.d/load-balancer.conf
          force: no
      - name: Move default nginx conf
        stat: path=/etc/nginx/conf.d/
        register: conf_exists