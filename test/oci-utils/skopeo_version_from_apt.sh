#!/bin/bash

# TODO: Consolidate when https://github.com/devcontainers/cli/pull/265 ships

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.

file /usr/local/bin/oras
file /home/linuxbrew/.linuxbrew/bin/skopeo

check "oras installed and on path" oras version

check "skopeo installed and on path" skopeo --version

check "skopeo version 1.4.1" skopeo --version | grep 1.4.1

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults