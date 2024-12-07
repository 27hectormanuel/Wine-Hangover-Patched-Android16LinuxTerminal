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

2 - Install InputBridge

## Installation Command

Run the following command in your Termux:

<pre>
<code>
termux-setup-storage
export DEBIAN_FRONTEND=noninteractive
echo 'DPkg::Options { "--force-confold"; }' | tee -a /data/data/com.termux/files/usr/etc/apt/apt.conf.d/local
pkg update -y && pkg upgrade -y --assume-yes && pkg install -y wget
wget https://github.com/Fcharan/WinlatorMali/releases/download/0.0/install_wine_hangover.sh -O ~/install_wine_hangover.sh
chmod +x ~/install_wine_hangover.sh
bash ~/install_wine_hangover.sh
</code>
</pre>

This Command Will Guide You And Automatically Installs All Required Files

Use The Command wine-hangover-menu To Enter Start Interface Again After Exit

# Screenshot 

![1000085668](https://github.com/user-attachments/assets/b431e1e9-549b-47d4-804b-583e61b882b2)

