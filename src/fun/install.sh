#!/bin/bash
set -e

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

install_from_brew() {
    local PACKAGE="$1"
    echo "Installing '$PACKAGE' via brew..."
    brew install "$PACKAGE"
}

clean_up() {
    # Clean up
    rm -rf /var/lib/apt/lists/*
}

updaterc() {
    echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."
    if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
        echo -e "$1" >> /etc/bash.bashrc
    fi
    if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
        echo -e "$1" >> /etc/zsh/zshrc
    fi
}

try_install_from_apt_or_brew() {
    if command -v "$1" > /dev/null 2>&1; then
        echo "'$1' already installed"
        return
    fi

    local PACKAGE=$1
    check_packages "$PACKAGE" || install_from_brew "$PACKAGE" || (echo "Failed to install '$PACKAGE'" && exit 1)
}

echo "Activating feature 'fun'"

export DEBIAN_FRONTEND=noninteractive

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Feature installation should always be run as root.'
    exit 1
fi

. /etc/os-release
if [ "${ID}" != "ubuntu" ] && [ "${ID}" != "debian"  ]; then
    echo -e 'This Feature only supports Ubuntu and Debian based distributions.'
    exit 1
fi

ARCHITECTURE="$(uname -m)"
if [ "${ARCHITECTURE}" != "amd64" ] && [ "${ARCHITECTURE}" != "x86_64" ]; then
  echo "(!) Architecture $ARCHITECTURE unsupported"
  exit 1
fi

# TODO: Be more resilient and install node/brew/etc. if not present
############################################
if ! type brew > /dev/null 2>&1; then
    echo "(!) Homebrew not installed. Please include the homebrew Feature and then try again!"
    exit 1
fi

if ! type npm > /dev/null 2>&1; then
    echo "(!) npm not installed. Please install npm and then try again!"
    exit 1
fi

if ! type node > /dev/null 2>&1; then
    echo "(!) node not installed. Please install node and then try again!"
    exit 1
fi
############################################

try_install_from_apt_or_brew "sl"
try_install_from_apt_or_brew "cowsay"


clean_up