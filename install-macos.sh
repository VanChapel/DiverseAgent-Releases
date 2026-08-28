#!/bin/bash
set -euo pipefail

MANIFEST_URL="https://raw.githubusercontent.com/VanChapel/DiverseAgent-Releases/main/macos-latest.json"
TMPDIR_DIVERSE="$(mktemp -d /tmp/diverseagent-install.XXXXXX)"
trap 'rm -rf "$TMPDIR_DIVERSE"' EXIT
MANIFEST="$TMPDIR_DIVERSE/macos-latest.json"

# Detect the physical chipset, not merely the architecture of a Rosetta-translated shell.
ARM_CAPABLE="$(/usr/sbin/sysctl -in hw.optional.arm64 2>/dev/null || echo 0)"
TRANSLATED="$(/usr/sbin/sysctl -in sysctl.proc_translated 2>/dev/null || echo 0)"
MACHINE="$(/usr/bin/uname -m)"
if [[ "$ARM_CAPABLE" == "1" || "$TRANSLATED" == "1" || "$MACHINE" == "arm64" ]]; then
  ARCH="arm64"
elif [[ "$MACHINE" == "x86_64" ]]; then
  ARCH="x64"
else
  echo "Unsupported Mac architecture: $MACHINE" >&2
  exit 2
fi

echo "DiverseAgent macOS installer: detected chipset $ARCH"
/usr/bin/curl -fsSL --retry 3 --connect-timeout 15 "$MANIFEST_URL" -o "$MANIFEST"
VERSION="$(/usr/bin/plutil -extract version raw -o - "$MANIFEST")"
PKG_URL="$(/usr/bin/plutil -extract "assets.${ARCH}.pkg.url" raw -o - "$MANIFEST")"
PKG_SHA="$(/usr/bin/plutil -extract "assets.${ARCH}.pkg.sha256" raw -o - "$MANIFEST")"
PKG_NAME="$(/usr/bin/plutil -extract "assets.${ARCH}.pkg.name" raw -o - "$MANIFEST")"
PKG="$TMPDIR_DIVERSE/$PKG_NAME"

echo "Downloading DiverseAgent macOS $VERSION ($ARCH)..."
/usr/bin/curl -fL --retry 3 --connect-timeout 15 "$PKG_URL" -o "$PKG"
ACTUAL_SHA="$(/usr/bin/shasum -a 256 "$PKG" | /usr/bin/awk '{print $1}')"
ACTUAL_SHA_LOWER="$(printf '%s' "$ACTUAL_SHA" | /usr/bin/tr '[:upper:]' '[:lower:]')"
PKG_SHA_LOWER="$(printf '%s' "$PKG_SHA" | /usr/bin/tr '[:upper:]' '[:lower:]')"
if [[ "$ACTUAL_SHA_LOWER" != "$PKG_SHA_LOWER" ]]; then
  echo "SHA-256 verification failed." >&2
  echo "Expected: $PKG_SHA" >&2
  echo "Actual:   $ACTUAL_SHA" >&2
  exit 3
fi

echo "SHA-256 verified. Checking Apple package trust..."
/usr/sbin/spctl --assess --type install --verbose=2 "$PKG"
/usr/sbin/pkgutil --check-signature "$PKG"

echo "Installing DiverseAgent $VERSION. macOS may request the administrator password for this initial installation."
/usr/bin/sudo /usr/sbin/installer -pkg "$PKG" -target /

echo "Installed version:"
/bin/cat "/Library/Application Support/DiverseAgent/config/version.json"
echo "Initial installation complete. Future DiverseAgent updates are automatic and select the installed Mac architecture without user interaction."
