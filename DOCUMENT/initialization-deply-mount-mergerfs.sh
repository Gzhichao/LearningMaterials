#!/bin/bash
#设置时区
timedatectl set-timezone Asia/Shanghai
#数据盘符
lsblk |grep -w 14.6T |awk '{print $1}' > 1.txt
#数据盘符相对应的uuid路径
>2.txt
for i in `cat 1.txt`; do ls -l /dev/disk/by-uuid |grep -w $i |awk '{print "/dev/disk/by-uuid/"$9}' >> 2.txt; done
#查看数据盘的uuid相对应的盘符
awk '{print "ls -l",$1}' 2.txt |bash
#写入到配置并挂载数据盘
n=0
for i in `cat 2.txt`
do
    if ls $i >/dev/null;then
       let n++
       [ ! -d "/mnt/data$n" ] && mkdir -p /mnt/data$n
       echo "$i /mnt/data$n xfs noatime 0 0" >> /etc/fstab
    fi
done
mount -a
#安装mergerfs
apt -y install mergerfs
#创建mergerfs挂载目录
[ ! -d "/export" ] && mkdir /export
#挂载mergerfs
df -h | grep -w 15T |awk '{printf $NF":"}' |awk '{print "mergerfs -o noforget,allow_other,use_ino,nonempty,minfreespace=65G,category.create=rand  "$1 "  /export"}'|bash
#安装nfs-kernel-server
apt -y install nfs-kernel-server
#配置nfs
if grep -wvq "/export" /etc/exports;then
     echo "/export *(rw,async,no_root_squash,no_subtree_check,fsid=-1)" >> /etc/exports
fi
#重启nfs服务
systemctl restart nfs-server.service
