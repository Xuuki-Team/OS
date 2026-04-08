<pre>
``` System environment (Arch Linux)
+-------------------------------------+    +----------------------------+
|          User Interface (TUI/UI)    |    |       File System (FSH)     |
|        (e.g., Shell)                |    |----------------------------|
+-------------------------------------+    | /home - User directories    |  <- User's home directory
|        User Applications (Apps)     |    | /usr - User programs & libs |
| (e.g., Browsers, Editors, etc.)     |    | /bin - Essential binaries   |  <- System-level binaries
+-------------------------------------+    | /lib - Essential libraries  |
|      System Libraries & Utilities   |    | /etc - Configuration files  |  <- System config files
|   (e.g., libc, systemd, services)   |    | /var - Variable data        |
+-------------------------------------+    | /tmp - Temporary files      |
|              Kernel                 |    | /dev - Device files         |  <- Managed by the kernel
|     (Linux Kernel - Process Mgmt,   |    | /proc - Kernel data         |
|         Memory, File I/O, etc.)     |    | /sys - System info          |
+-------------------------------------+    +----------------------------+
|             Firmware                |
|              (Bios)                 |
+-------------------------------------+
|            Physical Hardware        |
| (CPU, RAM, Disk, Network Devices)   |
+-------------------------------------+
```

# Xuuki OS Installer API
Automated Arch Linux installation via a single API call.

Xuuki OS Installer is a Node HTTP API that delivers a Bash script for automating Arch Linux installations.
From a live environment, you can call the API and pipe the script directly into your shell:

bash <(curl -s https://xuuki.xyz/os/i52520M)

## LightDM WebKit greeter

1. Copy the theme assets (currently `index.html`) into a LightDM WebKit theme directory:
   ```bash
   sudo install -d -m 755 /usr/share/lightdm-webkit/themes/xuuki-greeter
   sudo install -m 644 index.html /usr/share/lightdm-webkit/themes/xuuki-greeter/index.html
   ```
2. Point `/etc/lightdm/lightdm-webkit2-greeter.conf` at the theme: set `webkit_theme = xuuki-greeter`.
3. Ensure LightDM is using the WebKit greeter in `/etc/lightdm/lightdm.conf` (`greeter-session=lightdm-webkit2-greeter`).

## DWM session + dwmblocks service

Files live under `configs/` in this repo:

- `configs/dwm/start-dwm.sh` – session wrapper that loops `dwm`.
- `configs/lightdm/dwm.desktop` – desktop entry whose `Exec` points at the wrapper.
- `configs/systemd/user/dwmblocks.service` – user service that keeps `dwmblocks` alive.

Install/update them like this (per user):

```bash
# Session wrapper
sudo install -Dm755 configs/dwm/start-dwm.sh /usr/local/bin/start-dwm.sh

# Desktop entry (system-wide)
sudo install -m644 configs/lightdm/dwm.desktop /usr/share/xsessions/dwm.desktop

# dwmblocks user service
install -Dm644 configs/systemd/user/dwmblocks.service \
    "$HOME/.config/systemd/user/dwmblocks.service"
systemctl --user daemon-reload
systemctl --user enable --now dwmblocks.service
```

The service assumes the main X display is `:0`; adjust the `DISPLAY` and `XAUTHORITY` lines in the unit if you run multi-seat or Wayland.

After copying the files, restart LightDM (`sudo systemctl restart lightdm`) or log out/in so the new greeter + dwm wrapper take effect.

## Plymouth splash + GRUB tweaks

1. Copy the `configs/plymouth/xuuki-splash` folder to `/usr/share/plymouth/themes/xuuki-splash` (or adjust the paths in the `.plymouth` file if you keep it elsewhere).
2. Point `/etc/plymouth/plymouthd.conf` at the theme (`Theme=xuuki-splash`, `ShowDelay=0`).
3. Apply it and rebuild initramfs in one go:  
   ```bash
   sudo plymouth-set-default-theme -R xuuki-splash
   ```
4. Update `/etc/default/grub` so the boot flow stays hidden: `GRUB_TIMEOUT_STYLE=hidden`, `GRUB_TIMEOUT=1`, and  
   `GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 vt.global_cursor_default=0 systemd.show_status=0 rd.udev.log_priority=3"`.  
   Then regenerate the menu:  
   ```bash
   sudo grub-mkconfig -o /boot/grub/grub.cfg
   ```
5. (Optional) To silence GRUB's "Loading Linux…" lines, apply `configs/grub/10_linux.no-echo.patch` to `/etc/grub.d/10_linux` before regenerating the config.


## Desktop wallpaper hook

Install `configs/dwm/xprofile` to `~/.xprofile` so the existing `~/desktop.sh` script regenerates + applies the wallpaper on every graphical login:  
```bash
install -Dm755 configs/dwm/xprofile "$HOME/.xprofile"
```

## [CASE NOTES] VM Creation & Serial Console Setup

**Goal:** Create `openclaw-vm` via `create-openclaw-vm-auto.sh`, install Arch OS using ISO, then reboot to working login prompt accessible via `virsh console`.

### Attempt 1 - Initial Script Issues
- **Problem:** Permission denied on `/var/lib/libvirt/images/` because script ran without `sudo`
- **Fix:** Added root check `if [ "$EUID" -ne 0 ]` and `set -e`
- **Result:** Script runs but VM crashes during install

### Attempt 2 - OOM Crash (Host Memory)
- **Problem:** `oom_reaper: reaped process (qemu-system-x86)` - VM killed during package install
- **Discovery:** Host (x230) only has 3.5GB RAM, not 8GB
- **Fix:** Reduced VM from 4GB → 2GB RAM, added swapfile (2GB) + swap partition (4GB) = 6GB total swap
- **Result:** Install completes, but no login prompt after reboot

### Attempt 3 - Serial Console Not Working
- **Problem:** After reboot, `virsh console openclaw-vm` shows blank screen, no login prompt
- **Cause:** GRUB not configured for serial console - only kernel had `console=ttyS0` params
- **Current Fix (Testing):** Added proper GRUB serial config:
  ```bash
  GRUB_TERMINAL="console serial"
  GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
  ```
- **Status:** PENDING - Need to reinstall VM with updated script to test

### Key Files Modified
- `create-openclaw-vm-auto.sh` - Added sudo check, `--filesystem` for xuukey mount
- `scripts/install-openclaw-vm-os.sh` - Added swapfile creation, GRUB serial console config

### Next Steps
1. Destroy current VM: `sudo virsh destroy openclaw-vm && sudo virsh undefine openclaw-vm`
2. Delete disk: `sudo rm -f /var/lib/libvirt/images/openclaw-vm.qcow2`
3. Run: `sudo bash create-openclaw-vm-auto.sh`
4. Inside VM: `bash /mnt/xuukey/install-openclaw-vm-os.sh`
5. After reboot: `sudo virsh console openclaw-vm` - should see login prompt



### Attempt 4 - GRUB Serial Config Added (FAILED)
- **Date:** 2026-04-07
- **Change:** Added GRUB_TERMINAL and GRUB_SERIAL_COMMAND to configure GRUB for serial console
- **Expected:** GRUB menu visible via virsh console
- **Actual:** Still blank screen after reboot
- **Status:** FAILED

### Attempt 5 - Next Try
- **Problem:** Serial console still not working
- **Options:** Check GRUB install target, try virtio-console, check systemd getty


### Attempt 5 - GRUB Append If Missing (FAILED)
- **Date:** 2026-04-07
- **Change:** Changed sed replace to grep||echo append pattern for GRUB_TERMINAL, GRUB_SERIAL_COMMAND
- **Expected:** Lines would be added to /etc/default/grub since they dont exist in fresh install
- **Actual:** Still blank screen after reboot
- **Status:** FAILED

### Attempt 6 - Next Ideas
- **Problem:** Serial console not working after multiple GRUB config attempts
- **Hypotheses:**
  1. Serial device mismatch - VM uses isa-serial but maybe needs virtio-serial
  2. systemd getty not enabled on ttyS0
  3. GRUB not actually installing to MBR (pc-i386 target might be wrong)
  4. Need to explicitly enable serial-getty service
- **Next Options:**
  1. Check systemd: systemctl enable serial-getty@ttyS0.service
  2. Verify GRUB install target
  3. Check actual serial device name in VM
  4. Try adding earlyprintk to kernel params


### Attempt 6 - Enable serial-getty@ttyS0 (FAILED)
- **Date:** 2026-04-07
- **Change:** Added systemctl enable serial-getty@ttyS0.service (like Arch ISO does)
- **Expected:** Login prompt would spawn on ttyS0 after boot
- **Actual:** Still blank screen, no login prompt
- **Status:** FAILED

### Attempt 7 - Debug the Real Issue
- **Problem:** Serial console not working after 6 attempts
- **Key Insight:** Arch ISO works fine - need to compare what it does
- **New Hypotheses:**
  1. Wrong serial device - maybe not ttyS0 but hvc0 (virtio-console)?
  2. systemd not reaching multi-user.target?
  3. Need to check /proc/consoles in the installed system
  4. Maybe need to mask getty@tty1 and enable serial-getty as rescue shell?
- **Next:** Need to inspect what the installed system actually sees


### Attempt 11 - Dual Machine Test (IN PROGRESS)
- **Date:** 2026-04-07
- **Setup:** Both x230 and x220 reset to clean state, synced to bugfix/vm-serial-console branch
- **ISO:** Copied working ISO from x230 to x220 (1.5GB archlinux-2026.02.01-x86_64.iso)
- **Network:** Fixed x220 libvirt network (was inactive)
- **Boot Order:** Both VMs created with --boot hd,menu=off (disk first)
- **Status:** IN PROGRESS - Both VMs running

### Current State (16:40 GMT+1)

**x230:**
- VM ID: 37, State: running
- Console: Shows Arch ISO login prompt ("archiso login: root")
- Ready for install

**x220:**
- VM ID: 3, State: running
- Console: Shows [rootfs ~]# prompt (different boot state)
- May have already booted from disk or different init

### Next Steps
1. Run install script on x230: bash /mnt/xuukey/install-openclaw-vm-os.sh
2. Check x220 state - may need reinstall or different approach
3. After both installs complete, test serial console on reboot

### Commands to Complete Install

**On both machines:**



**Inside VM (x230 - at ISO prompt):**


