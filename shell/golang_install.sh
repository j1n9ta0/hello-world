#!/bin/bash

version=1.20.6

wget https://go.dev/dl/go${version}.linux-amd64.tar.gz
# 解压文件
tar zxf go${version}.linux-amd64.tar.gz -C /usr/local

#添加Gopath路径

echo 'export GOROOT=/usr/local/go' >>~/.bashrc
echo 'export PATH=$PATH:$GOROOT/bin' >>~/.bashrc
echo 'export GOPATH=$HOME' >>~/.bashrc
# 激活配置
source ~/.bashrc
