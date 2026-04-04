# Disable SMT (Simultaneous Multi-Threading) for Audio Workstations

## Purpose
Reduce heat and fan noise during audio recording by disabling virtual CPU threads.

## Hardware
- Intel Core i3-2310M (Sandy Bridge, 2 cores / 4 threads with HT)
- Target: 2 physical cores only, no virtual threads

## Procedure

### 1. Modify GRUB Kernel Parameters

Edit `/etc/default/grub`:

```bash
sudo nano /etc/default/grub
```

Find `GRUB_CMDLINE_LINUX_DEFAULT` and append `nosmt`:

```
GRUB_CMDLINE_LINUX_DEFAULT="quiet ... nosmt"
```

**Note:** `noht` is deprecated. Use `nosmt` on modern kernels.

### 2. Regenerate GRUB Config

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### 3. Reboot

```bash
sudo reboot
```

### 4. Verify

```bash
lscpu | grep -E "Thread|Core|CPU"
```

Expected output:
```
CPU(s):                               2
Thread(s) per core:                   1
Core(s) per socket:                   2
NUMA node0 CPU(s):                    0,2
```

Check kernel params:
```bash
cat /proc/cmdline | grep nosmt
```

## Result
- Logical CPUs: 4 → 2
- Heat generation: Reduced
- Fan noise: Lower under sustained load
- Real-time audio: Improved (no SMT contention)

## Related Files
- `~/.local/bin/jackd-recording.sh` — 1024-sample JACK config
- `~/.xprofile` — dwmblocks auto-start
- `~/Projects/OS/configs/dwm/xprofile.backup`

## References
- `csmt_1_2025.tex` — Full journal with thermal analysis
