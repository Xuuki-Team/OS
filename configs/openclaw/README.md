# OpenClaw Workspace Configuration

This directory contains the essential workspace files for OpenClaw automation.

## Files

### TOOLS.md
Local environment notes for the agent:
- Piper TTS configuration (Alba voice)
- SSH host details
- Device-specific settings

### Session Memory
- `2026-04-04-piper-tts-install.md` — Full log of Piper TTS setup on x230

## Setup Instructions

### 1. Place workspace files
```bash
mkdir -p ~/.openclaw/workspace/memory
cp TOOLS.md ~/.openclaw/workspace/
cp 2026-04-04-piper-tts-install.md ~/.openclaw/workspace/memory/
```

### 2. Install Piper TTS

**On vaio (primary):**
```bash
sudo pacman -S piper-tts-bin
mkdir -p ~/.local/share/piper-tts/models
cd ~/.local/share/piper-tts/models
curl -LO 'https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_GB/alba/medium/en_GB-alba-medium.onnx'
curl -LO 'https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_GB/alba/medium/en_GB-alba-medium.onnx.json'
```

**On x230 (remote speaker):**
```bash
sudo pacman -S piper-tts-bin
# Copy voice models from vaio via SCP
scp ~/.local/share/piper-tts/models/* admin@192.168.1.230:~/.local/share/piper-tts/models/
```

### 3. Test multi-machine TTS
```bash
# From vaio, speak on x230
ssh admin@192.168.1.230 'echo "Hello from x230" | piper-tts --model ~/.local/share/piper-tts/models/en_GB-alba-medium.onnx --output_file /tmp/test.wav && aplay /tmp/test.wav'
```

### 4. Agent will auto-detect
With TOOLS.md in place, the agent will:
- Know Piper is available
- Know Alba voice location
- Be able to generate SSH commands for x230

## SSH Setup (for passwordless access)

```bash
# On vaio
ssh-keygen -t ed25519 -C "openclaw" -f ~/.ssh/openclaw_x230
ssh-copy-id -i ~/.ssh/openclaw_x230.pub admin@192.168.1.230
```

Then add to `~/.ssh/config`:
```
Host x230
    HostName 192.168.1.230
    User admin
    IdentityFile ~/.ssh/openclaw_x230
```

## Notes

- **x230 IP**: 192.168.1.230
- **x230 User**: admin
- **x230 Password**: x
- **Alba voice**: en_GB-alba-medium.onnx
- **Piper binary**: /usr/bin/piper-tts

The agent decides which machine to speak on based on your request. If you say "speak on x230", it will SSH there. Otherwise it speaks locally on vaio.
