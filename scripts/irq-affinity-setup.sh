#!/bin/bash
# IRQ affinity setup for audio workstation
# Run after boot or add to .xprofile

# Move non-audio IRQs away from CPU0 (dedicated to audio)
echo 2 > /proc/irq/25/smp_affinity_list  # SATA/AHCI
echo 2 > /proc/irq/26/smp_affinity_list  # USB/xHCI
echo 2 > /proc/irq/31/smp_affinity_list  # GPU (i915)
echo 2 > /proc/irq/34/smp_affinity_list  # WiFi (iwlwifi)

# Audio IRQ 35 (snd_hda_intel) stays on CPU0

echo "IRQ affinity configured: audio on CPU0, others on CPU2"
