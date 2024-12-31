# Wine-Hangover-Patched Credits 

[Wine Hangover Patched](https://github.com/alexvorxx/hangover-termux/releases/tag/9.22) By Alexxrox 

[Mesa Native Wrapper](https://github.com/xMeM/termux-packages/actions) By Xmem 

[Patched Dxvk](https://github.com/Trass3r/dxvk/actions/runs/11881817846) By Trass3r 

Script And Additional Files By Fcharan 

# Features

Automatic Installation 

Mesa Native Wrapper Installed By Default 

Has An Start Interface 

Option To Install InputBridge , Patched Dxvk , Start Menu Patch From wine-hangover-menu 

Patched Dxvk With Stripped Requirements To Run On Mediatek And Other Chipsets 

Required Dlls Are Added To Env Variables By Default 

Pulse Audio Works

# Note

Only Some Games Are Working Now

Some Devices Have Issues And Hangover Will Not Work

# Installation 

1 - Install [Termux](https://github.com/Fcharan/WinlatorMali/releases/download/0.0/termux-app_v0.118.1+github-debug_arm64-v8a.apk)  and  [Termux X11](https://github.com/Fcharan/WinlatorMali/releases/download/0.0/app-arm64-v8a-debug.apk)

2 - Install [InputBridge](https://raw.githubusercontent.com/olegos2/mobox/main/components/inputbridge.apk)

## Installation Command

Run the following command in your Termux:

<pre>
<code>
pkg install termux-am -y
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

# Gameplay

Tested On Dimensity 7200

https://github.com/user-attachments/assets/8ae76b35-c97f-44da-aeec-9633f801f976

![1000088504](https://github.com/user-attachments/assets/4e2463da-b1b0-4795-a2f5-1ae1a9900f86)

![1000088589](https://github.com/user-attachments/assets/5dc386a4-fa97-41ea-b848-b6f3468d9bca)

![1000088585](https://github.com/user-attachments/assets/0165ec33-a992-4670-b51c-d99baeb10a20)

![1000088517](https://github.com/user-attachments/assets/df6697c5-448a-4c8a-a217-ffae3c107dd9)


