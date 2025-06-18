#!/bin/sh

# UUID="00277430-85b5-46e2-a6c9-4fe3da538187"
# APP_NAME="lyz7805-v2ray"
REGION="hkg"

# Ensure flyctl is installed and in PATH
if ! command -v flyctl >/dev/null 2>&1; then
    echo "Installing flyctl locally..."
    export FLYCTL_INSTALL="$HOME/.fly"
    mkdir -p "$FLYCTL_INSTALL/bin"
    curl -L https://fly.io/install.sh | sh
    export PATH="$FLYCTL_INSTALL/bin:$PATH"
    echo "flyctl installed to $FLYCTL_INSTALL"
fi
