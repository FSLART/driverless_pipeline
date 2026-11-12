#!/usr/bin/env bash
# Install the ZED SDK for this platform.
#
# Usage: install_zed_sdk.sh <version|latest> <l4t_major> <l4t_minor>
#
# On arm64 (Jetson) the installer is picked by L4T release. On x86_64 it is the
# Ubuntu 22.04 build for the CUDA major version found in the image, and the L4T
# arguments are ignored.
#
# Stereolabs has no "latest" download link, so for "latest" we walk the
# <major>.<minor> URLs upwards (starting at 5.0) and keep the highest one that
# resolves to an installer. Unknown versions redirect to the website instead.
set -euo pipefail

VERSION="${1:-latest}"
BASE_URL="https://download.stereolabs.com/zedsdk"

if [[ "$(uname -m)" == "aarch64" ]]; then
    PLATFORM="l4t${2}.${3}/jetsons"
else
    CUDA_MAJOR=$(nvcc --version | sed -n 's/.*release \([0-9]*\)\..*/\1/p')
    PLATFORM="cu${CUDA_MAJOR}/ubuntu22"
fi

installer_url() {
    local url
    url=$(curl -sIL -o /dev/null -w '%{url_effective}' "${BASE_URL}/$1/${PLATFORM}")
    [[ "${url}" == *.run ]] && echo "${url}"
}

if [[ "${VERSION}" == "latest" ]]; then
    major=5
    minor=0
    installer_url "${major}.${minor}" > /dev/null \
        || { echo "No ZED SDK found for ${PLATFORM}" >&2; exit 1; }
    while true; do
        if installer_url "${major}.$((minor + 1))" > /dev/null; then
            minor=$((minor + 1))
        elif installer_url "$((major + 1)).0" > /dev/null; then
            major=$((major + 1))
            minor=0
        else
            break
        fi
    done
    VERSION="${major}.${minor}"
fi

URL=$(installer_url "${VERSION}") \
    || { echo "ZED SDK ${VERSION} is not available for ${PLATFORM}" >&2; exit 1; }
echo "Installing ZED SDK ${VERSION} from ${URL}"

# The Jetson installer reads the L4T release from /etc/nv_tegra_release;
# containers do not always ship it.
if [[ "$(uname -m)" == "aarch64" && ! -f /etc/nv_tegra_release ]]; then
    echo "# R${2} (release), REVISION: ${3}.0" > /etc/nv_tegra_release
fi

wget -q "${URL}" -O /tmp/zed_sdk.run
chmod +x /tmp/zed_sdk.run
# CUDA comes from the base image, so skip the bundled one.
/tmp/zed_sdk.run -- silent skip_cuda skip_tools
rm -f /tmp/zed_sdk.run
# The installer leaves the SDK and its Python packages readable by root only, which
# breaks non-root users (the dev container): building zed_bridge, pyzed, and vcs.
chmod -R a+rX /usr/local/zed /usr/local/lib/python3*/dist-packages
rm -rf /var/lib/apt/lists/*
