#!/bin/bash
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
CurCore="linux-image-$(uname -r)"
CurCoreExtra="linux-image-extra-$(uname -r)"
echo "清理无用的内核"
echo "当前内核是：$CurCore"
for i in $(dpkg --get-selections | grep linux-image); do
	if [ "$i" != "install" ] && [ "$i" != "$CurCore" ] && [ "$i" != "$CurCoreExtra" ] && [ "$i" != 'linux-image-generic' ]; then
		echo "删除无用的内核：$i"
		sudo apt-get remove --purge $i
	fi
done
echo "更新启动菜单"
sudo update-grub
sudo apt-get autoremove
sudo apt-get autoclean
history -c
echo >~/.bash_history
