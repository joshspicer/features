#!/bin/bash

MITM_VERSION="${VERSION}"
INSTALL_ROOT_CERTS="${INSTALLROOTCERTS}"

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

clean_up() {
    rm -rf /var/lib/apt/lists/*
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends  "$@"
    fi
}

set -e
echo "Activating feature 'mitm-proxy'"

if ! grep -q -E "debian|ubuntu" /etc/os-release; then
    echo "This Feature is only supported on Debian-based distros."
    exit 0
fi

export DEBIAN_FRONTEND=noninteractive
check_packages \
    curl \
    wget \
    ca-certificates \
    openssl

if ! command -v python3 &> /dev/null; then
    echo "No installation of 'python3' found. Installing python3..."
    check_packages python3
fi

if [ "$MITM_VERSION" = "latest" ]; then
    MITM_VERSION=$(curl -s https://api.github.com/repos/mitmproxy/mitmproxy/releases/latest | grep tag_name | cut -d '"' -f 4)
fi

echo "Installing mitmproxy version ${MITM_VERSION}..."

# Install and add to path
wget https://snapshots.mitmproxy.org/${MITM_VERSION}/mitmproxy-${MITM_VERSION}-linux.tar.gz -O /tmp/mitm.tar.gz
tar xvf /tmp/mitm.tar.gz -C /usr/local/bin

# Start mitmdump for 5s in order to generate the ~/.mitmproxy folder and certificates
echo "Configuring for user '${_REMOTE_USER}'..."
timeout 5s su -c "mitmdump" "${_REMOTE_USER}" || true
echo "Configured."

MITM_CERT_FOLDER="${_REMOTE_USER_HOME}/.mitmproxy"

# Install root certificates
# https://docs.mitmproxy.org/stable/concepts-certificates/
if [ "$INSTALL_ROOT_CERTS" = "true" ]; then
    mkdir -p /usr/local/share/ca-certificates/extra
    echo "Installing root certificates (${MITM_CERT_FOLDER} -> /usr/local/share/ca-certificates/extra)"
    # Convert pem to crt
    openssl x509 -in "${MITM_CERT_FOLDER}/mitmproxy-ca-cert.pem" -inform PEM -out mitm.crt
    # Install root certificate
    cp mitm.crt /usr/local/share/ca-certificates/extra/mitm.crt
    update-ca-certificates
fi

clean_up

echo "Done!"
echo "To enable the proxy, run 'export HTTPS_PROXY=https://localhost:8080' and/or 'export HTTP_PROXY=http://localhost:8080'"
#     "remoteEnv": {
#         "HTTPS_PROXY": "https://localhost:8080",
#         "HTTP_PROXY": "http://localhost:8080"
#     },