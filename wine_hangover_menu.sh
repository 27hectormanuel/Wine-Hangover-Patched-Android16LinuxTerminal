#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

clear

if [ -d "$HOME/wine_hangover" ]; then
    is_installed="(Installed)"
else
    is_installed="(Not Installed)"
fi

if [ -d "$HOME/dxvk" ]; then
    dxvk_installed="(Installed)"
else
    dxvk_installed="(Not Installed)"
fi

echo -e "${BLUE}#########################################"
echo -e "${BLUE}#        Wine Hangover Setup Menu       #"
echo -e "${BLUE}#########################################"
echo ""
echo -e "${GREEN}Please choose an option:${NC}"
echo ""
echo -e "${CYAN}1)${NC} Install Wine Hangover $is_installed"
echo -e "${CYAN}2)${NC} Install Patched DXVK By Trass3r (Wine Hangover required)"
echo -e "${CYAN}3)${NC} Start Wine Hangover (Open Termux X11 After Esync Starts)"
echo -e "${CYAN}4)${NC} Install Input Bridge To Start Menu (Run Hangover First If Didn't)"
echo -e "${CYAN}5)${NC} Exit"
echo -e "${CYAN}6)${NC} Apply Start Menu Patch (Run Hangover First If Didn't)"
echo ""

read -p "Enter your choice: " choice

if [ "$choice" -eq 1 ]; then
    if [ -d "$HOME/wine_hangover" ]; then
        echo -e "${GREEN}Wine Hangover is already installed.${NC}"
    else
        pkg update -y && pkg upgrade -y \
          -o Dpkg::Options::="--force-confold"
        
        pkg install -y \
          -o Dpkg::Options::="--force-confold" \
          tur-repo x11-repo

        sed -i '1s/$/ tur-multilib/' /data/data/com.termux/files/usr/etc/apt/sources.list.d/tur.list
        pkg update -y && pkg upgrade -y \
          -o Dpkg::Options::="--force-confold"

        pkg install -y \
          -o Dpkg::Options::="--force-confold" \
          hangover termux-x11-*

        wget https://github.com/alexvorxx/hangover-termux/releases/download/9.22/wine_hangover_9.22_bionic_build_patched.tar.xz
        
        tar -xv -f wine_hangover_9.22_bionic_build_patched.tar.xz

        pkg install -y \
          -o Dpkg::Options::="--force-confold" \
          x11-repo tur-repo \
          freetype git gnutls libandroid-shmem-static libx11 xorgproto \
          libdrm libpixman libxfixes libjpeg-turbo mesa-demos osmesa \
          pulseaudio termux-x11-nightly vulkan-tools xtrans libxxf86vm \
          xorg-xrandr xorg-font-util xorg-util-macros libxfont2 \
          libxkbfile libpciaccess xcb-util-renderutil xcb-util-image \
          xcb-util-keysyms xcb-util-wm xorg-xkbcomp xkeyboard-config \
          libxdamage libxinerama libxshmfence

        wget -q --show-progress -O ~/mesa.deb https://github.com/Fcharan/WinlatorMali/releases/download/0.0/mesa.deb
        dpkg -i ~/mesa.deb

        echo -e "${GREEN}Wine Hangover installed successfully!${NC}"
        echo -e "${YELLOW}Please restart the Termux session to apply the changes.${NC}"
    fi
    bash $0

elif [ "$choice" -eq 2 ]; then
    if [ ! -d "$HOME/wine_hangover" ]; then
        echo -e "${RED}Wine Hangover is not installed. Please install it first.${NC}"
        bash $0
    fi

    if [ -d "$HOME/dxvk" ]; then
        echo -e "${GREEN}DXVK is already installed.${NC}"
    else
        wget https://github.com/Fcharan/WinlatorMali/releases/download/0.0/dxvkpatched.tar -P $HOME
        tar -xvf $HOME/dxvkpatched.tar -C $HOME
        mkdir -p $HOME/.wine/drive_c/windows
        mv -f $HOME/syswow64 $HOME/.wine/drive_c/windows/
        mv -f $HOME/system32 $HOME/.wine/drive_c/windows/
        echo -e "${GREEN}DXVK installed and moved to the correct directory!${NC}"
    fi
    bash $0

elif [ "$choice" -eq 3 ]; then
    if [ ! -d "$HOME/wine_hangover" ]; then
        echo -e "${RED}Wine Hangover is not installed. Please install it first.${NC}"
        bash $0
    fi
    termux-x11 :0 &>/dev/null &
    pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 &>/dev/null
    export VK_ICD_FILENAMES=$PREFIX/share/vulkan/icd.d/wrapper_icd.aarch64.json
    export MESA_VK_WSI_PRESENT_MODE=mailbox
    export MESA_VK_WSI_DEBUG=blit
    export ZINK_DEBUG=compact
    export ZINK_DESCRIPTORS=lazy
    export MESA_SHADER_CACHE=512MB
    export mesa_glthread=true
    export MESA_SHADER_CACHE_DISABLE=false
    export
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    export MESA_NO_ERROR=1
    export MESA_DEBUG=0
    export vblank_mode=0
    export USE_HEAP=1
    export DISPLAY=:0
    export PULSE_SERVER=127.0.0.1
    export XDG_RUNTIME_DIR=/tmp:${TMPDIR}
    export WINEESYNC=1
    export WINEESYNC_TERMUX=1
    export DXVK_HUD=full
    export WINEDEBUG=-all
    export WINEDLLOVERRIDES="advapi32=n,builtin;advpack=n,builtin;
    amstream=n,builtin;atl=n,builtin;
    avicap32=n,builtin;avifil32=n,builtin;
    bcrypt=n,builtin;cabinet=n,builtin;
    cfgmgr32=n,builtin;comctl32=n,builtin;
    comdlg32=n,builtin;d3d8=n,builtin;
    d3d9=n,builtin;d3d10=n,builtin;
    d3d10core=n,builtin;d3d11=n,builtin;
    d3d12=n,builtin;d3dcompiler_43=n,builtin;
    d3dcompiler_47=n,builtin;dinput=n,builtin;
    dinput8=n,builtin;dmusic=n,builtin;
    dsound=n,builtin;dwmapi=n,builtin;
    dxgi=n,builtin;gdiplus=n,builtin;
    gdi32=n,builtin;glu32=n,builtin;
    hal=n,builtin;hlink=n,builtin;
    imm32=n,builtin;kernel32=n,builtin;
    ksuser=n,builtin;mpr=n,builtin;
    msacm32=n,builtin;msvcrt=n,builtin;
    ntdll=n,builtin;ole32=n,builtin;
    oleaut32=n,builtin;opengl32=n,builtin;
    rpcrt4=n,builtin;shell32=n,builtin;
    shlwapi=n,builtin;urlmon=n,builtin;
    user32=n,builtin;usp10=n,builtin;
    uxtheme=n,builtin;version=n,builtin;
    winex11=n,builtin;winhttp=n,builtin;
    winmm=n,builtin;winspool.drv=n,builtin;
    wldap32=n,builtin;ws2_32=n,builtin;"
    ~/wine_hangover/arm64-v8a/bin/wine explorer /desktop=shell explorer

    echo OPEN TERMUX X11 NOW ! !

elif [ "$choice" -eq 4 ]; then
    if [ -d "$HOME/InputBridge" ]; then
        echo -e "${GREEN}Input Bridge is already installed.${NC}"
    else
        wget -q -c --no-check-certificate https://github.com/Fcharan/WinlatorMali/releases/download/0.0/InputBridge.tar -P $HOME
        mkdir -p $HOME/InputBridge
        tar -xvf $HOME/InputBridge.tar -C $HOME/InputBridge
        
        cp -r $HOME/InputBridge/usr/* $HOME/../usr
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error copying files to $HOME/../usr. Exiting...${NC}"
            exit 1
        fi
        
        mkdir -p "$HOME/.wine/drive_c/ProgramData/Microsoft/Windows/Start Menu/InputBridge"
        mv "$HOME/InputBridge/Start IB.bat" "$HOME/.wine/drive_c/ProgramData/Microsoft/Windows/Start Menu/InputBridge/"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error moving Start IB.bat. Exiting...${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}Input Bridge installed successfully!${NC}"
    fi
    bash $0

elif [ "$choice" -eq 6 ]; then
    wget https://github.com/Fcharan/WinlatorMali/releases/download/0.0/startmenu.tar -P $HOME
    tar -xvf $HOME/startmenu.tar -C $HOME
    
    mkdir -p $HOME/.wine/dosdevices/z:/opt/nxt/extras
    cp -r -f $HOME/opt/* $HOME/.wine/dosdevices/z:/opt/nxt/extras/
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Moved 'opt' to drive Z successfully!${NC}"
    else
        echo -e "${RED}Failed to move 'opt' to drive Z.${NC}"
    fi

    cp -r -f $HOME/ProgramData/* $HOME/.wine/drive_c/ProgramData/
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Moved 'ProgramData' to drive C successfully!${NC}"
    else
        echo -e "${RED}Failed to move 'ProgramData' to drive C.${NC}"
    fi

    echo -e "${GREEN}Start Menu Patch applied successfully!${NC}"
    bash $0
fi