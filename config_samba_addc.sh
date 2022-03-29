echo "------------------------------------"
echo "Set Password for Samba Administrator"
echo "------------------------------------"

samba-tool user setpassword administrator

samba-tool domain passwordsettings set --complexity=off
samba-tool domain passwordsettings set --history-length 5
samba-tool domain passwordsettings set --min-pwd-length 6
samba-tool domain passwordsettings set --min-pwd-age 1
samba-tool domain passwordsettings set --max-pwd-age 60
