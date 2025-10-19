#!/bin/bash

# This script prepares the Termux environment by compiling and installing libftdi from source.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "[*] Installing required build tools and libraries from Termux repo..."
pkg install -y git golang clang cmake make pkg-config libusb libusb-dev

# Define a temporary directory for the build
BUILD_DIR=$(mktemp -d)
echo "[*] Created temporary build directory at $BUILD_DIR"

echo "[*] Cloning libftdi source code..."
git clone git://developer.intra2net.com/libftdi.git "$BUILD_DIR"

# Enter the build directory
cd "$BUILD_DIR"
mkdir -p build && cd build

echo "[*] Configuring the build with CMake..."
# We configure cmake to install into the standard Termux prefix ($PREFIX)
# and disable parts we don't need (tests, C++ bindings, Python bindings).
cmake .. -DCMAKE_INSTALL_PREFIX="$PREFIX" -DBUILD_TESTS=OFF -DFTDIPP=OFF -DPYTHON_BINDINGS=OFF

echo "[*] Compiling libftdi..."
make

echo "[*] Installing libftdi to the system..."
make install

echo "[*] Cleaning up build directory..."
# Go back to original directory to be able to remove the build dir
cd -
rm -rf "$BUILD_DIR"

echo "[+] libftdi has been successfully compiled and installed."
echo "[+] You can now run './build.sh' to compile the Go program."
