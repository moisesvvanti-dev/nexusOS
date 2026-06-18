# NexusOS Aurora - Kali-Based Linux Distribution

## 🌟 Overview

**NexusOS Aurora** is a Kali-based Linux distribution designed for security professionals, researchers, and power users who need advanced networking capabilities, modern aesthetics, and seamless mobile tethering integration.

Built on top of Kali Linux Rolling, NexusOS combines the security tooling excellence of Kali with a refined, modern desktop experience and proprietary enhancements.

---

## 🔑 Key Features

### 📡 Advanced Tethering Detection

NexusOS includes a sophisticated tethering detection system that automatically identifies:

- **USB Tethering** - Detects RNDIS/CDC-ETHER devices, Android USB tethering, iPhone USB tethering
- **Bluetooth PAN/NAP** - Monitors for Bluetooth personal area network connections
- **WiFi Direct** - Detects ad-hoc and P2P connections
- **Mobile Broadband** - ModemManager integration for 4G/5G modems

The tethering detector runs automatically on network interface changes and provides detailed logging at `/var/log/nexus-tethering.log`.

### 🛡️ Kali Linux Foundation

- **Full Kali Repository Access** - All security and penetration testing tools
- **Rolling Updates** - Always up-to-date with latest Kali packages
- **Kernel Optimization** - Network performance tuning and security hardening
- **Hardware Support** - Broad driver support including WiFi, Bluetooth, and mobile broadband

### 🎨 Modern Prism UI

- **Animated Aurora Background** - Dynamic SVG wallpaper with color-shifting prism effect
- **Arc-Dark Theme** - Consistent dark theme across all applications
- **Papirus Icons** - Modern icon set with NexusOS custom icons
- **Xfce4 Desktop** - Lightweight, fast, and highly customizable

### ⚡ Performance Optimizations

```
# Network tuning applied automatically:
- TCP Window Scaling: Enabled
- HTCP Congestion Control
- Increased buffer sizes (16MB)
- IP Forwarding optimized
- VM tuning (swappiness=10)

# GPU acceleration:
- Intel: FBC, PSR enabled
- AMD: DC enabled, FreeSync
```

### 🔧 Development Ready

- Python 3 with pip and virtualenv
- GCC, Make, CMake for C/C++ development
- Git for version control
- Docker support (when installed)

---

## 🖥️ System Requirements

### Minimum
- 64-bit x86 processor
- 2 GB RAM
- 20 GB disk space
- USB boot support

### Recommended
- 4+ GB RAM for heavy security tools
- 40+ GB SSD for tool installations
- WiFi adapter (for wireless testing)
- Mobile device for tethering tests

---

## 📦 Package Highlights

### Desktop & UI
- Xfce4 with custom NexusOS theme
- LightDM with aurora greeter
- Papirus icon theme
- Arc-Dark GTK theme

### Network Tools
- NetworkManager + ModemManager
- Bluetooth (BlueZ + Blueman)
- iproute2, nmap, wireshark
- Advanced tethering auto-detection

### Security (Kali)
- aircrack-ng suite
- metasploit-framework
- Burp Suite Community
- OWASP ZAP

### Development
- GCC 10+, Make, CMake
- Python 3.10+
- Git, VS Code compatible

---

## 🔧 Installation

### Build from Source

```bash
# Clone the repository
git clone https://github.com/nexusos-project/nexusos.git
cd nexusos

# Install dependencies (Debian/Ubuntu/Kali)
sudo apt-get update
sudo apt-get install -y debootstrap squashfs-tools xorriso grub-pc-bin

# Run the build
chmod +x build.sh
sudo ./build.sh
```

### GitHub Actions (Automated Build)

Push to main branch or use workflow_dispatch:
- Workflow: `.github/workflows/build-nexus-kali.yml`
- Produces: `NexusOS-{version}-{arch}.iso`

### USB Installation

```bash
# Find your USB device
lsblk

# Write ISO to USB (replace X with your device)
sudo dd if=out/NexusOS-*.iso of=/dev/sdX bs=4M status=progress
sudo sync
```

---

## 🖥️ Network & Tethering Usage

### Automatic Tethering Detection

Tethering is detected automatically when:
- USB cable with tethering enabled
- Bluetooth PAN connection established
- WiFi Direct/Ad-hoc mode activated
- Mobile broadband modem connects

### Manual Detection

```bash
# Full tethering report
sudo nexus-tethering-detect

# Network status
nexus-network-monitor

# Specific checks
nexus-tethering-detect | grep USB
nexus-tethering-detect | grep BT
```

### Logs

```bash
# View tethering detection logs
cat /var/log/nexus-tethering.log

# Monitor network in real-time
tail -f /var/log/nexus-tethering.log

# Network state
cat /run/nexus/tethering.state
```

---

## 🎯 Customization

### Adding Kali Tools

```bash
sudo apt-get update
sudo apt-get install -y <tool-name>
```

### Custom Kernel Parameters

Edit `/etc/sysctl.d/99-nexus.conf` and run:
```bash
sudo sysctl -p /etc/sysctl.d/99-nexus.conf
```

### Theme Customization

Desktop settings stored in:
- `/etc/skel/.config/` - Default user config
- `~/.config/` - User overrides

---

## 🏗️ Architecture

```
nexusOS/
├── build.sh              # Main build script
├── .github/
│   └── workflows/
│       └── build-nexus-kali.yml    # CI/CD pipeline
├── config/
│   ├── archives/         # APT repo configs
│   ├── hooks/            # live-build hooks
│   ├── includes.chroot/  # Files to include in ISO
│   │   ├── etc/          # System config
│   │   │   ├── profile.d/
│   │   │   ├── lightdm/
│   │   │   └── systemd/
│   │   └── usr/
│   │       ├── local/bin/  # Nexus scripts
│   │       └── share/      # Themes, icons
│   └── package-lists/   # Package definitions
└── out/                  # Build output
```

---

## 📋 Build Output

After build completes:
```
out/
├── NexusOS-12.0.0-Aurora-amd64-{date}.iso
├── NexusOS-12.0.0-Aurora-amd64-{date}.iso.sha256
└── NexusOS-12.0.0-Aurora-amd64-{date}.iso.md5
```

---

## 🔒 Security Notes

- Kali tools require proper authorization
- Network monitoring is logged
- Tethering detection can be disabled
- Root access is standard (sudo)

---

## 📄 License

See LICENSE files in repository.

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Submit pull request

---

## 🔗 Links

- **Website**: https://nexusos.project
- **Documentation**: https://docs.nexusos.project
- **Issues**: https://github.com/nexusos-project/nexusos/issues
- **Kali Linux**: https://kali.org

---

> *"Security • Privacy • Performance • Tethering Detection"* — **NexusOS Aurora**