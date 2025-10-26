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
<pre>

# Xuuki OS Installer API
Automated Arch Linux installation via a single API call.

Xuuki OS Installer is a Node HTTP API that delivers a Bash script for automating Arch Linux installations.
From a live environment, you can call the API and pipe the script directly into your shell:

<pre>
bash <(curl -s https://xuuki.xyz/os/i52520M)
<pre>

## Usage

1. Boot from Arch Linux live ISO.
2. Open a terminal.
3. Run:

<pre>
bash <(curl -s https://xuuki.xyz/os/i52520M)
<pre>
