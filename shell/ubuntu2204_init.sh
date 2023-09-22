#!/bin/bash

apt purge iptables nano screen ufw -y
sed 's#archive.ubuntu.com#cn.archive.ubuntu.com/#g' /etc/apt/sources.list.curtin.old >/etc/apt/sources.list
apt update
apt full-upgrade -y
apt autoremove -y

lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
resize2fs /dev/ubuntu-vg/ubuntu-lv
lvs

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

netplan set ethernets.$eth.dhcp4="NULL"
netplan set ethernets.$eth.addresses="NULL"
netplan set ethernets.$eth.gateway4="NULL"
netplan set ethernets.$eth.routes="NULL"
netplan set ethernets.$eth.nameservers.addresses="NULL"
netplan set ethernets.$eth.addresses="[$ip4/24]"
netplan set ethernets.$eth.routes="[{to: default, via: $gateway4}]"
netplan set ethernets.$eth.nameservers.addresses="[$dns4]"
# netplan set ethernets.$eth.optional=false
netplan apply
netplan get
