# sudo pacman -Syu lightdm lightdm-slick-greeter
# sudo mkdir /usr/share/xsessions
cat << EOF > /usr/share/xsessions/dwm.desktop
[Desktop Entry]
Encoding=UTF-8
Name=dwm
Comment=Dynamic window manager
Exec=/usr/local/bin/dwm
Icon=dwm
Type=XSession
EOF

cat << EOF > /etc/lightdm/slick-greeter.conf
[Greeter]
background=/usr/share/backgrounds/im.jpg
EOF

