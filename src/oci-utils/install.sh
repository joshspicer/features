#!/bin/sh
set -e

# Options provided from devcontainer.json, or default values defined in 'devcontainer-feature.json'
ORAS_VERSION="$ORASVERSION"
SKOPEO_VERSION="$SKOPEOVERSION" 

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

echo "Activating feature 'oci-utils'"

export DEBIAN_FRONTEND=noninteractive

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Feature installation should always be run as root.'
    exit 1
fi

. /etc/os-release
if [ "${ID}" != "ubuntu" && "${ID}" != "debian" && "${ID_LIKE}" != "debian"  ]; then
    echo -e 'This Feature only supports Ubuntu and Debian based distros.'
    exit 1
fi

# TODO: Check architecture - expects x86_64 right now 

check_packages apt-transport-https curl ca-certificates gnupg2 dirmngr

echo "Installing 'oras' CLI"

cd /tmp
    curl -LO https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz
    mkdir -p oras-install/
    tar -zxf oras_${ORAS_VERSION}_*.tar.gz -C oras-install/
    mv oras-install/oras /usr/local/bin/
    rm -rf oras_${ORAS_VERSION}_*.tar.gz oras-install/
cd -

echo "Installing 'skopeo' CLI..."

# Take advantage of the prebuilt binaries that homebrew stores 
# as OCI artifacts.
# Eg: https://github.com/Homebrew/homebrew-core/pkgs/container/core%2Fskopeo
# We _just_ installed oras, so we can directly pull the binary - no need for any other dependency :D

# TODO: This doesn't work, yet!
# cd /tmp
#     /usr/local/bin/oras pull ghcr.io/homebrew/core/skopeo:${SKOPEO_VERSION}
#     mkdir -p skopeo-install/
#     tar -zxf skopeo--${SKOPEO_VERSION}.x86_64_linux.bottle.tar.gz -C skopeo-install/
#     mv skopeo-install/skopeo/${SKOPEO_VERSION}/bin/skopeo /usr/local/bin/
#     rm -rf skopeo--* skopeo-install/
# cd -

# Clean up
rm -rf /var/lib/apt/lists/*