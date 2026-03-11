#!/bin/sh
#
# Asus Router Post-Mount Script for WireGuard + Entware
# Place this file at: /jffs/scripts/post-mount
# Make executable: chmod +x /jffs/scripts/post-mount
# Enable custom scripts: nvram set jffs2_scripts=1 && nvram commit
#
# This script runs after USB storage mounts and ensures:
# - TUN kernel module is loaded
# - WireGuard can access /dev/net/tun
# - Config symlink is recreated (required by WireGuard UI)
# - All Entware services start automatically
#

# Wait for USB to fully mount
sleep 10

# Load TUN kernel module (required for WireGuard)
modprobe tun 2>/dev/null

# Fix /dev/net/tun permissions (WireGuard needs read/write access)
chmod 666 /dev/net/tun 2>/dev/null

# Create symlink for WireGuard UI (gets wiped on reboot)
mkdir -p /etc/wireguard
ln -sf /opt/etc/wireguard/wg0.conf /etc/wireguard/wg0.conf

# Start all Entware init scripts
if [ -d /opt/etc/init.d ]; then
    for script in /opt/etc/init.d/S??*; do
        [ -x "$script" ] && $script start
    done
fi
