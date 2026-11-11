# Xi230 install run — progress checklist

Run from a clone of this repo on the fresh install. Tick items as they pass.

## Base (i52520M.sh)
- [ ] Install script completes (base system + bootloader)
- [ ] connect-to-internet.sh works
- [ ] First boot: login prompt

## Xuuki desktop layer (automated on xuuki-desktop-layer branch)
- [ ] `startx` works after install (xterm fallback)
- [ ] dwm built by automation (`/usr/local/bin/dwm` exists)
- [ ] startx enters dwm (not xterm fallback)
- [ ] dwmblocks running in the bar
- [ ] LightDM greeter shows at boot with Xuuki background
- [ ] Greeter "dwm" session logs in via start-dwm.sh
- [ ] Plymouth Xuuki splash shows at boot

## Configs (manual try-out from this clone)
- [ ] configs/vimrc → ~/.vimrc
- [ ] configs/tmux.conf → ~/.tmux.conf
- [ ] configs/dwm/xprofile → ~/.xprofile

## Post-install scripts (scripts-for-installed-os/)
- [ ] user-setup.sh
- [ ] github-login.sh / get-ssh-keys.sh
- [ ] connect-to-internet.sh (already covered above if re-run)

## Notes for automation (log anything manual you had to do here)
-
