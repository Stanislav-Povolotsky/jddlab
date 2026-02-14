#!/bin/bash
set -ex

mkdir -p /work
apt-get update

# Base packages
packages_to_install="openjdk-21-jdk-headless python3 pipx binutils xmlstarlet zip less"
# Packages for checking network connection
packages_to_install+=" iputils-ping netcat-openbsd"

apt-get install -y $packages_to_install
rm -rf /var/lib/apt/lists/*