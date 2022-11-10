#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

check "cowsay is installed" cowsay moo
check "sl is installed" sl

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults