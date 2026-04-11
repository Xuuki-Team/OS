#!/bin/bash
# tts.sh - Text-to-Speech helper using Piper TTS
# Usage: ./tts.sh "Your text here"
#        echo "Your text" | ./tts.sh

set -e

# Configuration
PIPER_BIN="/usr/bin/piper-tts"
VOICE_MODEL="${HOME}/.local/share/piper-tts/models/en_GB-alba-medium.onnx"
TEMP_FILE="/tmp/piper_tts_$$.wav"

# Check if piper is installed
if [ ! -x "$PIPER_BIN" ]; then
    echo "Error: Piper TTS not found at $PIPER_BIN" >&2
    echo "Install with: sudo pacman -S piper-tts-bin" >&2
    exit 1
fi

# Check if voice model exists
if [ ! -f "$VOICE_MODEL" ]; then
    echo "Error: Voice model not found at $VOICE_MODEL" >&2
    echo "Download from: https://huggingface.co/rhasspy/piper-voices" >&2
    exit 1
fi

# Get text from argument or stdin
if [ $# -gt 0 ]; then
    TEXT="$*"
else
    TEXT=$(cat)
fi

# Generate and play speech
echo "$TEXT" | "$PIPER_BIN" --model "$VOICE_MODEL" --output_file "$TEMP_FILE"
aplay "$TEMP_FILE" 2>/dev/null || echo "Error: Could not play audio" >&2

# Cleanup
rm -f "$TEMP_FILE"
