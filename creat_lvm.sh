#!/bin/bash
dev='/dev/vdb'

fdisk -l ${dev} || exit 1

echo -e "n\np\n1\n\n\nt\n8e\nw" |fdisk ${dev}

pvdisplay |grep "${dev}1" ||\
pvcreate /dev/vdb1

vgdisplay |grep "vg0" ||\
vgcreate vg0 ${dev}1

lvdisplay |grep lv_data ||\
lvcreate -l +100%FREE -n lv_data vg0

mkfs.ext4 /dev/vg0/lv_data
tune2fs -m 0 /dev/vg0/lv_data
grep 'lv_data' /etc/fstab > /dev/null 2>&1 ||\
echo "/dev/vg0/lv_data /data ext4 defaults 0 1" >> /etc/fstab
mount -a
df -h
