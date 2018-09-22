#!/usr/bin/env bash

# Determine OS and Version
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

echo "OS is $OS and VER is $VER" | tee -a /tmp/startup-script-out.txt

# Install python on Ubuntu (16.04)
if [ "$OS" = "Ubuntu" -a "$VER" = "16.04" ]; then
   echo "Installing python" | tee -a /tmp/startup-script-out.txt
   sudo apt-get -y install python | tee -a /tmp/startup-script-out.txt
fi


lsblk | tee -a /tmp/startup-script-out.txt

SDB_DEVICE=`lsblk | grep db | cut -d ' ' -f 1`
mkfs.xfs /dev/$SDB_DEVICE | tee -a /tmp/startup-script-out.txt
mkdir /data | tee -a /tmp/startup-script-out.txt
mount /dev/$SDB_DEVICE /data | tee -a /tmp/startup-script-out.txt

if [ "$OS" = "Redhat" ]; then
  semanage fcontext -a -t  mongod_var_lib_t /data | tee -a /tmp/startup-script-out.txt
  restorecon -v /data | tee -a /tmp/startup-script-out.txt
fi

SDB_UUID=`blkid /dev/$SDB_DEVICE | cut -d' ' -f2 | cut -d '"' -f2`
cp -p /etc/fstab /etc/fstab.bak
echo "Adding follwing entry to fstab: " 
echo "UUID=$SDB_UUID /data      xfs     defaults        0 0" | tee -a /etc/fstab /tmp/startup-script-out.txt



