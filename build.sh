#!/bin/bash
###############################################################################
# NexusOS Build Script - Kali Linux Based Distribution
# Version: 12.0.0 (Aurora)
# Base: Kali Linux Rolling
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_ROOT/build"
OUT_DIR="$PROJECT_ROOT/out"
LOG_DIR="$PROJECT_ROOT/logs"

# NexusOS Version Info
NEXUS_VERSION="12.0.0"
NEXUS_CODENAME="Aurora"
NEXUS_BUILD="$(date +%Y%m%d-%H%M%S)"
ARCH="${ARCH:-amd64}"
KALI_VERSION="kali-rolling"

# ============================================================================
# COLORS
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
}

log_header() {
    echo ""
    echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}  ${WHITE}NexusOS ${NEXUS_VERSION} (${NEXUS_CODENAME}) - Kali-Based Build System${NC}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}  Build: ${NEXUS_BUILD} | Architecture: ${ARCH}${NC}"
    echo -e "${CYAN}  Base: ${KALI_VERSION}${NC}"
    echo ""
}

die() {
    log_error "$1"
    exit 1
}

# ============================================================================
# DEPENDENCY CHECKING
# ============================================================================
check_dependencies() {
    log_section "Checking Dependencies"
    
    local deps=(
        "debootstrap" "squashfs-tools" "xorriso" "grub-pc-bin" 
        "grub-efi-amd64-bin" "mtools" "parted" "fdisk" "dosfstools"
        "build-essential" "gcc" "make" "libncurses-dev" "libssl-dev"
        "python3" "python3-pip" "git" "wget" "curl" "gnupg"
        "lb" "live-build"
    )
    
    local missing=()
    for dep in "${deps[@]}"; do
        if ! dpkg -l 2>/dev/null | grep -q "^ii  $dep "; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warning "Missing packages: ${missing[*]}"
        log "Installing missing dependencies..."
        sudo apt-get update -qq
        sudo apt-get install -y -qq "${missing[@]}" 2>/dev/null || {
            log_warning "Some packages may have failed - continuing..."
        }
    fi
    
    log_success "All dependencies satisfied"
}

# ============================================================================
# KALI REPOSITORY SETUP
# ============================================================================
setup_kali_repos() {
    log_section "Configuring Kali Linux Repositories"
    
    # Add Kali archive keyring
    if [ ! -f /usr/share/keyrings/kali-archive-keyring.gpg ]; then
        log "Adding Kali archive keyring..."
        wget -q -O - https://archive.kali.org/archive-key.asc 2>/dev/null | gpg --dearmor -o /tmp/kali-archive-keyring.gpg 2>/dev/null || \
        curl -fsSL https://archive.kali.org/archive-key.asc | gpg --dearmor -o /tmp/kali-archive-keyring.gpg
        sudo mv /tmp/kali-archive-keyring.gpg /usr/share/keyrings/kali-archive-keyring.gpg
        log_success "Kali keyring added"
    else
        log "Kali keyring already present"
    fi
    
    # Add sources.list
    log "Configuring sources.list..."
    echo "# Kali Linux Rolling Repository" | sudo tee /etc/apt/sources.list.d/kali-rolling.list > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg] http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" | \
        sudo tee -a /etc/apt/sources.list.d/kali-rolling.list > /dev/null
    
    # Update package index
    log "Updating package index..."
    sudo apt-get update -qq 2>&1 | grep -v "^Get:" || true
    log_success "Repository configured"
}

# ============================================================================
# BUILD DIRECTORIES
# ============================================================================
prepare_build_dirs() {
    log_section "Preparing Build Directories"
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUT_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$BUILD_DIR/rootfs"
    mkdir -p "$BUILD_DIR/image"
    mkdir -p "$BUILD_DIR/image/boot"
    mkdir -p "$BUILD_DIR/image/boot/grub"
    
    log_success "Directories created"
    log "BUILD_DIR: $BUILD_DIR"
    log "OUT_DIR: $OUT_DIR"
    log "LOG_DIR: $LOG_DIR"
}

# ============================================================================
# INSTALL KALI BASE SYSTEM
# ============================================================================
install_kali_base() {
    log_section "Installing Kali Linux Base System"
    
    # Check if already installed
    if [ -f "$BUILD_DIR/rootfs/etc/os-release" ]; then
        log_warning "Base system already exists, skipping debootstrap"
        return 0
    fi
    
    log "Running debootstrap (this may take a while)..."
    
    sudo debootstrap --arch "$ARCH" \
        --components "main,contrib,non-free,non-free-firmware" \
        --include "kali-archive-keyring" \
        "$KALI_VERSION" \
        "$BUILD_DIR/rootfs" \
        http://http.kali.org/kali 2>&1 | tee "$LOG_DIR/debootstrap.log"
    
    if [ $? -eq 0 ]; then
        log_success "Kali base system installed"
    else
        die "Debootstrap failed - check logs"
    fi
}

# ============================================================================
# CONFIGURE BASE SYSTEM
# ============================================================================
configure_base_system() {
    log_section "Configuring Base System"
    
    # Setup Kali sources.list in chroot
    log "Setting up repositories in chroot..."
    cat << 'KALISOURCES' | sudo tee "$BUILD_DIR/rootfs/etc/apt/sources.list" > /dev/null
# Kali Linux Rolling Repository
deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg] http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
KALISOURCES
    
    # Copy Kali keyring into chroot
    sudo mkdir -p "$BUILD_DIR/rootfs/usr/share/keyrings"
    sudo cp /usr/share/keyrings/kali-archive-keyring.gpg "$BUILD_DIR/rootfs/usr/share/keyrings/" 2>/dev/null || true
    
    # Update package index in chroot
    log "Updating package index in chroot..."
    sudo chroot "$BUILD_DIR/rootfs" bash -c "apt-get update -qq 2>&1 | grep -v '^Get:'" || true
    
    # Install kernel
    log "Installing Linux kernel..."
    sudo chroot "$BUILD_DIR/rootfs" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        linux-image-amd64 \
        linux-headers-amd64 \
        firmware-linux \
        firmware-misc-nonfree \
        firmware-atheros \
        firmware-brcm80211 \
        firmware-iwlwifi \
        firmware-realtek \
        2>&1 | tail -10" || log_warning "Kernel install had issues"
    
    # Install core system packages
    log "Installing core system..."
    sudo chroot "$BUILD_DIR/rootfs" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        systemd \
        systemd-sysv \
        network-manager \
        network-manager-gnome \
        bluez \
        blueman \
        modemmanager \
        mobile-broadband-provider-info \
        udev \
        iproute2 \
        iputils-ping \
        dnsutils \
        net-tools \
        wireless-tools \
        wpasupplicant \
        rfkill \
        2>&1 | tail -10" || log_warning "Core system install had issues"
    
    # Set hostname
    echo "nexusos" | sudo tee "$BUILD_DIR/rootfs/etc/hostname" > /dev/null
    cat << 'HOSTS' | sudo tee "$BUILD_DIR/rootfs/etc/hosts" > /dev/null
127.0.0.1   localhost
127.0.1.1   nexusos
::1         localhost ip6-localhost ip6-loopback
HOSTS
    
    log_success "Base system configured"
}

# ============================================================================
# INSTALL DESKTOP ENVIRONMENT
# ============================================================================
install_desktop_environment() {
    log_section "Installing Desktop Environment"
    
    log "Installing Xfce4 desktop..."
    sudo chroot "$BUILD_DIR/rootfs" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        xfce4 \
        xfce4-goodies \
        lightdm \
        lightdm-gtk-greeter \
        2>&1 | tail -15" || log_warning "Xfce4 install had issues"
    
    log "Installing themes and icons..."
    sudo chroot "$BUILD_DIR/rootfs" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        papirus-icon-theme \
        arc-theme \
        fonts-noto \
        fonts-noto-color-emoji \
        2>&1 | tail -10" || log_warning "Themes install had issues"
    
    log_success "Desktop environment installed"
}

# ============================================================================
# INSTALL NEXUSOS PACKAGES
# ============================================================================
install_nexus_packages() {
    log_section "Installing NexusOS Packages"
    
    log "Installing utilities..."
    sudo chroot "$BUILD_DIR/rootfs" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        git \
        vim \
        nano \
        htop \
        btop \
        neofetch \
        python3 \
        python3-pip \
        python3-yaml \
        curl \
        wget \
        unzip \
        zip \
        p7zip-full \
        bash-completion \
        2>&1 | tail -10" || true
    
    log "Installing network tools..."
    sudo chroot "$BUILD_DIR/rootfs" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        nmap \
        tcpdump \
        netcat-openbsd \
        socat \
        traceroute \
        mtr \
        2>&1 | tail -10" || true
    
    log "Installing Wine for EXE compatibility..."
    sudo chroot "$BUILD_DIR/rootfs" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        wine \
        wine64 \
        winetricks \
        2>&1 | tail -10" || log_warning "Wine install had issues"
    
    log_success "NexusOS packages installed"
}

# ============================================================================
# KERNEL OPTIMIZATION
# ============================================================================
install_kernel_tweaks() {
    log_section "Applying Kernel Optimizations"
    
    # Network performance tuning
    log "Applying network tuning..."
    cat << 'SYSCTL' | sudo tee "$BUILD_DIR/rootfs/etc/sysctl.d/99-nexus.conf" > /dev/null
# NexusOS Kernel Tuning - Network Performance
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_congestion_control=htcp
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.core.netdev_max_backlog=5000
net.ipv4.tcp_max_syn_backlog=4096
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

# VM tuning
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=60
vm.dirty_background_ratio=10
vm.overcommit_memory=1

# Security
kernel.dmesg_restrict=1
kernel.kptr_restrict=1
kernel.yama.ptrace_scope=2
SYSCTL

    # Module blacklist for security/performance
    log "Applying module blacklist..."
    cat << 'MODPROBE' | sudo tee "$BUILD_DIR/rootfs/etc/modprobe.d/nexus-blacklist.conf" > /dev/null
# Disable unused modules for security and performance
blacklist floppy
blacklist pcspkr
blacklist snd_pcsp
blacklist uvcvideo
blacklist btusb
blacklist bluetooth
# Only blacklist if not needed for tethering
# blacklist usb-storage
MODPROBE

    # GPU tuning
    log "Applying GPU tuning..."
    sudo mkdir -p "$BUILD_DIR/rootfs/etc/modprobe.d"
    cat << 'GPU' | sudo tee "$BUILD_DIR/rootfs/etc/modprobe.d/nexus-gpu.conf" > /dev/null
# Intel GPU
options i915 enable_fbc=1
options i915 enable_psr=1
options i915 modeset=1

# AMD GPU
options amdgpu dc=1
options amdgpu enable_freeze_mgmt=1
options amdgpu modeset=1
GPU

    log_success "Kernel optimizations applied"
}

# ============================================================================
# NEXUSOS CUSTOM SCRIPTS
# ============================================================================
install_nexus_scripts() {
    log_section "Installing NexusOS Custom Scripts"
    
    sudo mkdir -p "$BUILD_DIR/rootfs/usr/local/bin"
    sudo mkdir -p "$BUILD_DIR/rootfs/etc/profile.d"
    
    # Main tethering detection script
    log "Installing tethering detector..."
    cat << 'TETHERDETECT' | sudo tee "$BUILD_DIR/rootfs/usr/local/bin/nexus-tethering-detect" > /dev/null
#!/bin/bash
###############################################################################
# NexusOS Advanced Tethering Detection System v2.0
# Detects USB, Bluetooth PAN, WiFi Direct, and Mobile Broadband
###############################################################################
set -euo pipefail

LOG="${LOG_FILE:-/var/log/nexus-tethering.log}"
STATE_FILE="${STATE_FILE:-/run/nexus/tethering.state}"
mkdir -p "$(dirname "$LOG")" "$(dirname "$STATE_FILE")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG"; }
log_error() { echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG"; }

echo "========================================" > "$LOG"
echo "NexusOS Tethering Detection v2.0" >> "$LOG"
echo "Time: $(date)" >> "$LOG"
echo "========================================" >> "$LOG"
echo "" >> "$LOG"

# =============================================================================
# USB TETHERING DETECTION
# =============================================================================
detect_usb_tethering() {
    log "=== USB Tethering Detection ==="
    
    local detected=0
    
    # Method 1: Check dmesg for RNDIS/CDC-ETHER devices
    if dmesg 2>/dev/null | grep -iq "rndis\|cdc_ether\|usb.*ethernet"; then
        log_success "RNDIS/CDC-Ethernet detected in dmesg"
        detected=1
    fi
    
    # Method 2: Check for USB network interfaces
    local usb_nics=$(ip -o link show 2>/dev/null | grep -i "usb" | awk -F': ' '{print $2}' || true)
    if [ -n "$usb_nics" ]; then
        log_success "USB network interface(s): $usb_nics"
        detected=1
    fi
    
    # Method 3: Check NetworkManager
    if command -v nmcli &>/dev/null; then
        local nm_devices=$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null | grep ":ethernet:connected" || true)
        if [ -n "$nm_devices" ]; then
            while IFS=: read -r dev type state; do
                # Check if it's a USB device
                if [[ -d "/sys/class/net/$dev/device" ]]; then
                    local driver=$(readlink "/sys/class/net/$dev/device/driver" 2>/dev/null || true)
                    if [[ "$driver" == *"usb"* ]]; then
                        log_success "NetworkManager USB device: $dev"
                        detected=1
                    fi
                fi
            done <<< "$nm_devices"
        fi
    fi
    
    # Method 4: Check for Android/RNDIS driver bound devices
    for dev in /sys/class/net/*; do
        local name=$(basename "$dev")
        if [[ -L "$dev/device/driver" ]]; then
            local driver=$(readlink "$dev/device/driver" 2>/dev/null || true)
            if [[ "$driver" == *"rndis"* ]] || [[ "$driver" == *"cdc_ether"* ]]; then
                log_success "RNDIS device: $name (driver: $(basename "$driver"))"
                detected=1
            fi
        fi
    done
    
    # Method 5: Check for iPhone USB tethering
    if dmesg 2>/dev/null | grep -iq "ipheth"; then
        log_success "iPhone USB tethering detected"
        detected=1
    fi
    
    if [ $detected -eq 1 ]; then
        echo "USB_TETHER=active"
        return 0
    else
        log "No USB tethering detected"
        echo "USB_TETHER=inactive"
        return 1
    fi
}

# =============================================================================
# BLUETOOTH TETHERING DETECTION (PAN/NAP)
# =============================================================================
detect_bluetooth_tethering() {
    log "=== Bluetooth Tethering Detection ==="
    
    if ! command -v bluetoothctl &>/dev/null; then
        log_warning "bluetoothctl not available"
        echo "BT_TETHER=inactive"
        return 1
    fi
    
    # Check if Bluetooth is powered on
    if ! bluetoothctl power on 2>/dev/null; then
        log_warning "Bluetooth power on failed"
        echo "BT_TETHER=inactive"
        return 1
    fi
    
    # Check rfkill status
    local bt_blocked=$(rfkill list bluetooth 2>/dev/null | grep -c "Soft blocked: yes" || echo 0)
    if [ $bt_blocked -gt 0 ]; then
        log_warning "Bluetooth is blocked by rfkill"
        rfkill unblock bluetooth 2>/dev/null || true
    fi
    
    local detected=0
    
    # Method 1: Check for BNEP interfaces (active PAN connections)
    for iface in /sys/class/net/*; do
        local name=$(basename "$iface")
        if [[ "$name" == "bnep"* ]]; then
            log_success "Active BNEP interface: $name"
            detected=1
        fi
    done
    
    # Method 2: Check paired devices and their status
    local paired=$(bluetoothctl paired-devices 2>/dev/null || true)
    if [ -n "$paired" ]; then
        while IFS= read -r line; do
            local addr=$(echo "$line" | awk '{print $2}')
            local name=$(echo "$line" | sed 's/.*\"\(.*\)\".*/\1/')
            
            # Check if connected
            if bluetoothctl info "$addr" 2>/dev/null | grep -q "Connected: yes"; then
                log_success "Connected BT device: $name ($addr)"
                detected=1
            fi
        done <<< "$paired"
    fi
    
    # Method 3: Check for PAN UUIDs in connected devices
    if command -v sdptool &>/dev/null; then
        local pan_devs=$(sdptool search PAN 2>/dev/null | grep -c "Service Name:" || echo 0)
        if [ "$pan_devs" -gt 0 ]; then
            log_success "PAN device(s) found: $pan_devs"
            detected=1
        fi
    fi
    
    if [ $detected -eq 1 ]; then
        echo "BT_TETHER=active"
        return 0
    else
        log "No active Bluetooth tethering"
        echo "BT_TETHER=inactive"
        return 1
    fi
}

# =============================================================================
# WIFI DIRECT DETECTION
# =============================================================================
detect_wifi_direct() {
    log "=== WiFi Direct Detection ==="
    
    local detected=0
    
    # Method 1: Check for ad-hoc or mesh interfaces
    if command -v iw &>/dev/null; then
        for iface in /sys/class/net/*; do
            local name=$(basename "$iface")
            if [[ -d "/sys/class/net/$name/wireless" ]]; then
                local mode=$(iw dev "$name" info 2>/dev/null | grep "type" | awk '{print $2}' || echo "managed")
                if [[ "$mode" == "adhoc" ]] || [[ "$mode" == "mesh" ]]; then
                    log_success "WiFi Direct/Ad-hoc: $name (mode: $mode)"
                    detected=1
                fi
            fi
        done
    fi
    
    # Method 2: Check for P2P interfaces (wpa_supplicant P2P)
    if [ -d /run/wpa_supplicant ]; then
        local p2p_ifaces=$(ls /run/wpa_supplicant/ 2>/dev/null | grep -E "^p2p" || true)
        if [ -n "$p2p_ifaces" ]; then
            log_success "P2P interfaces: $p2p_ifaces"
            detected=1
        fi
    fi
    
    # Method 3: Check hostapd running with AP mode
    if pgrep -x hostapd &>/dev/null; then
        log_success "hostapd running (AP mode)"
        detected=1
    fi
    
    if [ $detected -eq 1 ]; then
        echo "WIFI_DIRECT=active"
        return 0
    else
        log "No WiFi Direct detected"
        echo "WIFI_DIRECT=inactive"
        return 1
    fi
}

# =============================================================================
# MOBILE BROADBAND DETECTION
# =============================================================================
detect_mobile_broadband() {
    log "=== Mobile Broadband Detection ==="
    
    if ! command -v mmcli &>/dev/null; then
        log_warning "ModemManager (mmcli) not available"
        echo "MOBILE_BB=inactive"
        return 1
    fi
    
    # List modems
    local modems=$(mmcli -L 2>/dev/null || true)
    if [ -z "$modems" ] || echo "$modems" | grep -q "No modems"; then
        log "No modems detected"
        echo "MOBILE_BB=inactive"
        return 1
    fi
    
    log "Modem(s) found:"
    echo "$modems" | while read -r line; do
        log "  $line"
    done
    
    # Get first modem
    local modem_path=$(echo "$modems" | head -1 | grep -oP '/org/freedesktop/ModemManager1/Modem/\d+' || true)
    
    if [ -n "$modem_path" ]; then
        local status=$(mmcli -m "$modem_path" -o 2>/dev/null | grep -E "state|operator" || true)
        log "Modem status: $status"
        
        if echo "$status" | grep -qi "connected\|registered"; then
            log_success "Mobile broadband active"
            echo "MOBILE_BB=active"
            echo "MOBILE_MODEM=${modem_path##*/}"
            return 0
        fi
    fi
    
    log "Mobile broadband not connected"
    echo "MOBILE_BB=inactive"
    return 1
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    log "=========================================="
    log "  NexusOS Advanced Tethering Detection"
    log "  $(date)"
    log "=========================================="
    echo ""
    
    # Run all detection methods
    detect_usb_tethering
    echo ""
    detect_bluetooth_tethering
    echo ""
    detect_wifi_direct
    echo ""
    detect_mobile_broadband
    
    echo ""
    log "=========================================="
    log "  Detection Complete"
    log "=========================================="
    
    # Save state
    cp "$LOG" "$STATE_FILE" 2>/dev/null || true
}

main "$@"
TETHERDETECT
sudo chmod +x "$BUILD_DIR/rootfs/usr/local/bin/nexus-tethering-detect"

    # Network monitor
    log "Installing network monitor..."
    cat << 'NETMON' | sudo tee "$BUILD_DIR/rootfs/usr/local/bin/nexus-network-monitor" > /dev/null
#!/bin/bash
###############################################################################
# NexusOS Network Monitor - Advanced Network Status and Auto-Detection
###############################################################################
set -euo pipefail

STATE_DIR="/run/nexus/network"
LOG_DIR="/var/log"
mkdir -p "$STATE_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
get_primary_iface() {
    ip route show default 2>/dev/null | awk '/default/ {print $5}' | head -1
}

get_iface_type() {
    local iface="${1:-}"
    case "$iface" in
        usb*) echo "usb-tethering" ;;
        bnep*) echo "bluetooth-pan" ;;
        wlan*|wlp*) echo "wifi" ;;
        eth*|en*) echo "ethernet" ;;
        wwan*) echo "mobile-broadband" ;;
        tun*|tap*) echo "vpn-tunnel" ;;
        *) echo "unknown" ;;
    esac
}

check_connectivity() {
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        echo "online"
    else
        echo "offline"
    fi
}

get_ip() {
    local iface="${1:-}"
    ip -4 addr show "$iface" 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1 || echo "no-ip"
}

# =============================================================================
# DISPLAY FUNCTIONS
# =============================================================================
show_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}        ${GREEN}NexusOS Network Monitor${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_status() {
    local primary_iface=$(get_primary_iface)
    local conn_type=$(get_iface_type "$primary_iface")
    local status=$(check_connectivity)
    local ip=$(get_ip "$primary_iface")
    
    echo -e "${BLUE}Primary Interface:${NC} $primary_iface"
    echo -e "${BLUE}Type:${NC} $conn_type"
    echo -e "${BLUE}IP Address:${NC} $ip"
    echo -e "${BLUE}Status:${NC} $([ "$status" == "online" ] && echo -e "${GREEN}$status${NC}" || echo -e "${RED}$status${NC}")"
}

show_interfaces() {
    echo ""
    echo -e "${BLUE}=== All Network Interfaces ===${NC}"
    ip -o link show | awk -F': ' '{print $2, $(NF-2)}' | while read -r iface rest; do
        local state=$(echo "$rest" | awk '{print $1}')
        local state_color="${GREEN}"
        [[ "$state" != "UP" ]] && state_color="${YELLOW}"
        echo -e "  $iface: $(echo -e "${state_color}$state${NC}")"
    done
}

show_routes() {
    echo ""
    echo -e "${BLUE}=== Routing Table ===${NC}"
    ip route show | head -10 | sed 's/^/  /'
}

show_connections() {
    echo ""
    echo -e "${BLUE}=== Active Connections ===${NC}"
    if command -v ss &>/dev/null; then
        ss -tun | tail -n +2 | head -10 | sed 's/^/  /'
    else
        netstat -tun | tail -n +3 | head -10 | sed 's/^/  /'
    fi
}

show_tethering() {
    echo ""
    echo -e "${BLUE}=== Tethering Status ===${NC}"
    if [ -x /usr/local/bin/nexus-tethering-detect ]; then
        /usr/local/bin/nexus-tethering-detect 2>&1 | grep -E "_TETHER=|active|inactive" | sed 's/^/  /'
    else
        echo -e "  ${YELLOW}Tethering detector not available${NC}"
    fi
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    case "${1:-}" in
        --daemon)
            echo "Starting network monitor daemon..."
            while true; do
                echo "$(date): $(check_connectivity)" >> "$LOG_DIR/nexus-network.log"
                sleep 30
            done
            ;;
        --tethering)
            /usr/local/bin/nexus-tethering-detect
            ;;
        *)
            show_header
            show_status
            show_interfaces
            show_routes
            show_tethering
            echo ""
            ;;
    esac
}

main "$@"
NETMON
sudo chmod +x "$BUILD_DIR/rootfs/usr/local/bin/nexus-network-monitor"

    # Profile
    log "Installing NexusOS profile..."
    cat << 'PROFILE' | sudo tee "$BUILD_DIR/rootfs/etc/profile.d/nexusos.sh" > /dev/null
# NexusOS Environment Variables
export NEXUSOS_VERSION="${NEXUS_CODENAME:-Aurora}"
export NEXUSOS_BUILD="${NEXUS_BUILD:-unknown}"
export EDITOR=vim
export VISUAL=vim

# Aliases
alias cls='clear'
alias dir='ls -la'
alias ipconfig='ip addr'
alias tasklist='ps aux'
alias winver='cat /etc/os-release'
alias netmon='nexus-network-monitor'
alias tether='sudo /usr/local/bin/nexus-tethering-detect'
alias logs='cd /var/log && ls -lt | head -20'

# Colorful ls
alias ls='ls --color=auto'
alias ll='ls -la --color=auto'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# NexusOS welcome
echo ""
echo -e "\033[1;36m╔═══════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║\033[0m  \033[1;37mWelcome to NexusOS ${NEXUSOS_VERSION}\033[0m"
echo -e "\033[1;36m╚═══════════════════════════════════════════════════════════╝\033[0m"
echo ""
PROFILE

    log_success "NexusOS scripts installed"
}

# ============================================================================
# DISPLAY MANAGER CONFIGURATION
# ============================================================================
configure_display_manager() {
    log_section "Configuring Display Manager"
    
    sudo mkdir -p "$BUILD_DIR/rootfs/etc/lightdm"
    
    cat << 'LIGHTDM' | sudo tee "$BUILD_DIR/rootfs/etc/lightdm/lightdm-gtk-greeter.conf" > /dev/null
[greeter]
background=/usr/share/backgrounds/nexusos/nexusos-aurora.svg
theme-name=Arc-Dark
icon-theme-name=Papirus-Dark
font-name=Noto Sans 10
indicators=~host;~spacer;~clock;~spacer;~language;~session;~power
clock-format=%H:%M  •  %A, %d/%m/%Y
screensaver-timeout=60
xft-antialias=true
xft-dpi=96
xft-rgba=rgb
xft-hintstyle=hintslight
LIGHTDM

    cat << 'LIGHTDM2' | sudo tee "$BUILD_DIR/rootfs/etc/lightdm/lightdm.conf" > /dev/null
[Seat:*]
autologin-user=nexus
autologin-user-timeout=0
allow-user-switching=true
allow-guest=true
greeter-session=lightdm-gtk-greeter
session-wrapper=lightdm-session
xserver-command=X -core
LIGHTDM2

    # Enable LightDM
    sudo chroot "$BUILD_DIR/rootfs" bash -c "systemctl enable lightdm 2>/dev/null" || true
    
    log_success "Display manager configured"
}

# ============================================================================
# NETWORK SERVICES CONFIGURATION
# ============================================================================
configure_network_services() {
    log_section "Configuring Network Services"
    
    # Enable NetworkManager
    log "Enabling NetworkManager..."
    sudo chroot "$BUILD_DIR/rootfs" bash -c "systemctl enable NetworkManager 2>/dev/null" || true
    sudo chroot "$BUILD_DIR/rootfs" bash -c "systemctl enable NetworkManager-wait-online 2>/dev/null" || true
    
    # Enable Bluetooth
    log "Enabling Bluetooth..."
    sudo chroot "$BUILD_DIR/rootfs" bash -c "systemctl enable bluetooth 2>/dev/null" || true
    
    # Enable Avahi
    log "Enabling Avahi daemon..."
    sudo chroot "$BUILD_DIR/rootfs" bash -c "systemctl enable avahi-daemon 2>/dev/null" || true
    
    # Create NetworkManager dispatcher for auto-tethering detection
    sudo mkdir -p "$BUILD_DIR/rootfs/etc/NetworkManager/dispatcher.d"
    cat << 'NMDI' | sudo tee "$BUILD_DIR/rootfs/etc/NetworkManager/dispatcher.d/99-nexus-tethering" > /dev/null
#!/bin/bash
# NexusOS Tethering Auto-Detection on interface up/down
interface="$1"
action="$2"

case "$action" in
    up)
        logger "NexusOS: Interface $interface up - running tethering detection"
        /usr/local/bin/nexus-tethering-detect &>/dev/null &
        ;;
    down)
        logger "NexusOS: Interface $interface down"
        ;;
esac
NMDI
    sudo chmod +x "$BUILD_DIR/rootfs/etc/NetworkManager/dispatcher.d/99-nexus-tethering"

    log_success "Network services configured"
}

# ============================================================================
# OS IDENTITY
# ============================================================================
configure_os_identity() {
    log_section "Setting OS Identity"
    
    cat << 'OSREL' | sudo tee "$BUILD_DIR/rootfs/etc/os-release" > /dev/null
NAME="NexusOS"
VERSION="12.0.0 (Aurora)"
ID=nexusos
ID_LIKE=kali
VERSION_ID="12.0.0"
PRETTY_NAME="NexusOS Aurora"
ANSI_COLOR="1;36"
URL="https://nexusos.project"
BUG_REPORT_URL="https://github.com/nexusos-project/nexusos/issues"
PRIVACY_POLICY_URL="https://nexusos.project/privacy"
LOGO=nexus-os
VERSION_CODENAME=Aurora
OSREL

    cat << 'ISSUE' | sudo tee "$BUILD_DIR/rootfs/etc/issue" > /dev/null
NexusOS 12.0.0 (Aurora) \l

Kernel \r on \m (\n)

Last login: \n
ISSUE

    cat << 'LSBRELEASE' | sudo tee "$BUILD_DIR/rootfs/etc/lsb-release" > /dev/null
DISTRIB_ID=NexusOS
DISTRIB_RELEASE=12.0.0
DISTRIB_CODENAME=Aurora
DISTRIB_DESCRIPTION="NexusOS Aurora"
LSBRELEASE

    log_success "OS identity configured"
}

# ============================================================================
# VISUAL THEME
# ============================================================================
apply_visual_theme() {
    log_section "Applying NexusOS Visual Theme"
    
    # Create directories
    sudo mkdir -p "$BUILD_DIR/rootfs/usr/share/backgrounds/nexusos"
    sudo mkdir -p "$BUILD_DIR/rootfs/usr/share/pixmaps"
    sudo mkdir -p "$BUILD_DIR/rootfs/usr/share/icons/hicolor/256x256/apps"
    sudo mkdir -p "$BUILD_DIR/rootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml"
    sudo mkdir -p "$BUILD_DIR/rootfs/etc/skel/.config/xfce4/panel"
    
    # Xfce4 window manager config
    cat << 'XFWM4' | sudo tee "$BUILD_DIR/rootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" > /dev/null
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Arc-Dark"/>
    <property name="title_font" type="string" value="Noto Sans SemiBold 10"/>
    <property name="button_layout" type="string" value="O|HMC"/>
    <property name="use_compositing" type="bool" value="true"/>
    <property name="frame_opacity" type="int" value="95"/>
    <property name="inactive_opacity" type="int" value="90"/>
    <property name="move_opacity" type="int" value="85"/>
    <property name="resize_opacity" type="int" value="85"/>
    <property name="shadow_delta_height" type="int" value="3"/>
    <property name="shadow_delta_width" type="int" value="0"/>
    <property name="shadow_delta_x" type="int" value="0"/>
    <property name="shadow_delta_y" type="int" value="2"/>
    <property name="snap_to_windows" type="bool" value="true"/>
    <property name="snap_width" type="int" value="10"/>
  </property>
</channel>
XFWM4

    # Xfce4 desktop config
    cat << 'XFDESK' | sudo tee "$BUILD_DIR/rootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" > /dev/null
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="image-path" type="string" value="/usr/share/backgrounds/nexusos/nexusos-aurora.svg"/>
        <property name="image-style" type="int" value="5"/>
      </property>
    </property>
  </property>
</channel>
XFDESK

    # Panel config
    cat << 'XPANEL' | sudo tee "$BUILD_DIR/rootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" > /dev/null
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int">1</value>
  </property>
  <property name="panel-1" type="empty">
    <property name="position" type="string" value="p=6;x=620;y=0"/>
    <property name="size" type="string" value="40"/>
    <property name="length" type="int">100</property>
    <property name="position-force" type="bool" value="true"/>
  </property>
</channel>
XPANEL

    log_success "Visual theme applied"
}

# ============================================================================
# CLEANUP
# ============================================================================
cleanup_build() {
    log_section "Cleaning Up Build System"
    
    log "Cleaning apt cache..."
    sudo chroot "$BUILD_DIR/rootfs" bash -c "apt-get clean" 2>/dev/null || true
    sudo chroot "$BUILD_DIR/rootfs" bash -c "apt-get autoclean" 2>/dev/null || true
    sudo chroot "$BUILD_DIR/rootfs" bash -c "apt-get autoremove -y" 2>/dev/null || true
    
    log "Removing documentation..."
    sudo chroot "$BUILD_DIR/rootfs" bash -c "rm -rf /usr/share/doc/*" 2>/dev/null || true
    sudo chroot "$BUILD_DIR/rootfs" bash -c "rm -rf /usr/share/man/*" 2>/dev/null || true
    sudo chroot "$BUILD_DIR/rootfs" bash -c "rm -rf /usr/share/info/*" 2>/dev/null || true
    
    log "Clearing logs..."
    sudo rm -rf "$BUILD_DIR/rootfs/var/log/"* 2>/dev/null || true
    sudo mkdir -p "$BUILD_DIR/rootfs/var/log"
    
    log_success "Cleanup complete"
}

# ============================================================================
# CREATE FILESYSTEM IMAGES
# ============================================================================
create_squashfs() {
    log_section "Creating SquashFS Image"
    
    # Verify rootfs exists and has content
    if [ ! -d "$BUILD_DIR/rootfs" ]; then
        die "Rootfs directory not found: $BUILD_DIR/rootfs"
    fi
    
    local rootfs_files=$(sudo find "$BUILD_DIR/rootfs" -type f 2>/dev/null | wc -l)
    log "Rootfs contains $rootfs_files files"
    
    if [ "$rootfs_files" -lt 100 ]; then
        die "Rootfs appears incomplete (only $rootfs_files files) - check apt-get logs"
    fi
    
    # Check if kernel exists in rootfs
    if [ -d "$BUILD_DIR/rootfs/boot" ]; then
        log "Boot contents: $(ls "$BUILD_DIR/rootfs/boot/" 2>/dev/null | tr '\n' ' ')"
    else
        log_warning "No /boot directory in rootfs - kernel may not be installed"
    fi
    
    log "Compressing root filesystem..."
    sudo mksquashfs "$BUILD_DIR/rootfs" \
        "$BUILD_DIR/image/squashfs" \
        -comp xz \
        -b 1M \
        -no-xattrs \
        -no-exports \
        2>&1 | tee "$LOG_DIR/squashfs.log" | tail -10
    
    if [ -f "$BUILD_DIR/image/squashfs" ]; then
        log_success "SquashFS created: $(du -h "$BUILD_DIR/image/squashfs" | cut -f1)"
    else
        die "SquashFS creation failed"
    fi
}

create_boot_image() {
    log_section "Creating Boot Image"
    
    # Check if kernel exists in rootfs
    if [ ! -d "$BUILD_DIR/rootfs/boot" ]; then
        log_error "No /boot directory in rootfs!"
        log "Attempting to install kernel..."
        sudo chroot "$BUILD_DIR/rootfs" bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y linux-image-amd64" 2>/dev/null || true
    fi
    
    # List available kernels
    log "Available kernels in rootfs/boot:"
    sudo ls -la "$BUILD_DIR/rootfs/boot/" 2>/dev/null || true
    
    # Copy kernel and initrd
    if [ -d "$BUILD_DIR/rootfs/boot" ]; then
        log "Copying kernel and initrd..."
        sudo cp "$BUILD_DIR/rootfs/boot/"* "$BUILD_DIR/image/boot/" 2>/dev/null || true
        
        # Verify files were copied
        local copied=$(sudo ls "$BUILD_DIR/image/boot/" 2>/dev/null | wc -l)
        log "Copied $copied files to image/boot/"
        
        if [ "$copied" -eq 0 ]; then
            log_warning "No kernel/initrd copied - ISO may not be bootable"
        fi
    else
        log_warning "No /boot directory - ISO will not be bootable"
    fi
    
    # Create live boot config
    cat << 'GRUB' | sudo tee "$BUILD_DIR/image/boot/grub/grub.cfg" > /dev/null
# NexusOS Boot Configuration

set default=0
set timeout=5

menuentry "NexusOS Aurora - Live Mode" {
    search --no-floppy --label --set=root NexusOS
    linux /boot/vmlinuz boot=live components splash quiet
    initrd /boot/initrd.img
}

menuentry "NexusOS Aurora - Safe Mode" {
    search --no-floppy --label --set=root NexusOS
    linux /boot/vmlinuz boot=live components splash acpi=off
    initrd /boot/initrd.img
}

menuentry "NexusOS Aurora - Recovery" {
    search --no-floppy --label --set=root NexusOS
    linux /boot/vmlinuz boot=live components single
    initrd /boot/initrd.img
}
GRUB

    log_success "Boot image created"
}

# ============================================================================
# CREATE ISO
# ============================================================================
create_iso() {
    log_section "Creating ISO Image"
    
    # Ensure output directory exists
    sudo mkdir -p "$OUT_DIR"
    
    ISO_NAME="NexusOS-${NEXUS_VERSION}-${NEXUS_CODENAME}-${ARCH}-${NEXUS_BUILD}.iso"
    ISO_PATH="$OUT_DIR/$ISO_NAME"
    
    log "ISO will be created at: $ISO_PATH"
    log "OUT_DIR contents before ISO creation:"
    sudo ls -lah "$OUT_DIR/" 2>/dev/null || echo "OUT_DIR empty or missing"
    
    # Find isohdpfx.bin (different distros place it differently)
    ISOHDPFX=""
    for path in /usr/lib/ISOLINUX/isohdpfx.bin /usr/lib/syslinux/isohdpfx.bin /usr/share/syslinux/isohdpfx.bin; do
        if [ -f "$path" ]; then
            ISOHDPFX="$path"
            log "Found isohdpfx.bin at: $path"
            break
        fi
    done
    
    if [ -z "$ISOHDPFX" ]; then
        log "WARNING: isohdpfx.bin not found, trying to install isolinux..."
        sudo apt-get install -y isolinux 2>/dev/null || true
        for path in /usr/lib/ISOLINUX/isohdpfx.bin /usr/lib/syslinux/isohdpfx.bin /usr/share/syslinux/isohdpfx.bin; do
            if [ -f "$path" ]; then
                ISOHDPFX="$path"
                log "Found isohdpfx.bin after install at: $path"
                break
            fi
        done
    fi
    
    if [ -z "$ISOHDPFX" ]; then
        die "isohdpfx.bin not found - cannot create ISO"
    fi
    
    # Verify image directory exists and has content
    if [ ! -d "$BUILD_DIR/image" ]; then
        die "Build image directory not found: $BUILD_DIR/image"
    fi
    
    local image_files
    image_files=$(sudo find "$BUILD_DIR/image" -type f 2>/dev/null | wc -l)
    log "Image directory contains $image_files files"
    
    if [ "$image_files" -eq 0 ]; then
        die "Image directory is empty - build incomplete"
    fi
    
    # Show image directory contents
    log "Image directory structure:"
    sudo find "$BUILD_DIR/image" -type f 2>/dev/null | head -20
    
    log "Building ISO: $ISO_NAME"
    log "Using boot sector: $ISOHDPFX"
    
    # Run xorriso and capture all output
    set +e  # Temporarily disable exit on error for xorriso
    sudo xorriso -as mkisofs \
        -r \
        -J \
        -joliet-long \
        -isohybrid-mbr "$ISOHDPFX" \
        -partition_offset 16 \
        -V "NexusOS" \
        -A "NexusOS ${NEXUS_VERSION} (${NEXUS_CODENAME})" \
        -publisher "NexusOS Project" \
        -p "Built on Kali Linux" \
        -o "$ISO_PATH" \
        "$BUILD_DIR/image" 2>&1 | tee "$LOG_DIR/xorriso.log"
    local xorriso_status=${PIPESTATUS[0]}
    set -e  # Re-enable exit on error
    
    log "xorriso exit status: $xorriso_status"
    
    if [ $xorriso_status -ne 0 ]; then
        log_error "xorriso failed with exit code $xorriso_status"
        log "xorriso log contents:"
        cat "$LOG_DIR/xorriso.log" | tail -30
        die "xorriso failed - check logs/xorriso.log"
    fi
    
    # Check if ISO was created
    if [ -f "$ISO_PATH" ]; then
        log_success "ISO created successfully!"
        log "Location: $ISO_PATH"
        log "Size: $(du -h "$ISO_PATH" | cut -f1)"
        
        # Verify ISO is valid
        log "Verifying ISO..."
        xorriso --no-pvd_offset_check -indev "$ISO_PATH" -report_el_torito 2>&1 | head -10 || true
        
        # Create checksums
        cd "$OUT_DIR"
        sha256sum "$ISO_NAME" > "${ISO_NAME}.sha256"
        md5sum "$ISO_NAME" > "${ISO_NAME}.md5"
        
        log_success "Checksums created"
        log ""
        log "=========================================="
        log "  Build Complete!"
        log "=========================================="
        log ""
        log "ISO: $ISO_NAME"
        log "SHA256: ${ISO_NAME}.sha256"
    else
        log_error "ISO file not found at: $ISO_PATH"
        log_error "OUT_DIR contents:"
        ls -lah "$OUT_DIR/"
        die "ISO creation failed - check logs/xorriso.log"
    fi
}

# ============================================================================
# MAIN BUILD PROCESS
# ============================================================================
main() {
    log_header
    
    log_section "Starting NexusOS Build Process"
    
    log "Phase 1: Setup"
    check_dependencies
    setup_kali_repos
    prepare_build_dirs
    
    log "Phase 2: Base System"
    install_kali_base
    configure_base_system
    
    log "Phase 3: Desktop"
    install_desktop_environment
    install_nexus_packages
    
    log "Phase 4: Customization"
    install_kernel_tweaks
    install_nexus_scripts
    configure_display_manager
    configure_network_services
    configure_os_identity
    apply_visual_theme
    
    log "Phase 5: Finalization"
    cleanup_build
    create_squashfs
    create_boot_image
    create_iso
    
    log_section "BUILD COMPLETE!"
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${WHITE}NexusOS ${NEXUS_VERSION} (${NEXUS_CODENAME}) build complete!${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    ls -lh "$OUT_DIR"/*.iso 2>/dev/null || ls -lh "$OUT_DIR/"
}

# Handle command line arguments
case "${1:-}" in
    clean)
        log_section "Cleaning Build"
        rm -rf "$BUILD_DIR" "$OUT_DIR"/*.iso "$LOG_DIR"
        log_success "Cleaned"
        ;;
    deps)
        check_dependencies
        setup_kali_repos
        log_success "Dependencies ready"
        ;;
    shell)
        log "Dropping to shell in chroot..."
        sudo chroot "$BUILD_DIR/rootfs" /bin/bash
        ;;
    *)
        main
        ;;
esac