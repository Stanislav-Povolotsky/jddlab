#!/bin/bash
set -e

mkdir -p /work
apt-get update
apt-get install -y openjdk-21-jdk-headless python3 binutils
rm -rf /var/lib/apt/lists/*