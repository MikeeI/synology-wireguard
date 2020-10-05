#!/bin/bash
VER=6.2
ARCHS=(
    "apollolake"
    "armada38x"
    "avoton"
    "braswell"
    "broadwell"
    "cedarview"
    "denverton"
    "rtd1296"
    "x64"
)
set -e

# Check that we are running as root
if [ `id -u` -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Create release directory if needed
if [ ! -d target/ ]; then
    mkdir target/
fi

sudo apt update -yq
sudo apt install aria2 -yq

# Download all necessary tarballs before calling into the docker containers.
echo "Downloading environment tarballs"
url_base="https://sourceforge.net/projects/dsgpl/files/toolkit/DSM$VER"
sudo mkdir -p toolkit_tarballs/

pushd toolkit_tarballs/
if [ ! -f base_env-$VER.txz ]; then
    aria2c -q -x 8 "$url_base/base_env-$VER.txz?use_mirror=kumisystems"
fi
for arch in ${ARCHS[@]}; do
    if [ ! -f ds.$arch-$VER.dev.txz ]; then
        aria2c -q -x 8 "$url_base/ds.$arch-$VER.dev.txz?use_mirror=kumisystems"
    fi
    if [ ! -f ds.$arch-$VER.env.txz ]; then
        aria2c -q -x 8 "$url_base/ds.$arch-$VER.env.txz?use_mirror=kumisystems"
    fi
done
popd

# Ensure that we are using an up to date docker image
docker build -t synobuild .

for arch in ${ARCHS[@]}; do
    echo "Building '$arch'"

    # Remove old artifact directory
    if [ -d artifacts/ ]; then
        rm -rf artifacts/
    fi

    docker run \
        --rm \
        --privileged \
        --env PACKAGE_ARCH=$arch \
        --env DSM_VER=6.2 \
        -v $(pwd)/artifacts:/result_spk \
        -v $(pwd)/toolkit_tarballs:/toolkit_tarballs \
        synobuild

    mv artifacts/WireGuard-*/* target/
done

echo "Current Folder"
ls -lah
echo "toolkit_tarballs"
ls -lah $(pwd)/toolkit_tarballs
echo "toolkit_tarballs"
ls -lah toolkit_tarballs

# Clean up artifact directory
if [ -d artifacts/ ]; then
    rm -rf artifacts/
fi

# Change permissions of the target directory to match the local user if called
# using sudo
if [ ! -z ${SUDO_USER+x} ]; then
    chown "$SUDO_USER:$SUDO_USER" -R target/
fi
