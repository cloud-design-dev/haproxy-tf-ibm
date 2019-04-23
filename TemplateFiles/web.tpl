---
  - hosts: web
    become: true
    tasks:
      - name: Adding Portable IP to Web nodes
        blockinfile:
          path: /etc/network/interfaces.d/50-cloud-init.cfg
          block: |
            auto eth0:1
            iface eth0:1 inet static
            address ${web_ip}/29
            post-up route add default gw ${web_ip_gateway} || true
            pre-down route del default gw ${web_ip_gateway} || true
            post-up route add -net 10.0.0.0 netmask 255.0.0.0 gw ${web_ip_gateway} || true
            pre-down route del -net 10.0.0.0 netmask 255.0.0.0 gw ${web_ip_gateway} || true
            post-up route add -net 161.26.0.0 netmask 255.255.0.0 gw ${web_ip_gateway} || true
            pre-down route del -net 161.26.0.0 netmask 255.255.0.0 gw ${web_ip_gateway} || true
            post-up route add -net 166.8.0.0 netmask 255.252.0.0 gw ${web_ip_gateway} || true
            pre-down route del -net 166.8.0.0 netmask 255.252.0.0 gw ${web_ip_gateway} || true


