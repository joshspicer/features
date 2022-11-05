#!/bin/sh
set -e

# Options provided from devcontainer.json, or default values defined in 'devcontainer-feature.json'
ORAS_VERSION="$ORASVERSION"
SKOPEO_VERSION="$SKOPEOVERSION" 

USERNAME="automatic"

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
if [ "${ID}" != "ubuntu" && "${ID}" != "debian"  ]; then
    echo -e 'This Feature only supports Ubuntu and Debian based distributions.'
    exit 1
fi

ARCHITECTURE="$(uname -m)"
if [ "${ARCHITECTURE}" != "amd64" ] && [ "${ARCHITECTURE}" != "x86_64" ]; then
  echo "(!) Architecture $ARCHITECTURE unsupported"
  exit 1
fi

# # Determine the appropriate non-root user
# if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
#   USERNAME=""
#   POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
#   for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
#     if id -u ${CURRENT_USER} > /dev/null 2>&1; then
#       USERNAME=${CURRENT_USER}
#       break
#     fi
#   done
#   if [ "${USERNAME}" = "" ]; then
#     USERNAME=root
#   fi
# elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
#   USERNAME=root
# fi


check_packages \
  bzip2 \
  ca-certificates \
  curl \
  file \
  fonts-dejavu-core \
  g++ \
  git \
  less \
  libz-dev \
  locales \
  make \
  netbase \
  openssh-client \
  patch \
  sudo \
  tzdata \
  uuid-runtime

echo "Installing 'oras' CLI"

cd /tmp
    curl -LO https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz
    mkdir -p oras-install/
    tar -zxf oras_${ORAS_VERSION}_*.tar.gz -C oras-install/
    mv oras-install/oras /usr/local/bin/
    rm -rf oras_${ORAS_VERSION}_*.tar.gz oras-install/
cd -

echo "Installing 'skopeo' CLI..."

check_packages skopeo || :

if ! type skopeo > /dev/null 2>&1; then
    echo "Could not download 'skopeo' via apt. Installing via homebrew."

    # Check if homebrew (linuxbrew) installed.
    if ! type brew > /dev/null 2>&1; then
        echo "Installing homebrew..."
        # Borrowed from: https://github.com/meaningful-ooo/devcontainer-features/blob/main/src/homebrew/install.sh
        BREW_PREFIX="/home/linuxbrew/.linuxbrew"
        git clone --depth 1 https://github.com/Homebrew/brew "${BREW_PREFIX}/Homebrew"
        mkdir -p "${BREW_PREFIX}/Homebrew/Library/Taps/homebrew"
        git clone --depth 1 https://github.com/Homebrew/homebrew-core "${BREW_PREFIX}/Homebrew/Library/Taps/homebrew/homebrew-core"

        "${BREW_PREFIX}/Homebrew/bin/brew" config
        mkdir "${BREW_PREFIX}/bin"
        ln -s "${BREW_PREFIX}/Homebrew/bin/brew" "${BREW_PREFIX}/bin"
        # chown -R ${USERNAME} "${BREW_PREFIX}"
    fi

    /home/linuxbrew/.linuxbrew/bin/brew install skopeo
fi

# Clean up
rm -rf /var/lib/apt/lists/*