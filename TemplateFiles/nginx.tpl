upstream backend {
    server ${web1_ip};
    server ${web2_ip};
    server ${web3_ip};
  }
  server {
  listen ${lb_ip}:80;

  location / {
    proxy_pass http://backend;
    }
}