#!/bin/bash

MITM_VERSION="${VERSION:-latest}"
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

# Determine the correct filename format based on version
# For versions > 10.1.5, the filename includes architecture (linux-x86_64)
# For versions <= 10.1.5, the filename is just linux
version_compare() {
    # Simple version comparison for x.y.z format
    # Returns 0 if $1 > $2, 1 if $1 <= $2
    local v1=$(echo "$1" | sed 's/^v//')
    local v2=$(echo "$2" | sed 's/^v//')
    
    # Check if versions are numeric-like (contain only digits and dots)
    if ! echo "$v1" | grep -qE '^[0-9]+(\.[0-9]+)*$'; then
        echo "Warning: Non-numeric version '$1', assuming new format"
        return 0  # Assume newer format for non-numeric versions
    fi
    
    # Split versions into major.minor.patch, defaulting missing parts to 0
    local v1_major=$(echo "$v1" | cut -d. -f1)
    local v1_minor=$(echo "$v1" | cut -d. -f2)
    local v1_patch=$(echo "$v1" | cut -d. -f3)
    
    local v2_major=$(echo "$v2" | cut -d. -f1)
    local v2_minor=$(echo "$v2" | cut -d. -f2)
    local v2_patch=$(echo "$v2" | cut -d. -f3)
    
    # Handle missing parts by defaulting to 0
    [ -z "$v1_minor" ] && v1_minor=0
    [ -z "$v1_patch" ] && v1_patch=0
    [ -z "$v2_minor" ] && v2_minor=0
    [ -z "$v2_patch" ] && v2_patch=0
    
    # Ensure all parts are numbers
    [ -z "$v1_major" ] && v1_major=0
    [ -z "$v2_major" ] && v2_major=0
    
    # Compare major.minor.patch
    if [ "$v1_major" -gt "$v2_major" ]; then
        return 0
    elif [ "$v1_major" -lt "$v2_major" ]; then
        return 1
    elif [ "$v1_minor" -gt "$v2_minor" ]; then
        return 0
    elif [ "$v1_minor" -lt "$v2_minor" ]; then
        return 1
    elif [ "$v1_patch" -gt "$v2_patch" ]; then
        return 0
    else
        return 1
    fi
}

# Detect platform architecture for newer versions
detect_architecture() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        *)
            echo "Warning: Unsupported architecture '$arch', defaulting to x86_64" >&2
            echo "x86_64"
            ;;
    esac
}

# Check if version is greater than 10.1.5
# Strip 'v' prefix from version for filename construction
VERSION_NO_V=$(echo "${MITM_VERSION}" | sed 's/^v//')

if version_compare "${MITM_VERSION}" "10.1.5"; then
    ARCH=$(detect_architecture)
    FILENAME="mitmproxy-${VERSION_NO_V}-linux-${ARCH}.tar.gz"
else
    FILENAME="mitmproxy-${VERSION_NO_V}-linux.tar.gz"
fi

echo "Using filename: ${FILENAME}"

# Install and add to path
wget https://snapshots.mitmproxy.org/${MITM_VERSION}/${FILENAME} -O /tmp/mitm.tar.gz
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