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

# Install python on Ubuntu (16.04)
if [ "$OS" = "Ubuntu" -a "$VER" = "16.04" ]; then
   echo "Installing python"
   sudo apt-get -y install python
fi

cat >> /etc/hosts <<EOL
# vagrant environment nodes
11.0.0.11 mongo1
11.0.0.12 mongo2
11.0.0.13 mongo3
11.0.0.14 mongo4
11.0.0.15 mongo5
11.0.0.16 mongo6
11.0.0.17 mongo7
11.0.0.18 mongo8
EOL
