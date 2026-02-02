sudo rm -r $HOME/xuukiarchiso
cp -r /usr/share/archiso/configs/releng/ $HOME/xuukiarchiso
cp $HOME/Projects/OS/lock.sh $HOME/xuukiarchiso/airootfs/usr/local/bin/lock.sh
chmod +x $HOME/xuukiarchiso/airootfs/usr/local/bin/lock.sh
cat << EOF > $HOME/xuukiarchiso/airootfs/etc/profile
/usr/local/bin/lock.sh
EOF

# Define the line to be added                                                                                 
line='  ["/usr/local/bin/lock.sh"]="0:0:755"'                                                        
                                                                                                              
# Check if the line already exists in the file                                                                
if ! grep -qF "$line" ~/xuukiarchiso/profiledef.sh; then                                                      
  # Add the line before the closing parenthesis of file_permissions                                           
  sed -i "/file_permissions=(/a\\$line" ~/xuukiarchiso/profiledef.sh                                          
  echo "Line added to profiledef.sh"                                                                          
else                                                                                                          
  echo "Line already exists in profiledef.sh"                                                                 
fi

echo "inotify-tools" | tee -a $HOME/xuukiarchiso/packages.x86_64

cd $HOME/xuukiarchiso
sudo mkarchiso -v .
