# Asus Router WireGuard VPN Server Setup

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Tested](https://img.shields.io/badge/Tested-RT--AC86U-success.svg)](https://github.com/smk422/asus-wireguard-setup)

Complete, battle-tested guide for setting up a WireGuard VPN server on Asus routers with Merlin firmware and Entware.

**What makes this guide different:**
- ✅ Verified through actual troubleshooting sessions
- ✅ Documents real-world issues and their solutions
- ✅ Includes auto-start configuration that actually works
- ✅ Step-by-step fixes for common problems
- ✅ Complete post-mount script with all necessary fixes

## Why This Guide Exists

Most WireGuard guides for Asus routers skip critical details or assume everything works perfectly. This guide was created from a real setup session where we encountered and solved multiple real-world issues:
- Missing `wg-quick` command (requires `wireguard-go` package)
- Services failing to start after reboot
- TUN device permission problems
- Config symlink issues with WireGuard UI
- Kernel module limitations

Every solution here has been tested and verified to work.

## Quick Start

**Hardware tested:**
- Asus RT-AC86U (aarch64) with ASUSWRT-Merlin 386.14_2
- Also compatible: RT-AX88U, RT-AC68U, other ARMv7/ARMv8 routers

**Prerequisites:**
- Asus router with Merlin firmware (or stock with SSH)
- USB stick formatted as ext4
- 30-60 minutes

**Installation:**
1. Follow the [complete setup guide](./asus-wireguard-setup.md)
2. Use scripts from [`scripts/`](./scripts/) directory
3. Refer to [Quick Fix Reference](#quick-fixes) when troubleshooting

## Critical Notes Before Starting

⚠️ **Must install BOTH packages:** `wireguard-tools` AND `wireguard-go` (tools alone is incomplete)

⚠️ **Auto-start requires work:** Use the provided post-mount script - it handles multiple initialization tasks

⚠️ **Kernel support varies:** Some routers lack WireGuard kernel module - check VPN section for native support first

## What's Included

### 📖 Documentation
- **[Complete Setup Guide](./asus-wireguard-setup.md)** - Step-by-step instructions with explanations
- **8 Real-World Issues** - Documented with symptoms, causes, and solutions
- **Quick Fix Reference** - 10-step troubleshooting checklist

### 🔧 Scripts
All scripts in [`scripts/`](./scripts/) directory:
- **`post-mount.sh`** - Auto-start script for `/jffs/scripts/post-mount`
  - Loads TUN module
  - Fixes /dev/net/tun permissions
  - Creates config symlinks
  - Starts all Entware services

- **`S50wireguard`** - WireGuard interface init script for `/opt/etc/init.d/`

- **`S51wireguard-ui`** - WireGuard UI web interface init script for `/opt/etc/init.d/`

## Features

- 🔒 **Secure VPN Server** - WireGuard protocol with full encryption
- 🌐 **Web Management** - WireGuard UI for easy client management
- 📱 **QR Code Generation** - Quick mobile device setup
- 🔄 **Auto-Start** - Survives router reboots with proper configuration
- 🛠️ **Troubleshooting** - Comprehensive checklist for common issues

## Quick Fixes

### WireGuard UI won't start after reboot
```bash
mkdir -p /etc/wireguard
ln -sf /opt/etc/wireguard/wg0.conf /etc/wireguard/wg0.conf
cd /opt/etc/wireguard && ./wireguard-ui --bind-address 0.0.0.0:5000 &
```

### WireGuard interface won't start
```bash
modprobe tun
chmod 666 /dev/net/tun
wg-quick up wg0
```

### Missing wg-quick command
```bash
opkg install wireguard-go
```

See [full troubleshooting checklist](./asus-wireguard-setup.md#quick-fix-reference-troubleshooting-checklist) in the guide.

## Installation Overview

1. **Prepare USB** - Format as ext4, mount on router
2. **Install Entware** - Package manager for Asus routers
3. **Install WireGuard** - Both `wireguard-tools` and `wireguard-go`
4. **Configure Server** - Generate keys, create config
5. **Install UI** - Web interface for management
6. **Auto-Start** - Deploy post-mount script
7. **Test** - Connect client and verify

See [complete guide](./asus-wireguard-setup.md) for detailed instructions.

## Common Issues Covered

| Issue | What Happens | Solution |
|-------|--------------|----------|
| Missing wg-quick | `/opt/bin/wg-quick: not found` | Install wireguard-go package |
| TUN device error | "Failed to create TUN device" | Load tun module, fix permissions |
| UI can't find config | "no such file or directory" | Create symlink to /etc/wireguard |
| No auto-start | Services dead after reboot | Use provided post-mount script |
| USB symlink wrong | /opt points to wrong path | Remount rw, update symlink |
| opkg not found | PATH doesn't include /opt/bin | Add to PATH and ~/.profile |
| No kernel module | "Protocol not supported" | Check for native Merlin support |
| Old USB replacement | Entware points to dead drive | Fix symlink to new USB mount |

Full details in [Common Issues section](./asus-wireguard-setup.md#common-issues-during-setup-real-experience---march-2026).

## Documentation Structure

```
asus-wireguard-setup/
├── README.md                    (this file - overview)
├── asus-wireguard-setup.md      (complete step-by-step guide)
├── LICENSE                      (MIT)
├── scripts/
│   ├── post-mount.sh           (auto-start script)
│   ├── S50wireguard            (WireGuard init)
│   └── S51wireguard-ui         (UI init)
```

## Contributing

Found an issue or have an improvement? Contributions welcome!

1. Test your fix on actual hardware
2. Document the problem and solution clearly
3. Submit a pull request with detailed description

## Credits

- **WireGuard** - Jason A. Donenfeld and the WireGuard team
- **WireGuard UI** - [ngoduykhanh/wireguard-ui](https://github.com/ngoduykhanh/wireguard-ui)
- **Entware** - [Entware project](https://github.com/Entware/Entware)
- **ASUSWRT-Merlin** - [RMerl](https://github.com/RMerl/asuswrt-merlin.ng)

## Acknowledgments

This guide was created with assistance from **GitHub Copilot** (Claude Sonnet 4.5) during a real late-night troubleshooting session. Every issue, solution, and fix documented here comes from actual hardware testing and problem-solving on a live router setup.

## Support

- 📖 Read the [complete guide](./asus-wireguard-setup.md) first
- 🔍 Check [Common Issues](./asus-wireguard-setup.md#common-issues-during-setup-real-experience---march-2026)
- ✅ Use [Quick Fix Checklist](./asus-wireguard-setup.md#quick-fix-reference-troubleshooting-checklist)
- 🐛 Open an [issue](https://github.com/smk422/asus-wireguard-setup/issues) if problem persists

## License

MIT License - See [LICENSE](./LICENSE) file for details.

---

**Tested:** March 11, 2026 | **Hardware:** RT-AC86U (aarch64) | **Firmware:** Merlin 386.14_2
**Status:** Power-cycle tested and working ✅
**Created with:** Real hardware + GitHub Copilot collaboration
