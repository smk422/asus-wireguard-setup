# How to Publish This Repository to GitHub

Follow these steps to publish your WireGuard setup guide to GitHub.

## Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. **Repository name:** `asus-wireguard-setup`
3. **Description:** Battle-tested WireGuard VPN setup guide for Asus routers with Merlin firmware
4. **Visibility:** Public (so others can benefit)
5. **Initialize:** Don't check any boxes (we have files already)
6. Click **Create repository**

## Step 2: Prepare Local Repository

Open PowerShell in the repository directory:

```powershell
cd c:\develop\asus-wireguard-setup

# Initialize git repository
git init

# Add all files
git add .

# Create first commit
git commit -m "Initial release: Complete WireGuard setup guide for Asus routers"
```

## Step 3: Connect to GitHub

Link your local repo to GitHub (replace YOUR_USERNAME with your actual GitHub username):

```powershell
# Add GitHub as remote
git remote add origin https://github.com/smk422/asus-wireguard-setup.git

# Set main branch
git branch -M main

# Push to GitHub
git push -u origin main
```

## Step 4: Configure Repository Settings

On GitHub:

1. Go to your repo: `https://github.com/smk422/asus-wireguard setup`

2. **Add Topics** (click gear icon next to About):
   - `asus-router`
   - `wireguard`
   - `merlin-firmware`
   - `vpn`
   - `entware`
   - `rt-ac86u`
   - `self-hosted`

3. **Update Description:** "Battle-tested WireGuard VPN setup guide for Asus routers with Merlin firmware and Entware"

4. **Add Website:** (optional) Link to your domain if you have one

## Step 5: Verify

Check that everything looks good:
- README renders properly
- Scripts are in `scripts/` folder
- LICENSE is visible
- Guide is accessible

## Optional: Add Issue Template

Create `.github/ISSUE_TEMPLATE.md`:

```markdown
**Router Model:**
RT-AC86U / RT-AX88U / etc.

**Firmware:**
Merlin 386.14_2 / Stock / etc.

**Problem Description:**
Clear description of the issue...

**What I've tried:**
- Step 1 from troubleshooting...
- Checked XYZ...

**Output/Logs:**
```
Paste relevant command output here
```
```

## Tips for Maintenance

**When updating:**
```powershell
cd c:\develop\asus-wireguard-setup

# Make your changes to files...

# Commit changes
git add .
git commit -m "Describe what you changed"
git push
```

**Update CHANGELOG.md** when you make significant changes.

## Promoting Your Guide

Once published, consider:
1. Share on Reddit: r/ASUS, r/WireGuard, r/selfhosted
2. Post on ASUSWRT-Merlin forums
3. Cross-reference from similar projects
4. Add to awesome lists (awesome-selfhosted, awesome-sysadmin)

## Acknowledgment

If you want to acknowledge collaboration with GitHub Copilot, add to README:

> This guide was created with assistance from GitHub Copilot during a real troubleshooting session, documenting actual issues and their solutions.

---

**Questions?**
- Git not installed? Download from https://git-scm.com/
- New to GitHub? Check https://docs.github.com/en/get-started
