#!/bin/bash
set -e

apt-get update && apt-get install -y curl ca-certificates python3-pip python3-venv zip openjdk-21-jdk-headless git jq xmlstarlet python3-distutils

echo Installing mvn
pushd /tmp
#curl -O https://dlcdn.apache.org/maven/maven-3/3.9.10/binaries/apache-maven-3.9.10-bin.tar.gz
curl -o maven-index.html https://dlcdn.apache.org/maven/maven-3/
maven_latest_version=$(grep -oP '(?<=<a href=")[0-9]+\.[0-9]+\.[0-9]+/' maven-index.html | sed 's:/$::' | sort -V | tail -n1 | tr -d '\n' | tr -d '\r')
rm maven-index.html
echo "Detected latest maven version: $maven_latest_version"
curl -O https://dlcdn.apache.org/maven/maven-3/$maven_latest_version/binaries/apache-maven-$maven_latest_version-bin.tar.gz
tar -xvf apache-maven-*.tar.gz
rm -f apache-maven-*.tar.gz
mv apache-maven-* /opt/
ln -s /opt/apache-maven-*/bin/mvn /usr/local/bin/mvn
popd
mvn dependency:get >/dev/null 2>&1 || echo MVN precached

echo Installing rust compiler
curl https://sh.rustup.rs -sSf | sh -s -- -y
