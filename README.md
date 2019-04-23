# Terraform, Ansible and HA load balancing in the IBM Cloud

One of my colleagues, *Hi Neil!*, wrote a guide for how to do a roll your own Cloud Load balancer scenerio with Keepalived and Nginx on the IBM Cloud. I decided to take up the learning exercise/challenge of migrating the manual steps in the guide to an automated deployment model using Terraform and Ansible. I also added in an extra wrinkle which is to add Security groups in to the mix. The [overview](#overview) and [Objectives and Outcomes](#objectives-and-outcomes) sections below are lifted directly from Neils guide [here](https://dsc.cloud/quickshare/HA-NGINX-How-To.pdf).

## **Major Work in Progress** 
#### Completed
 - Deployment of IaaS Load Balancer and Web Servers using Terraform
 - Generation of local Ansible Inventory file. 
 - Generation of Ansible playbooks using Terraform template provider
 - Ansible playbooks to add portable IPs to Web and Load balancer nodes
 - Ansible playbooks to install and configure Keepalived

#### Todo:
 - Need to configure the `install.yml` file to create a user account that is not named Ryan.
 - Need to put placeholder in the `install.yml` file for where you can add your specific SSH keys (and not mine). 
 - Need to create playbooks for installing Apache and configuring it to listen on private network IPs. 
 - Need to create playbook for Nginx LB config (Keepalived and floating IP are already done).
 - Need to dynamically create Security groups based on Subnets that are provisioned.

## Overview
Load balancers offer a great way to automatically distribute traffic across a pool of servers. Not only does it afford the opportunity to add or remove servers based on resource needs, but, whether a server in the pool goes down for maintenance or because it has some sort of failure, it also assures that you have as much availability for your service as possible when a server becomes unavailable.
There can still, however, be a single point of failure in a load balancer implementation. If you only employ one load balancer in the setup, and if that load balancer fails, then your entire server pool could become unreachable. The objective of this document is to demonstrate how you can create an Active/Passive Highly Available pair of load balancers utilizing some open source operating systems, like Ubuntu, and web server software, like NGINX. NGINX is a powerful, open-source web server package that has many capabilities, including a load balancing functionality that has been used by companies large and small.

## Objectives and Outcomes
This guide will take you through how to order, configure, and deploy and test an active/passive, highly-available load balancer and web server solution on IBM Cloud Infrastructure, using virtual servers to proxy inbound HTTP traffic from the public network to the private network. This solution utilizes two Linux-based load balancers, three Linux-based web servers, a Secondary Portable Private IP subnet, and a Secondary Portable Public IP subnet to accomplish this objective.

We will configure the solution to accept HTTP traffic on the public network, proxy the traffic to the private network, and keep all the servers on the same VLAN, for two specific reasons. The first is that it keeps your web servers secure. You can turn the public network interfaces of your web servers off, thus negating any sort of risk you may face from intrusion attempts. The second is that by keeping everything on the same VLAN, you can take advantage of the native intra-VLAN network and avoid any unnecessary network hops, thus lowering latency and increasing performance.
Here is a simple diagram of what we are trying to accomplish:

![Diagram](https://dsc.cloud/quickshare/Shared-Image-2019-03-07-14-35-27.png)

## Prerequisites
 - Terraform [installed](https://learn.hashicorp.com/terraform/getting-started/install.html)
 - The IBM Cloud Terraform provider [installed and configured](https://ibm-cloud.github.io/tf-ibm-docs/index.html#using-terraform-with-the-ibm-cloud-provider)
 - Since our Web servers are going to be private network only you will need either a [Bastion host](https://en.wikipedia.org/wiki/Bastion_host) or existing IBM Cloud server to run the Ansible commands from. 


