#!/bin/bash

sudo apt purge iptables nano screen ufw -y
sudo sed -i 's#http://archive.ubuntu.com/ubuntu/#http://cn.archive.ubuntu.com/ubuntu/#g' /etc/apt/sources.list
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove -y

sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
sudo lvs

default_eth=$(ip route | awk 'NR==1{print $5}')
arr_eth_ip4_addr=($(ip -f inet addr show dev $default_eth | grep -oP '(?<=inet\s)\d+(\.\d+){3}'))
str_eth_ip4_addr=$(
    IFS=,
    echo "${arr_eth_ip4_addr[*]}"
)
default_gateway4=$(ip route | awk 'NR==1{print $3}')

read -p "input ethernet name(default:$default_eth):" eth
read -p "input ip address(currently $default_eth contains these ip addresses:[$str_eth_ip4_addr].default is ${arr_eth_ip4_addr[0]}):" ip4
read -p "input gateway address(default:$default_gateway4):" gateway4
read -p "input dns server(default:$default_gateway4):" dns4

eth=${eth:-$default_eth}
gateway4=${gateway4:-$default_gateway4}
ip4=${ip4:-${arr_eth_ip4_addr[0]}}
dns4=${dns4:-$default_gateway4}

sudo netplan set ethernets.$eth.dhcp4="NULL"
sudo netplan set ethernets.$eth.addresses="NULL"
sudo netplan set ethernets.$eth.addresses="[$ip4/24]"
sudo netplan set ethernets.$eth.routes="[{to: default, via: $gateway4}]"
sudo netplan set ethernets.$eth.nameservers.addresses="NULL"
sudo netplan set ethernets.$eth.nameservers.addresses="[$dns4]"
# netplan set ethernets.$eth.optional=false
sudo netplan apply
sudo netplan get


