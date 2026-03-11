# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-03-11

### Added
- Initial release of complete WireGuard setup guide
- Step-by-step installation instructions
- 8 documented real-world issues with solutions:
  1. Old USB symlink after USB stick failure
  2. WireGuard UI can't find config file
  3. opkg command not found after Entware install
  4. kmod-wireguard not available
  5. Services don't start after reboot
  6. Missing wg-quick command
  7. Missing /dev/net/tun device
  8. WireGuard interface won't start (kernel module)
- Post-mount script with comprehensive fixes
- WireGuard interface init script (S50wireguard)
- WireGuard UI init script (S51wireguard-ui)
- Quick Fix Reference troubleshooting checklist
- Security notes and best practices
- Backup and DDNS configuration guides

### Tested
- Asus RT-AC86U (aarch64 architecture)
- ASUSWRT-Merlin 386.14_2
- Power cycle testing verified
- Auto-start functionality confirmed

### Documentation
- Complete setup guide (asus-wireguard-setup.md)
- GitHub README with quick start
- MIT License
- Script documentation and usage notes
