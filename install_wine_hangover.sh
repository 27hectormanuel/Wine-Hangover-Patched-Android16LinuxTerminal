#!/bin/bash

echo "Updating and upgrading packages..."
pkg update -y && pkg upgrade -y

echo "Installing required packages..."
pkg install -y wget termux-tools

echo "Downloading Wine Hangover setup script..."
wget https://github.com/Fcharan/WinlatorMali/releases/download/0.0/wine_hangover_menu.sh -O ~/wine_hangover_menu.sh

chmod +x ~/wine_hangover_menu.sh

echo  Use Command 'wine-hangover-menu'  Now
echo "alias wine-hangover-menu='bash ~/wine_hangover_menu.sh'" >> ~/.bashrc

source ~/.bashrc
exec bash

echo Use Command 'wine-hangover-menu'  Now
if alias wine-hangover-menu &>/dev/null; then
    # Confirm that setup is complete
    echo "Wine Hangover Interface setup complete. You can now use the command 'wine-hangover-menu' to start it."
else
    echo "Failed to add alias for 'wine-hangover-menu'. Please check the script."
fi