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
install -Dm755 configs/dwm/start-dwm.sh "$HOME/.local/bin/start-dwm.sh"

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

