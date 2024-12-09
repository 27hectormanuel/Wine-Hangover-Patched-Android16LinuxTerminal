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

main_menu() {
    echo -e "${BLUE}#########################################"
    echo -e "${BLUE}#        Wine Hangover Setup Menu       #"
    echo -e "${BLUE}#########################################${NC}"
    echo ""
    echo -e "${GREEN}Please choose an option:${NC}"
    echo ""
    echo -e "${CYAN}1)${NC} Install Wine Hangover $is_installed"
    echo -e "${CYAN}2)${NC} Install Patched DXVK By Trass3r"
    echo -e "${CYAN}3)${NC} Start Wine Hangover"
    echo -e "${CYAN}4)${NC} Settings"
    echo -e "${CYAN}5)${NC} Exit"
    echo ""

    read -p "Enter your choice: " choice

    case $choice in
        1) install_wine_hangover ;;
        2) install_dxvk ;;
        3) start_wine_hangover ;;
        4) settings_menu ;;
        5) exit 0 ;;
        *) 
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 1
            bash $0
            ;;
    esac
}

install_wine_hangover() {
    if [ -d "$HOME/wine_hangover" ]; then
        echo -e "${GREEN}Wine Hangover is already installed.${NC}"
    else
        pkg update -y && pkg upgrade -y -o Dpkg::Options::="--force-confold"
        
        pkg install -y -o Dpkg::Options::="--force-confold" \
            tur-repo x11-repo

        sed -i '1s/$/ tur-multilib/' /data/data/com.termux/files/usr/etc/apt/sources.list.d/tur.list
        pkg update -y && pkg upgrade -y -o Dpkg::Options::="--force-confold"

        pkg install -y -o Dpkg::Options::="--force-confold" \
            hangover termux-x11-*

        wget https://github.com/alexvorxx/hangover-termux/releases/download/9.22/wine_hangover_9.22_bionic_build_patched.tar.xz
        tar -xv -f wine_hangover_9.22_bionic_build_patched.tar.xz

        pkg install -y -o Dpkg::Options::="--force-confold" \
            x11-repo tur-repo freetype git gnutls libandroid-shmem-static \
            libx11 xorgproto libdrm libpixman libxfixes libjpeg-turbo \
            mesa-demos osmesa pulseaudio termux-x11-nightly vulkan-tools \
            xtrans libxxf86vm xorg-xrandr xorg-font-util xorg-util-macros \
            libxfont2 libxkbfile libpciaccess xcb-util-renderutil \
            xcb-util-image xcb-util-keysyms xcb-util-wm xorg-xkbcomp \
            xkeyboard-config libxdamage libxinerama libxshmfence

        wget -q --show-progress -O ~/mesa.deb https://github.com/Fcharan/WinlatorMali/releases/download/0.0/mesa.deb
        dpkg -i ~/mesa.deb

        echo -e "${GREEN}Wine Hangover installed successfully!${NC}"
        echo -e "${YELLOW}Please restart the Termux session to apply the changes.${NC}"
    fi
    
    bash $0
}

install_dxvk() {
    if [ ! -d "$HOME/wine_hangover" ]; then
        echo -e "${RED}Wine Hangover is not installed. Please install it first.${NC}"
        read -p " Press Enter to return to main menu. . . "
        bash $0
    fi

    if [ -d "$HOME/dxvk" ]; then
        echo -e "${GREEN}DXVK is already installed.${NC}"
        read -p " Press Enter to return to main menu. . . "
    else
        find /data/data/com.termux/files/home/.wine/drive_c/windows -type f \( \
            -name "d3d9.dll" -o \
            -name "d3d11.dll" -o \
            -name "d3d10.dll" -o \
            -name "d3d10core.dll" -o \
            -name "dxgi.dll" -o \
            -name "d3d10_1.dll" \) -delete

        wget https://github.com/Fcharan/WinlatorMali/releases/download/0.0/dxvkpatched.tar -P $HOME
        tar -xvf $HOME/dxvkpatched.tar -C $HOME
        mkdir -p $HOME/.wine/drive_c/windows
        mv -f $HOME/syswow64 $HOME/.wine/drive_c/windows/
        mv -f $HOME/system32 $HOME/.wine/drive_c/windows/
        
        echo -e "${GREEN}DXVK installed and moved to the correct directory!${NC}"
    fi
    
    read -p " Press Enter to return to main menu. . . "
    bash $0
}

start_wine_hangover() {
    if [ ! -d "$HOME/wine_hangover" ]; then
        echo -e "${RED}Wine Hangover is not installed. Please install it first.${NC}"
        read -p " Press Enter to return to main menu. . . "
        bash $0
    fi

    am start -n com.termux.x11/com.termux.x11.MainActivity
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
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    export MESA_NO_ERROR=1
    export MESA_DEBUG=0
    export vblank_mode=0
    export USE_HEAP=1
    export WINEDEBUGSTACKSIZE=2048
    export DISPLAY=:0
    export PULSE_SERVER=127.0.0.1
    export XDG_RUNTIME_DIR=/tmp:${TMPDIR}
    export WINEESYNC=1
    export WINEESYNC_TERMUX=1
    export DXVK_HUD=fps,version,devinfo
    export WINEDEBUG=-all

    export WINEDLLOVERRIDES="advapi32=n,builtin;advpack=n,builtin;amstream=n,builtin;atl=n,builtin;avicap32=n,builtin;avifil32=n,builtin;bcrypt=n,builtin;cabinet=n,builtin;cfgmgr32=n,builtin;comctl32=n,builtin;comdlg32=n,builtin;d3d8=n,builtin;d3d9=n,builtin;d3d10=n,builtin;d3d10core=n,builtin;d3d11=n,builtin;d3d12=n,builtin;d3dcompiler_43=n,builtin;d3dcompiler_47=n,builtin;dinput=n,builtin;dinput8=n,builtin;dmusic=n,builtin;dsound=n,builtin;dwmapi=n,builtin;dxgi=n,builtin;gdiplus=n,builtin;gdi32=n,builtin;glu32=n,builtin;hal=n,builtin;hlink=n,builtin;imm32=n,builtin;kernel32=n,builtin;ksuser=n,builtin;mpr=n,builtin;msacm32=n,builtin;msvcrt=n,builtin;ntdll=n,builtin;ole32=n,builtin;oleaut32=n,builtin;opengl32=n,builtin;rpcrt4=n,builtin;shell32=n,builtin;shlwapi=n,builtin;urlmon=n,builtin;user32=n,builtin;usp10=n,builtin;uxtheme=n,builtin;version=n,builtin;winex11=n,builtin;winhttp=n,builtin;winmm=n,builtin;winspool.drv=n,builtin;wldap32=n,builtin;ws2_32=n,builtin;"

    ~/wine_hangover/arm64-v8a/bin/wine explorer /desktop=shell,1280x720 explorer
    
    echo OPEN TERMUX X11 NOW ! !
}

settings_menu() {
    echo -e "${BLUE}#########################################"
    echo -e "${BLUE}#              Settings Menu            #"
    echo -e "${BLUE}#########################################${NC}"
    echo ""
    echo -e "${CYAN}1)${NC} Install Input Bridge"
    echo -e "${CYAN}2)${NC} Apply Start Menu Patch"
    echo -e "${CYAN}3)${NC} Change Native Wrapper"
    echo -e "${CYAN}4)${NC} Change Resolution"
    echo -e "${CYAN}5)${NC} Check for Script Updates"
    echo -e "${CYAN}6)${NC} Back to Main Menu"
    echo ""

    read -p "Enter your choice: " settings_choice

    case $settings_choice in
        1) install_input_bridge ;;
        2) apply_start_menu_patch ;;
        3) change_native_wrapper ;;
        4) change_resolution ;;
        5) check_script_updates ;;
        6) bash $0 ;;
        *) 
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 1
            settings_menu
            ;;
    esac
}

install_input_bridge() {
    if [ ! -f "$HOME/.wine/system.reg" ]; then
        echo -e "${RED}Wine Hangover must be opened at least once before installing Input Bridge.${NC}"
        read -p " Press Enter to return to Settings menu. . . "
        settings_menu
    fi

    if [ -d "$HOME/InputBridge" ]; then
        echo -e "${GREEN}Input Bridge is already installed.${NC}"
        read -p " Press Enter to return to Settings menu. . . "
        settings_menu
    fi

    wget https://github.com/Fcharan/WinlatorMali/releases/download/0.0/InputBridge.tar -P $HOME
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
    read -p " Press Enter to return to Settings menu. . . "
    settings_menu
}

apply_start_menu_patch() {
    if [ ! -f "$HOME/.wine/system.reg" ]; then
        echo -e "${RED}Wine Hangover must be opened at least once before applying the Start Menu Patch.${NC}"
        read -p "Press Enter to return to the Settings menu..."
        settings_menu
    fi

    wget https://github.com/Fcharan/WinlatorMali/releases/download/0.0/startmenu.tar -P "$HOME"
    tar -xvf "$HOME/startmenu.tar" -C "$HOME"
    
    mv -f "$HOME/opt" "$HOME/.wine/dosdevices/z:/"
    cp -r -f "$HOME/ProgramData/"* "$HOME/.wine/drive_c/ProgramData/"
    
    echo -e "${GREEN}Start Menu Patch applied successfully!${NC}"
    read -p "Press Enter to return to the Settings menu..."
    settings_menu
}

change_native_wrapper() {
    if [ ! -d "$HOME/wine_hangover" ]; then
        echo -e "${RED}Wine Hangover must be installed first to change the wrapper.${NC}"
        read -p " Press Enter to return to Settings menu. . . "
        settings_menu
    fi

    echo -e "${BLUE}Choose a Wrapper Version:${NC}"
    echo -e "${CYAN}1)${NC} mesa-vulkan-icd-wrapper (24.2.5-12) ( Latest Will Not Work On Some Devices )"
    echo -e "${CYAN}2)${NC} mesa-vulkan-icd-wrapper (24.2.5-9) ( Default )"
    echo -e "${CYAN}3)${NC} mesa-vulkan-icd-wrapper (24.2.5-11)"
    echo -e "${CYAN}4)${NC} Cancel"
    echo ""

    read -p "Enter your choice: " wrapper_choice

    case $wrapper_choice in
        1)
            wget -q --show-progress -O ~/mesalatest.deb https://github.com/Fcharan/WinlatorMali/releases/download/0.0/mesalatest.deb
            dpkg -i ~/mesalatest.deb
            ;;
        2)
            wget -q --show-progress -O ~/mesa.deb https://github.com/Fcharan/WinlatorMali/releases/download/0.0/mesa.deb
            dpkg -i ~/mesa.deb
            ;;
        3)
            wget -q --show-progress -O ~/mesa2.deb https://github.com/Fcharan/WinlatorMali/releases/download/0.0/mesa2.deb
            dpkg -i ~/mesa2.deb
            ;;
        4)   
            settings_menu
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 1
            change_native_wrapper
            ;;
    esac

    read -p " Press Enter to return to Settings menu. . . "
    settings_menu
}

change_resolution() {
    if [ ! -d "$HOME/wine_hangover" ]; then
        echo -e "${RED}Wine Hangover must be installed first to change resolution.${NC}"
        read -p " Press Enter to return to Settings menu. . . "
        settings_menu
    fi

    echo -e "${BLUE}Choose a Resolution:${NC}"
    echo -e "${CYAN}1)${NC} 1280x720 (HD)"
    echo -e "${CYAN}2)${NC} 1920x1080 (Full HD)"
    echo -e "${CYAN}3)${NC} 1600x900 (HD+)"
    echo -e "${CYAN}4)${NC} Custom Resolution"
    echo -e "${CYAN}5)${NC} Cancel"
    echo ""

    read -p "Enter your choice: " res_choice

    case $res_choice in
        1) selected_res="1280x720" ;;
        2) selected_res="1920x1080" ;;
        3) selected_res="1600x900" ;;
        4) 
            read -p "Enter custom resolution (e.g., 1024x768): " custom_res
            
            if [[ ! $custom_res =~ ^[0-9]+x[0-9]+$ ]]; then
                echo -e "${RED}Invalid resolution format. Use WIDTHxHEIGHT (e.g., 1024x768)${NC}"
                read -p " Press Enter to return to Settings menu. . . "
                settings_menu
                return
            fi
            selected_res="$custom_res"
            ;;
        5) settings_menu; return ;;
        *) 
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 1
            change_resolution
            return
            ;;
    esac
    
    sed -i "s|explorer /desktop=shell,1280x720 explorer|explorer /desktop=shell,$selected_res explorer|g" "$0"

    echo -e "${GREEN}Resolution set to $selected_res${NC}"
    read -p " Press Enter to return to Settings menu. . . "
    settings_menu
}

check_script_updates() {
    echo -e "${BLUE}Checking for script updates...${NC}"
    
    TEMP_SCRIPT=$(mktemp)
    
    if wget -q --show-progress -O "$TEMP_SCRIPT" https://github.com/Fcharan/WinlatorMali/releases/download/0.0/wine_hangover_menu.sh; then
        
        if ! cmp -s "$0" "$TEMP_SCRIPT"; then
            echo -e "${YELLOW}Update available! ( Warning Do Not Update Until The Author Say To Do ! )${NC}"
            
            read -p "Do you want to update the script? (y/n): " update_choice
            
            case $update_choice in
                [Yy]|[Yy][Ee][Ss])
                    
                    cp "$0" "$0.bak"
                    
                    mv "$TEMP_SCRIPT" "$0"
                    
                    chmod +x "$0"
                    
                    echo -e "${GREEN}Script updated successfully! Old script backed up as $0.bak${NC}"
                    
                    read -p "Press Enter to restart the script..." 
                    exec bash "$0"
                    ;;
                *)
                    echo -e "${YELLOW}Update cancelled. Keeping current script.${NC}"
                    rm "$TEMP_SCRIPT"
                    ;;
            esac
        else
            echo -e "${GREEN}Your script is already up to date.${NC}"
            rm "$TEMP_SCRIPT"
        fi
    else
        echo -e "${RED}Failed to download update. Check your internet connection.${NC}"
        rm -f "$TEMP_SCRIPT"
    fi
    
    read -p "Press Enter to return to Settings menu. . . "
    settings_menu
}

main_menu