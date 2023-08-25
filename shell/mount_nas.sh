#!/bin/bash

mkdir -p /mnt/nas
mount -t cifs -o username="user",password="123456" //192.168.0.254/storage /mnt/nas
