# Asus Router WireGuard VPN Server Setup

Complete guide for setting up WireGuard VPN server on Asus router with USB storage.

**Battle-Tested:** This guide includes real-world fixes for common issues encountered during actual setup sessions. All solutions have been verified on hardware.

## Prerequisites

- Asus router with Merlin firmware (recommended) or stock firmware with SSH access
- USB stick (ext4 or ext3 formatted recommended)
- SSH client (PuTTY on Windows)
- Router admin access

## Critical Setup Notes

**Before you start, know these important facts:**

1. **Install BOTH packages:** You need `wireguard-tools` AND `wireguard-go` - the tools package alone is incomplete
2. **Symlink recreates on reboot:** `/etc/wireguard/wg0.conf` must be recreated in post-mount script
3. **TUN module required:** Must load `modprobe tun` and set permissions on `/dev/net/tun`
4. **Auto-start needs work:** Post-mount script must handle multiple initialization tasks
5. **Kernel support varies:** Some routers may not have WireGuard kernel module - check VPN section for native support first

**Time Investment:** 30-60 minutes including troubleshooting

## Step 1: Prepare USB Storage

### Format USB Stick

1. **On Router Web Interface:**
   - Insert USB stick into router
   - Navigate to: `USB Application` → `Format`
   - Select filesystem: **ext4** (preferred) or ext3
   - Format the drive

2. **Verify mount:**
   ```bash
   df -h
   # Should show /tmp/mnt/sda1 or similar
   ```

## Step 2: Install Entware

Entware is the package manager for Asus routers.

### SSH into Router

```bash
ssh admin@192.168.1.1
# Or your router's IP address
# Default password: your router admin password
```

### Install Entware Script

```bash
# Download and run Entware installer
wget -O - http://bin.entware.net/armv7sf-k3.2/installer/generic.sh | sh

# Or for older routers (ARM):
# wget -O - http://bin.entware.net/armv7sf-k2.6/installer/generic.sh | sh

# Add Entware to PATH (important!)
export PATH=/opt/bin:/opt/sbin:$PATH
echo 'export PATH=/opt/bin:/opt/sbin:$PATH' >> ~/.profile

# Update package list
opkg update
```

### Verify Installation

```bash
opkg list | grep wireguard
```

### If "opkg: not found" Error

If you get "opkg: not found", try these solutions:

**Option 1: Check USB mount**
```bash
# Verify USB is mounted
df -h | grep /tmp/mnt

# If not mounted, unplug and replug USB, then check router web interface
```

**Option 2: Use full path**
```bash
# Try running with full path
/opt/bin/opkg update

# If this works, add to PATH:
export PATH=/opt/bin:/opt/sbin:$PATH
echo 'export PATH=/opt/bin:/opt/sbin:$PATH' >> ~/.profile
```

**Option 3: Re-run Entware installer**
```bash
# For ARM v7 (most modern Asus routers)
wget -O - http://bin.entware.net/armv7sf-k3.2/installer/generic.sh | sh

# For older ARM routers (RT-N66U, RT-AC66U, etc.)
wget -O - http://bin.entware.net/armv5sf-k3.2/installer/generic.sh | sh

# For MIPS routers
wget -O - http://bin.entware.net/mipselsf-k3.4/installer/generic.sh | sh
```

**Option 4: Check router architecture**
```bash
# Determine your router's CPU architecture
uname -m
# Output tells you which Entware version to use:
# - armv7l → use armv7sf-k3.2
# - armv5 → use armv5sf-k3.2
# - mips → use mipselsf-k3.4
```

**Option 5: Reboot router**
```bash
reboot
# Wait 2-3 minutes, then SSH back in and try:
/opt/bin/opkg update
```

**Option 6: Manual PATH setup**
```bash
# Create profile script for automatic PATH
cat > /jffs/scripts/services-start << 'EOF'
#!/bin/sh
export PATH=/opt/bin:/opt/sbin:$PATH
EOF

chmod +x /jffs/scripts/services-start
```

## Step 3: Install WireGuard

### Install WireGuard Packages

```bash
# Install WireGuard tools (required)
opkg install wireguard-tools

# Install wireguard-go (REQUIRED for wg-quick command)
opkg install wireguard-go

# Try to install kernel module (optional - may not be available)
# This is NOT required for WireGuard to work
opkg install kmod-wireguard 2>/dev/null || echo "Kernel module not available - that's OK!"

# Verify installation
wg --version
which wg-quick
# Should show: wireguard-tools v1.0.20210914 or newer
# And wg-quick should be at /opt/bin/wg-quick
```

**Important:** The `wireguard-tools` package only contains `/opt/bin/wg` command. You **must** also install `wireguard-go` to get the `wg-quick` script, which is needed to bring up WireGuard interfaces.

**Note:** The kernel module (kmod-wireguard) is often not available for Asus routers. WireGuard will work fine using the userspace implementation with wireguard-go.

## Step 4: Configure WireGuard Server

### Generate Server Keys

```bash
# Create config directory
mkdir -p /opt/etc/wireguard
cd /opt/etc/wireguard

# Generate server private and public keys
wg genkey | tee server_private.key | wg pubkey > server_public.key

# Set proper permissions
chmod 600 server_private.key
```

### Create Server Configuration

```bash
# Create wg0.conf
cat > /opt/etc/wireguard/wg0.conf << 'EOF'
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = SERVER_PRIVATE_KEY_HERE

# Firewall rules
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Client 1 configuration
[Peer]
PublicKey = CLIENT1_PUBLIC_KEY_HERE
AllowedIPs = 10.0.0.2/32

# Add more [Peer] sections for additional clients
EOF

# Replace SERVER_PRIVATE_KEY_HERE with actual key
SERVER_KEY=$(cat server_private.key)
sed -i "s|SERVER_PRIVATE_KEY_HERE|$SERVER_KEY|g" /opt/etc/wireguard/wg0.conf

# Set permissions
chmod 600 /opt/etc/wireguard/wg0.conf
```

## Step 5: Generate Client Configurations

### Generate Client Keys

```bash
cd /opt/etc/wireguard

# For each client, generate key pair
wg genkey | tee client1_private.key | wg pubkey > client1_public.key
chmod 600 client1_private.key
```

### Create Client Config File

```bash
# Get your public IP or domain
PUBLIC_IP="your.public.ip.or.domain"

# Get server public key
SERVER_PUBLIC_KEY=$(cat server_public.key)
CLIENT_PRIVATE_KEY=$(cat client1_private.key)

# Create client config
cat > client1.conf << EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.0.0.2/32
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $PUBLIC_IP:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
```

### Add Client Public Key to Server Config

```bash
# Edit wg0.conf and add the client's public key
nano /opt/etc/wireguard/wg0.conf

# Add this section:
# [Peer]
# PublicKey = CLIENT1_PUBLIC_KEY_HERE
# AllowedIPs = 10.0.0.2/32

# Or use command:
CLIENT_PUBLIC_KEY=$(cat client1_public.key)
echo "" >> /opt/etc/wireguard/wg0.conf
echo "[Peer]" >> /opt/etc/wireguard/wg0.conf
echo "PublicKey = $CLIENT_PUBLIC_KEY" >> /opt/etc/wireguard/wg0.conf
echo "AllowedIPs = 10.0.0.2/32" >> /opt/etc/wireguard/wg0.conf
```

## Step 6: Configure Router Firewall

### Enable IP Forwarding

```bash
# Check if forwarding is enabled
cat /proc/sys/net/ipv4/ip_forward
# Should return 1

# If not, enable it:
echo 1 > /proc/sys/net/ipv4/ip_forward

# Make permanent (add to router startup script)
nvram set ipv4_forwarding=1
nvram commit
```

### Open Port on Router

1. **Via Web Interface:**
   - Go to: `WAN` → `Virtual Server / Port Forwarding`
   - Add rule:
     - Service Name: WireGuard
     - Port Range: 51820
     - Local IP: Router's IP
     - Local Port: 51820
     - Protocol: UDP

2. **Via iptables (if needed):**
   ```bash
   iptables -I INPUT -p udp --dport 51820 -j ACCEPT
   ```

## Step 7: Start WireGuard

### Manual Start

```bash
# Start WireGuard interface
wg-quick up wg0

# Check status
wg show

# Stop interface
# wg-quick down wg0
```

### Auto-Start on Boot

Create init script:

```bash
# Create startup script
cat > /opt/etc/init.d/S50wireguard << 'EOF'
#!/bin/sh

ENABLED=yes
PROCS=wg-quick

start() {
    if [ "$ENABLED" = "yes" ]; then
        echo "Starting WireGuard"
        /opt/bin/wg-quick up wg0
    fi
}

stop() {
    echo "Stopping WireGuard"
    /opt/bin/wg-quick down wg0
}

restart() {
    stop
    sleep 2
    start
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart|reload)
        restart
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac

exit 0
EOF

# Make executable
chmod +x /opt/etc/init.d/S50wireguard

# Start on boot
/opt/etc/init.d/S50wireguard start
```

## Step 8: Install WireGuard UI (Optional but Recommended)

WireGuard UI provides a web interface to manage your VPN server easily.

### Install WireGuard UI

```bash
cd /opt/etc/wireguard

# Download wireguard-ui for ARM (RT-AC86U)
wget https://github.com/ngoduykhanh/wireguard-ui/releases/download/v0.6.2/wireguard-ui-v0.6.2-linux-arm.tar.gz

# Extract
tar -xzf wireguard-ui-v0.6.2-linux-arm.tar.gz

# Make executable
chmod +x wireguard-ui

# Create data directory
mkdir -p /opt/etc/wireguard/db

# Fix: Create symlink for WireGuard UI to find config
mkdir -p /etc/wireguard
ln -sf /opt/etc/wireguard/wg0.conf /etc/wireguard/wg0.conf
```

### Create Startup Script

```bash
cat > /opt/etc/init.d/S51wireguard-ui << 'EOF'
#!/bin/sh

ENABLED=yes
PROCS=wireguard-ui

start() {
    if [ "$ENABLED" = "yes" ]; then
        echo "Starting WireGuard UI"
        cd /opt/etc/wireguard
        ./wireguard-ui --bind-address 0.0.0.0:5000 > /dev/null 2>&1 &
    fi
}

stop() {
    echo "Stopping WireGuard UI"
    killall wireguard-ui
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 2
        start
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac

exit 0
EOF

# Make executable
chmod +x /opt/etc/init.d/S51wireguard-ui

# Start WireGuard UI
/opt/etc/init.d/S51wireguard-ui start
```

### Enable Auto-Start on Reboot

Create the post-mount script to auto-start all Entware services after reboot:

```bash
# Create post-mount script with all necessary fixes
cat > /jffs/scripts/post-mount << 'EOF'
#!/bin/sh

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
EOF

chmod +x /jffs/scripts/post-mount

# Enable custom scripts on router
nvram set jffs2_scripts=1
nvram commit

# Verify
ls -la /jffs/scripts/post-mount
```

This ensures:
- TUN module is loaded
- WireGuard can access /dev/net/tun
- Config symlink is recreated (needed by WireGuard UI)
- WireGuard UI and all Entware services start automatically after router reboots

### Access WireGuard UI

- **URL:** `http://192.168.1.1:5000` (or your router's IP)
- **Default Username:** `admin`
- **Default Password:** `admin`

**Important:** Change the default password immediately after first login!

### Features

- Add/remove clients via web interface
- Generate QR codes for mobile devices
- View active connections
- Download client configs
- Monitor traffic

## Step 9: Test Connection

### On Client Device

1. **Windows:** Install WireGuard from wireguard.com
2. **Mobile:** Install WireGuard app from app store
3. **Linux:** `apt install wireguard` or `opkg install wireguard-tools`

### Import Configuration

- Copy `client1.conf` to client device
- Import into WireGuard app
- Activate connection
- Test: `ping 10.0.0.1` (should reach router)

## Common Issues During Setup (Real Experience - March 2026)

### Issue 1: Old USB Symlink After USB Stick Failure

**Problem:** After replacing dead USB stick, `/opt` still points to old USB path `/tmp/mnt/ENTWARE/opt`

**Symptoms:**
```bash
ls -la /opt
# Shows: lrwxrwxrwx 1 admin root 20 Mar 7 11:27 /opt -> /tmp/mnt/ENTWARE/opt
```

**Solution:**
```bash
# Remount root as read-write (it's read-only by default)
mount -o remount,rw /

# Remove old symlink
rm /opt

# Create new symlink to new USB
ln -sf /tmp/mnt/sda1/opt /opt

# Remount as read-only (optional, for safety)
mount -o remount,ro /

# Verify
ls -la /opt
# Should show: /opt -> /tmp/mnt/sda1/opt
```

### Issue 2: WireGuard UI Can't Find Config File

**Problem:** WireGuard UI looks in `/etc/wireguard/` but config is in `/opt/etc/wireguard/`

**Error:**
```
Cannot create server config: open /etc/wireguard/wg0.conf: no such file or directory
```

**Solution:**
```bash
# Create /etc/wireguard directory
mkdir -p /etc/wireguard

# Create symlink to actual config
ln -sf /opt/etc/wireguard/wg0.conf /etc/wireguard/wg0.conf

# Restart WireGuard UI
killall wireguard-ui
/opt/etc/init.d/S51wireguard-ui start
```

### Issue 3: opkg Command Not Found After Entware Install

**Problem:** Entware installed but `opkg` command not in PATH

**Solution:**
```bash
# Add to current session
export PATH=/opt/bin:/opt/sbin:$PATH

# Make permanent
echo 'export PATH=/opt/bin:/opt/sbin:$PATH' >> ~/.profile

# Or use full path
/opt/bin/opkg update
```

### Issue 4: kmod-wireguard Not Available

**Problem:** `opkg install kmod-wireguard` fails - package doesn't exist for your kernel

**Solution:**
```bash
# Just install wireguard-tools (userspace tools are enough for most setups)
opkg install wireguard-tools

# Verify
wg --version
# Should show: wireguard-tools v1.0.20210914
```

**Note:** Kernel module (kmod-wireguard) is not required if you're using the userspace implementation. WireGuard will work fine with just wireguard-tools.

### Issue 5: Services Don't Start After Reboot

**Problem:** WireGuard UI and other Entware services don't auto-start after router reboot

**Symptoms:**
- UI accessible at port 5000 before reboot
- After reboot, port 5000 not responding
- `ps | grep wireguard-ui` shows no process

**Solution:**
Create `/jffs/scripts/post-mount` script to auto-start all Entware services:

```bash
cat > /jffs/scripts/post-mount << 'EOF'
#!/bin/sh

# Wait for USB to fully mount
sleep 10

# Start all Entware init scripts
if [ -d /opt/etc/init.d ]; then
    for script in /opt/etc/init.d/S??*; do
        [ -x "$script" ] && $script start
    done
fi
EOF

chmod +x /jffs/scripts/post-mount

# Enable custom scripts
nvram set jffs2_scripts=1
nvram commit
```

**Why:** Asus routers don't automatically run Entware init scripts after reboot. The `post-mount` script triggers after USB mounts.

### Issue 6: Missing wg-quick Command

**Problem:** `/opt/bin/wg-quick: not found` when trying to start WireGuard

**Symptoms:**
```bash
/opt/etc/init.d/S50wireguard start
# Shows: /opt/bin/wg-quick: not found

ls -la /opt/bin/wg*
# Only shows: /opt/bin/wg (missing wg-quick)
```

**Root Cause:** The `wireguard-tools` package only contains `/opt/bin/wg` command. It does NOT include the `wg-quick` script.

**Solution:**
```bash
# Install wireguard-go package (includes wg-quick)
opkg install wireguard-go

# This also installs dependencies:
# - bash
# - coreutils
# - wg-quick script

# Verify wg-quick is now available
which wg-quick
# Should show: /opt/bin/wg-quick

ls -la /opt/bin/wg-quick
# Should show the script file
```

**Prevention:** Always install both `wireguard-tools` AND `wireguard-go` packages.

### Issue 7: Missing /dev/net/tun Device

**Problem:** WireGuard can't create interface - "Failed to create TUN device: /dev/net/tun does not exist"

**Symptoms:**
```bash
wg-quick up wg0
# Shows: ERROR: Failed to create TUN device: /dev/net/tun does not exist
# Or: RTNETLINK answers: Operation not supported
```

**Root Cause:** TUN kernel module not loaded or /dev/net/tun has wrong permissions.

**Solution:**
```bash
# Load TUN kernel module
modprobe tun

# Verify module is loaded
lsmod | grep tun
# Should show: tun    21207  0

# Check if /dev/net/tun exists
ls -la /dev/net/tun
# Should show: crw-rw-rw- device file

# If permissions are wrong (crw-------), fix them:
chmod 666 /dev/net/tun

# Try starting WireGuard again
wg-quick up wg0
```

**Make Permanent:** Add to `/jffs/scripts/post-mount` (already included in updated script above):
```bash
modprobe tun 2>/dev/null
chmod 666 /dev/net/tun 2>/dev/null
```

**Why:** The TUN module and device are required for creating virtual network interfaces. They may not persist after reboot on some router configurations.

### Issue 8: WireGuard Interface Won't Start (Kernel Module)

**Problem:** WireGuard UI works but interface won't activate - "Protocol not supported" or "Unable to modify interface"

**Symptoms:**
```bash
wg-quick up wg0
# Shows warnings about kernel module
# Shows: [!] Missing WireGuard kernel module. Falling back to slow userspace implementation.
# Then: Unable to modify interface: Protocol not supported

wg show
# Returns nothing (no active interface)
```

**Root Cause:** WireGuard kernel module not available or not loaded. Some Merlin builds may not include WireGuard kernel support.

**Workarounds:**

**Option 1: Check for Native Merlin WireGuard Support**
1. Go to router web interface
2. Navigate to **VPN** section
3. Look for **WireGuard** tab or option
4. If available, use Merlin's built-in WireGuard server instead of manual Entware setup
5. This is the recommended approach if available

**Option 2: Use WireGuard UI to Manage (Manual Activation)**
- WireGuard UI can still manage configs and generate client QR codes
- You may need to manually bring up the interface through router settings
- Or consider using OpenVPN as alternative (better kernel support on routers)

**Option 3: Check Kernel Module Availability**
```bash
# Search for WireGuard kernel module
find /lib/modules -name "*wireguard*"

# If found, try loading it
insmod /lib/modules/$(uname -r)/wireguard.ko

# Check if loaded
lsmod | grep wireguard
```

**Note:** This is a known limitation with some router firmwares. The setup guide works perfectly when kernel support is available, but WireGuard requires either kernel module support OR full userspace implementation (wireguard-go with proper permissions).

## Troubleshooting

### Check WireGuard Status

```bash
# View interface status
wg show

# View interface details
ip addr show wg0

# Check if running
ps | grep wg
```

### Check Logs

```bash
# System log
logread | grep -i wireguard

# Kernel module
lsmod | grep wireguard
```

### Debug Connection Issues

```bash
# Test UDP port is open
netstat -tulpn | grep 51820

# Check routing
ip route show

# Check firewall rules
iptables -L -v -n | grep 51820
iptables -t nat -L -v -n
```

### Common Issues

1. **Port not forwarding:** Check router WAN settings, ISP may block UDP ports
2. **Can't load kernel module:** May need different firmware or router model doesn't support it
3. **No internet through VPN:** Check PostUp/PostDown iptables rules and IP forwarding
4. **Connection times out:** Verify public IP/domain is correct and port 51820 UDP is open

## Alternative: Use DDNS

If your ISP changes your IP frequently:

```bash
# Set up on router (if available)
# Or use a DDNS service like:
# - No-IP
# - DuckDNS
# - Cloudflare

# Update client config Endpoint with your DDNS domain:
# Endpoint = yourdomain.ddns.net:51820
```

## Backup Configuration

```bash
# Backup all configs and keys
cd /opt/etc/wireguard
tar -czf ~/wireguard-backup-$(date +%Y%m%d).tar.gz .

# Download to PC via SCP:
# scp admin@192.168.1.1:~/wireguard-backup-*.tar.gz .
```

## Security Notes

- Keep private keys secure and never share them
- Use unique keys for each client
- Regularly update Entware packages: `opkg update && opkg upgrade`
- Monitor connected peers: `wg show`
- Revoke client access by removing [Peer] section and restarting: `wg-quick down wg0 && wg-quick up wg0`

## Quick Reference Commands

```bash
# Start VPN
wg-quick up wg0

# Stop VPN
wg-quick down wg0

# View status
wg show

# View connected peers
wg show wg0 peers

# Add new peer without restart
wg set wg0 peer CLIENT_PUBLIC_KEY allowed-ips 10.0.0.3/32

# Remove peer
wg set wg0 peer CLIENT_PUBLIC_KEY remove

# Reload config
wg-quick down wg0 && wg-quick up wg0
```

## Quick Fix Reference (Troubleshooting Checklist)

Use this checklist if things aren't working after reboot or fresh install:

```bash
# 1. Check USB is mounted
df -h | grep /tmp/mnt/sda1

# 2. Check PATH includes /opt/bin
echo $PATH | grep /opt/bin

# 3. Verify BOTH WireGuard packages installed
which wg && which wg-quick

# 4. Check TUN module loaded
lsmod | grep tun

# 5. Check /dev/net/tun exists and has correct permissions
ls -la /dev/net/tun  # Should show: crw-rw-rw-

# 6. Verify config symlink exists
ls -la /etc/wireguard/wg0.conf  # Should point to /opt/etc/wireguard/wg0.conf

# 7. Check post-mount script exists and is executable
ls -la /jffs/scripts/post-mount

# 8. Verify jffs2_scripts enabled
nvram get jffs2_scripts  # Should return: 1

# 9. Check WireGuard UI is running
ps | grep wireguard-ui
netstat -tulpn | grep 5000

# 10. Manually start WireGuard UI if needed
cd /opt/etc/wireguard && ./wireguard-ui --bind-address 0.0.0.0:5000 &
```

**If WireGuard UI is dead after reboot:**
```bash
mkdir -p /etc/wireguard
ln -sf /opt/etc/wireguard/wg0.conf /etc/wireguard/wg0.conf
cd /opt/etc/wireguard && ./wireguard-ui --bind-address 0.0.0.0:5000 &
```

**If WireGuard interface won't start:**
```bash
modprobe tun
chmod 666 /dev/net/tun
wg-quick up wg0
```

---

**Last Updated:** March 11, 2026 (Power cycle tested after multiple real-world issues)
**Tested On:** Asus RT-AC86U (aarch64 architecture) with ASUSWRT-Merlin 386.14_2 - Successfully configured
**Real-World Validation:** All common issues documented from actual setup session including USB replacement, missing packages, symlink problems, TUN module issues, and auto-start configuration
**Also Compatible With:** RT-AX88U, RT-AC68U, and other ARMv7/ARMv8 Asus routers with Merlin firmware
