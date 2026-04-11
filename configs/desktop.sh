#!/bin/sh
magick -size 1366x768 xc: +noise Random \
       -colorspace gray -blur 0x19 \
       -sigmoidal-contrast 4,40% \
       -function Sinusoid 2.9,0 \
       -normalize -gamma 0.9 \
       -fill '#dfefff' -colorize 94% \
       ~/ripples-wall-soft2.png
DISPLAY=:0 feh --bg-fill ~/ripples-wall-soft2.png
