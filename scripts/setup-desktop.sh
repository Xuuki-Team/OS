#!/bin/bash
# setup-desktop.sh — install the full Xuuki admin desktop (dwm + dwmblocks + ticker
# + lightdm xuuki-webkit greeter + plymouth) on a freshly installed machine.
# Idempotent: re-run safe. Run as root AFTER the base install + admin user exists.
# Usage: sudo bash setup-desktop.sh [--with-splash]
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
NEW_USER="${NEW_USER:-admin}"

echo "=== Xuuki desktop setup (repo: $REPO_DIR, user: $NEW_USER) ==="

# 1. Packages
echo '--- Installing packages (needed set only) ---'
pacman -S --needed --noconfirm base-devel git xorg-server xorg-xinit xterm \
  libx11 libxft libxinerama lightdm lightdm-webkit2-greeter curl libxml2 \
  imagemagick feh papirus-icon-theme ttf-dejavu ttf-liberation

# 2. Userland repos into admin's ~/Projects (clones on this machine, network OK here)
echo '--- Cloning userland repos ---'
mkdir -p /home/$NEW_USER/Projects
for repo in dwm dwmblocks dmenu st; do
  [ -d /home/$NEW_USER/Projects/$repo/.git ] || \
    git clone -q https://github.com/Xuuki-Team/$repo /home/$NEW_USER/Projects/$repo || \
    git clone -q https://git.suckless.org/$repo /home/$NEW_USER/Projects/$repo
done
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/Projects

# 3. Configs into the clones (the verified working ones)
install -m 644 "$REPO_DIR/configs/dwm-source/config.h"      /home/$NEW_USER/Projects/dwm/config.h
install -m 644 "$REPO_DIR/configs/dwmblocks-source/config.h" /home/$NEW_USER/Projects/dwmblocks/config.h
chown $NEW_USER:$NEW_USER /home/$NEW_USER/Projects/{dwm,dwmblocks}/config.h

# 4. Build as admin
echo '--- Building dwm / dwmblocks / dmenu / st as admin ---'
su - $NEW_USER -c '
set -e
cd ~/Projects/dwm       && make clean && make && sudo make install
cd ~/Projects/dwmblocks && make clean && make && sudo make install
cd ~/Projects/dmenu     && make clean && make && sudo make install || true
cd ~/Projects/st        && make clean && make && sudo make install || true
'

# 5. User helper scripts at ~/dwmblocks (paths referenced by blocks)
echo '--- Deploying user helper scripts ---'
mkdir -p /home/$NEW_USER/dwmblocks/bin
install -m 755 "$REPO_DIR/dwmblocks/date.sh"            /home/$NEW_USER/dwmblocks/date.sh
install -m 755 "$REPO_DIR/dwmblocks/weather.sh"         /home/$NEW_USER/dwmblocks/weather.sh
install -m 755 "$REPO_DIR/dwmblocks/wifi.sh"            /home/$NEW_USER/dwmblocks/wifi.sh
install -m 755 "$REPO_DIR/dwmblocks/bin/news-ticker.sh" /home/$NEW_USER/dwmblocks/bin/news-ticker.sh
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/dwmblocks

# 6. News ticker user service
echo '--- Installing news ticker service ---'
machinectl shell $NEW_USER@.host /bin/bash "$REPO_DIR/dwmblocks/scripts/install-news-ticker.sh" 2>/dev/null || \
  su - $NEW_USER -c "bash $REPO_DIR/dwmblocks/scripts/install-news-ticker.sh"

# 7. Greeter (fixed setup-lightdm.sh: [Seat:*], [branding], session-wrapper, DMABUF env)
echo '--- Greeter (lightdm + xuuki webkit) ---'
bash "$REPO_DIR/scripts/setup-lightdm.sh"

### Section marker
# 8. Session + background + xinitrc
echo '--- Session files ---'
install -Dm 644 "$REPO_DIR/configs/lightdm/dwm.desktop" /usr/share/xsessions/dwm.desktop
install -m 755 "$REPO_DIR/configs/dwm/start-dwm.sh"     /usr/local/bin/start-dwm.sh
install -Dm 644 "$REPO_DIR/configs/backgrounds.jpg"         /usr/share/backgrounds/im.jpg
install -m 644 "$REPO_DIR/index.html"                   /usr/share/lightdm-webkit/themes/xuuki-greeter/index.html
cat > /home/$NEW_USER/.xinitrc << EOF
#!/bin/bash
dwmblocks &
exec dwm
EOF
chown $NEW_USER:$NEW_USER /home/$NEW_USER/.xinitrc
systemctl enable lightdm

# 9. Optional splash
if [ "${1:-}" = "--with-splash" ]; then
  echo '--- Plymouth splash ---'
  bash "$REPO_DIR/scripts/setup-plymouth.sh"
fi

echo '=== Xuuki desktop installed. Reboot or restart lightdm to test the greeter. ==='
