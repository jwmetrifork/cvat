#!/bin/bash

# Exit if any command fails
set -e

###############################################################################
# Variables
###############################################################################
NUCTL_VERSION="1.13.0"
NUCTL_BINARY="nuctl-${NUCTL_VERSION}-linux-amd64"
NUCTL_DOWNLOAD_URL="https://github.com/nuclio/nuclio/releases/download/${NUCTL_VERSION}/${NUCTL_BINARY}"

###############################################################################
# Step 1: Set up CVAT and serverless features for automatic annotation
###############################################################################
echo "Setting up Docker containers for CVAT and automatic annotation..."
docker compose -f docker-compose.yml -f components/serverless/docker-compose.serverless.yml up -d

###############################################################################
# Step 2: Download nuctl for serverless functionality, if not already downloaded
###############################################################################
if [ ! -f "${NUCTL_BINARY}" ]; then
    echo "Downloading nuctl version ${NUCTL_VERSION}..."
    wget ${NUCTL_DOWNLOAD_URL}
else
    echo "nuctl version ${NUCTL_VERSION} already downloaded."
fi

###############################################################################
# Step 3: Make nuctl executable and move to /usr/local/bin
###############################################################################
echo "Making nuctl executable and linking it to /usr/local/bin..."
sudo chmod +x ${NUCTL_BINARY}
sudo ln -sf $(pwd)/${NUCTL_BINARY} /usr/local/bin/nuctl

echo "Installation completed successfully!"

