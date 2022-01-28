#!/bin/bash -e

# Environment variables:
#
# - REPO_URL
# - PACKAGE_NAME

echo "::group::Parsing PKGBUILD"

# Copy PKGBUILD and other required files
cp -r /pkgbuild/. .

# Determine the built package filename (we can't use `basename` here ...)
PACKAGE_FILES="$(makepkg --packagelist | rev | cut -d'/' -f 1 | rev)"

echo "::endgroup::"

echo "::group::Determine if the packages are already built"

# Determine if the packages are already built
if [[ "$REPO_URL" != "" ]]; then
	PACKAGE_ALL_BUILT="true"
	for PACKAGE_FILE in $PACKAGE_FILES; do
		PACKAGE_URL="$REPO_URL/$PACKAGE_FILE"
		echo Checking if package exists: $PACKAGE_URL

		CURL_OUTPUT_FILE="/tmp/curl_output.txt"
		curl -I --header 'Cache-Control: no-cache' "$PACKAGE_URL" -w '%{http_code}' | tee "$CURL_OUTPUT_FILE"
		echo # Fix curl's output doesn't end with newline

		HTTP_STATUS="$(cat "$CURL_OUTPUT_FILE" | tail -n 1)"
		if [[ "$HTTP_STATUS" != "200" ]]; then
			PACKAGE_ALL_BUILT="false"
			break
		fi
	done
else
	PACKAGE_ALL_BUILT="false"
fi

echo "::endgroup::"

if [[ "$PACKAGE_ALL_BUILT" == "true" ]]; then
	echo "::set-output name=skipped::$PACKAGE_ALL_BUILT"
	exit 0
fi

echo "::group::Install build dependencies"

# Install build dependencies
(
	# Run "source PKGBUILD" in a subshell
	source PKGBUILD
	# Install build dependencies with yay
	yay -S ${makedepends[*]} --needed --noconfirm
)

# Install extra build dependencies
EXTRA_BUILD_DEPENDENCIES_CMDLINE="$(echo "$EXTRA_BUILD_DEPENDENCIES" | xargs)"
if [[ "$EXTRA_BUILD_DEPENDENCIES_CMDLINE" != "" ]]; then
	sudo pacman -S $EXTRA_BUILD_DEPENDENCIES_CMDLINE --needed --noconfirm
fi

echo "::endgroup::"

echo "::group::Build packages"

# Build packages
makepkg -sfA --skippgpcheck --needed --noconfirm

echo "::endgroup::"

# Set output
echo "::set-output name=skipped::$PACKAGE_ALL_BUILT"

# Copy packages to target directory
sudo cp $PACKAGE_FILES /target/
