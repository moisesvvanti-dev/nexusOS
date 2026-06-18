#!/bin/bash
###############################################################################
# NexusOS Local Build Script
# Build NexusOS ISO on local Linux system
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_SCRIPT="$PROJECT_ROOT/build.sh"

echo "=============================================="
echo "  NexusOS Local Build Environment"
echo "=============================================="
echo ""
echo "Project root: $PROJECT_ROOT"
echo "Build script: $BUILD_SCRIPT"
echo ""

# Check for required tools
check_tool() {
    if ! command -v "$1" &>/dev/null; then
        echo "ERROR: Required tool '$1' not found"
        MISSING_TOOLS+=("$1")
    fi
}

echo "Checking required tools..."
MISSING_TOOLS=()
REQUIRED_TOOLS=(
    "sudo" "bash" "debootstrap" "squashfs-tools" "xorriso"
    "grub-pc-bin" "grub-efi-amd64-bin" "mtools" "parted"
    "fdisk" "dosfstools" "git" "wget" "curl"
)

for tool in "${REQUIRED_TOOLS[@]}"; do
    check_tool "$tool"
done

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
    echo ""
    echo "Missing tools: ${MISSING_TOOLS[*]}"
    echo ""
    echo "On Debian/Ubuntu/Kali, install with:"
    echo "  sudo apt-get update && sudo apt-get install -y \\"
    echo "    ${REQUIRED_TOOLS[*]}"
    echo ""
    exit 1
fi

echo "All required tools present."
echo ""

# Check if running as root or has sudo
if [[ $EUID -ne 0 ]] && ! sudo -v 2>/dev/null; then
    echo "ERROR: This script requires root privileges"
    exit 1
fi

# Run the main build
echo "Starting NexusOS build..."
echo ""
echo "Build will:"
echo "  1. Setup Kali Linux repositories"
echo "  2. Bootstrap Kali base system"
echo "  3. Install desktop environment (Xfce4)"
echo "  4. Install NexusOS customizations"
echo "  5. Apply kernel optimizations"
echo "  6. Create bootable ISO"
echo ""

if [[ -f "$BUILD_SCRIPT" ]]; then
    cd "$PROJECT_ROOT"
    sudo bash "$BUILD_SCRIPT" "$@"
else
    echo "ERROR: build.sh not found at $BUILD_SCRIPT"
    exit 1
fi

echo ""
echo "=============================================="
echo "  Build Complete!"
echo "=============================================="