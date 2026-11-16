#!/bin/bash
set -ex

mkdir -p /work
apt-get update

# Base packages. Java 25 (LTS): recent tool releases need it (e.g. FernFlower is
# built for class file version 69); older Java tools run on it unchanged.
packages_to_install="openjdk-25-jdk-headless python3 pipx binutils xmlstarlet zip unzip less file"
# Packages for checking network connection
packages_to_install+=" iputils-ping netcat-openbsd"
# Forwarding the in-container ADB port to the host ADB server (JDDLAB_ADB_SERVER, see entrypoint.sh)
packages_to_install+=" socat"
# blutter compiles a Dart-version-specific analyzer on first use (C++20 compiler and libs)
packages_to_install+=" git g++ make cmake ninja-build pkg-config libicu-dev libcapstone-dev"

# The Android SDK ships x86_64-only platform-tools (adb) and build-tools binaries
# (zipalign, aapt - used by objection). On arm64 use the native Ubuntu builds
# (apksigner is Java and works).
if [[ "$(uname -m)" == "aarch64" ]]; then
    packages_to_install+=" adb zipalign aapt"
fi

apt-get install -y $packages_to_install
rm -rf /var/lib/apt/lists/*
# JDK modules for jlink only (~340 MB), not used by any tool
rm -rf /usr/lib/jvm/java-*-openjdk-*/jmods
