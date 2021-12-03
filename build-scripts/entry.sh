#!/bin/bash

echo "::endgroup::" # ::group::Start Docker container

BUILD_USER="builder"
BUILD_USER_HOME="/home/builder"
BUILD_DEPENDENCIES=(
	base-devel
)

echo "::group::Install common dependencies"

# Prepare dependencies
pacman -Syu ${BUILD_DEPENDENCIES[*]} --noconfirm --needed

echo "::endgroup::"

echo "::group::Prepare environment"

# Prepare builder user
if ! id "$BUILD_USER" &> /dev/null; then
	useradd "$BUILD_USER" --home-dir "$BUILD_USER_HOME"
	mkdir "$BUILD_USER_HOME"
	chown "$BUILD_USER:$BUILD_USER" "$BUILD_USER_HOME"
fi
echo "$BUILD_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Prepare environment
mkdir /build
chown "$BUILD_USER" /build

echo "::endgroup::"

echo "::group::Install yay"

# Install yay
sudo -EHu "$BUILD_USER" /build-scripts/get-yay.sh

echo "::endgroup::"

# Enter builder user and run build.sh
cd /build
sudo -EHu "$BUILD_USER" /build-scripts/build.sh
