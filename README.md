# Wine-Hangover-Patched Credits 

Wine Hangover Patched By Alexxrox 

Mesa Native Wrapper By Xmem 

Patched Dxvk By Trass3r 

Script And Additional Files By Fcharan 

# Features

Automatic Installation 

Mesa Native Wrapper Installed By Default 

Has An Start Interface 

Option To Install InputBridge , Patched Dxvk , Start Menu Patch From wine-hangover-menu 

Patched Dxvk With Stripped Requirements To Run On Mediatek And Other Chipsets 


# Installation 

1 - Install Termux And Termux X11

## Installation Command 

```bash
termux-setup-storage
export DEBIAN_FRONTEND=noninteractive
echo 'DPkg::Options { "--force-confold"; }' | tee -a /data/data/com.termux/files/usr/etc/apt/apt.conf.d/local
pkg update -y && pkg upgrade -y --assume-yes && pkg install -y wget
wget https://github.com/Fcharan/WinlatorMali/releases/download/0.0/install_wine_hangover.sh -O ~/install_wine_hangover.sh
chmod +x ~/install_wine_hangover.sh
bash ~/install_wine_hangover.sh
