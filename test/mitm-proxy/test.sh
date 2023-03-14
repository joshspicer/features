#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

check "mitmproxy on path" bash -c 'mitmproxy --version'
check "mitmproxy folder and certs generated" bash -c 'test -f "/root/.mitmproxy/mitmproxy-ca-cert.pem"'
check "CA cert installed" bash -c 'test -f "/usr/local/share/ca-certificates/extra/mitm.crt"'

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults