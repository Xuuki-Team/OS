#!/bin/bash
# date.sh — status block: weekday, date, Nerd-Font calendar glyph, time
DATE_GLYPH="$(printf '\xf3\xb0\x83\xad')"
date "+%a, %d %b  ${DATE_GLYPH} %H:%M"
