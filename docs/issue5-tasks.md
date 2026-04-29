# Issue 5: x230 Bare Metal Desktop Environment Integration

## Overview
Complete integration of DWM suckless desktop environment, LightDM greeter, and Plymouth boot splash into the Arch Linux installation process.

## Completed Work (2026-04-29)

### 1. Suckless Software Build System
**Status:** ✅ Working on x230

**Components:**
- **DWM**: Window manager with admin config (3 tags, Alt keybindings, Nerd Fonts)
- **dwmblocks**: Status bar with date/time + WiFi icons
- **dmenu**: Application launcher
- **st**: Terminal emulator

**Key Configuration Decisions:**
- MODKEY = Mod1Mask (Alt) — matches Vaio behavior
- Tags: "1", "2", "3" with icon spacing (terminal, dev, web)
- Fonts: monospace + Symbols Nerd Font for icons
- Minimal rules: st, Zathura, qutebrowser only

### 2. LightDM WebKit Greeter
**Status:** ✅ Working on x230

**Critical Fix:**
- LightDM tries to run `lightdm-session` command which doesn't exist
- Fix: Create symlink `/usr/bin/lightdm-session` → `/etc/lightdm/Xsession`
- Config requires `session-wrapper=/etc/lightdm/Xsession` in [Seat:*] section

**Theme:** Neo-brutalist xuuki-greeter (white box, hard shadows)

### 3. Plymouth Boot Splash
**Status:** ❌ Disabled on x230 (Intel HD 4000 incompatibility)

**Note:** Plymouth hangs on i915-only systems. Workaround is text boot.

---

## Required Changes to arch-install-scripts/i52520M.sh

### Phase 1: Package Installation (in pacstrap)

**Add packages:**
```bash
# Suckless build dependencies
libx11 libxft libxinerama xorg-server xorg-xinit

# LightDM + greeter
lightdm lightdm-webkit2-greeter

# Plymouth (optional - may need to skip on i915)
plymouth plymouth-theme-spinner

# Fonts
nerd-fonts ttf-nerd-fonts-symbols

# WiFi tools
networkmanager nm-applet

# Rofi (for WiFi menu)
rofi
```

### Phase 2: User Setup (in chroot-script.sh)

**Clone suckless repos:**
```bash
# As admin user
su - $NEW_USER -c "mkdir -p ~/Projects"
su - $NEW_USER -c "git clone https://git.suckless.org/dwm ~/Projects/dwm"
su - $NEW_USER -c "git clone https://git.suckless.org/dwmblocks ~/Projects/dwmblocks"
su - $NEW_USER -c "git clone https://git.suckless.org/dmenu ~/Projects/dmenu"
su - $NEW_USER -c "git clone https://git.suckless.org/st ~/Projects/st"
```

**Install configs and build:**
```bash
# Copy admin configs from OS repo
su - $NEW_USER -c "cp ~/Projects/OS/configs/dwm-source/config.h ~/Projects/dwm/"
su - $NEW_USER -c "cp ~/Projects/OS/configs/dwmblocks-source/config.h ~/Projects/dwmblocks/"
su - $NEW_USER -c "cp ~/Projects/OS/configs/dwmblocks-source/wifi-menu.sh ~/Projects/dwmblocks/bin/"

# Build and install
su - $NEW_USER -c "cd ~/Projects/dwm && make && sudo make install"
su - $NEW_USER -c "cd ~/Projects/dwmblocks && make && sudo make install"
su - $NEW_USER -c "cd ~/Projects/dmenu && make && sudo make install"
su - $NEW_USER -c "cd ~/Projects/st && make && sudo make install"
```

### Phase 3: Desktop Session Setup

**Create .xinitrc:**
```bash
su - $NEW_USER -c "echo 'export DISPLAY=:\${DISPLAY:-:0}' > ~/.xinitrc"
su - $NEW_USER -c "echo 'dwmblocks &' >> ~/.xinitrc"
su - $NEW_USER -c "echo 'exec dwm' >> ~/.xinitrc"
```

**Create start-dwm.sh wrapper:**
```bash
cat > /usr/local/bin/start-dwm.sh << 'EOF'
#!/bin/sh
LOG=/tmp/start-dwm.log
{
  echo "== $(date) =="
  echo "DISPLAY=$DISPLAY"
} >> "$LOG" 2>&1

if command -v dwmblocks >/dev/null 2>&1; then
  dwmblocks >> "$LOG" 2>&1 &
fi

while true; do
  /usr/local/bin/dwm >> "$LOG" 2>&1
  sleep 1
done
EOF
chmod +x /usr/local/bin/start-dwm.sh
```

### Phase 4: LightDM Configuration

**Create dwm.desktop:**
```bash
cat > /usr/share/xsessions/dwm.desktop << 'EOF'
[Desktop Entry]
Encoding=UTF-8
Name=dwm
Comment=Dynamic window manager
Exec=/usr/local/bin/start-dwm.sh
Icon=dwm
Type=XSession
EOF
```

**Configure LightDM:**
```bash
# Create lightdm-session symlink (CRITICAL FIX)
ln -s /etc/lightdm/Xsession /usr/bin/lightdm-session

# Install config
cp /home/$NEW_USER/Projects/OS/configs/lightdm/lightdm.conf /etc/lightdm/lightdm.conf

# Install theme
mkdir -p /usr/share/lightdm-webkit/themes/xuuki-greeter
cp /home/$NEW_USER/Projects/OS/index.html /usr/share/lightdm-webkit/themes/xuuki-greeter/

# Enable LightDM
systemctl enable lightdm
```

### Phase 5: Plymouth Configuration (Optional)

**Note:** Skip on x230 (Intel HD 4000 incompatibility)

For other systems:
```bash
# Copy theme
mkdir -p /usr/share/plymouth/themes/xuuki-splash
cp ~/Projects/OS/configs/plymouth/xuuki-splash/* /usr/share/plymouth/themes/xuuki-splash/

# Set theme
plymouth-set-default-theme xuuki-splash

# Add plymouth hook
# Edit /etc/mkinitcpio.conf: HOOKS=(base plymouth ...)
mkinitcpio -P
```

---

## Testing Checklist

- [ ] DWM starts via LightDM greeter
- [ ] Alt+Shift+Return opens terminal
- [ ] Alt+Shift+Q quits DWM
- [ ] Ctrl+W brings up WiFi rofi menu
- [ ] dwmblocks shows date/time + WiFi icon
- [ ] 3 tags visible with proper spacing
- [ ] Login/logout cycle works

## Known Issues

| Issue | Cause | Workaround |
|-------|-------|------------|
| Plymouth hangs | i915 graphics | Skip Plymouth, use text boot |
| lightdm-session missing | Not in PATH | Create symlink to Xsession |
| Black screen after login | Old binary running | Kill DWM to restart with new config |

## References

- DWM config: `~/Projects/OS/configs/dwm-source/config.h`
- dwmblocks config: `~/Projects/OS/configs/dwmblocks-source/`
- LightDM config: `~/Projects/OS/configs/lightdm/lightdm.conf`
- Automation scripts: `~/Projects/OS/scripts/setup-*.sh`
