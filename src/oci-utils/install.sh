#!/bin/sh
set -e

# Options provided from devcontainer.json, or default values defined in 'devcontainer-feature.json'
ORAS_VERSION=ORASVERSION

echo "Activating feature 'oci-utils'"
export DEBIAN_FRONTEND=noninteractive

echo "Installing 'skopeo' CLI..."
apt update -y
apt install skopeo -y

echo "Installing 'oras' CLI"
curl -LO https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz
mkdir -p oras-install/
tar -zxf oras_${ORAS_VERSION}_*.tar.gz -C oras-install/
mv oras-install/oras /usr/local/bin/
rm -rf oras_${ORAS_VERSION}_*.tar.gz oras-install/