#!/bin/bash

# Build (if necessary) and install yay

# Check if yay is already installed
if which yay &> /dev/null; then
	exit 0
fi

# Check if yay exists in repos
if pacman -Ss ^yay$ &> /dev/null; then
	# Install from rpeo
	sudo pacman -S yay --needed --noconfirm
else
	# Install from AUR
	mkdir /tmp/build-yay
	cd /tmp/build-yay
	curl https://aur.archlinux.org/cgit/aur.git/snapshot/yay-bin.tar.gz | tar xzvf -
	cd yay-bin
	makepkg -sif --needed --noconfirm
fi
