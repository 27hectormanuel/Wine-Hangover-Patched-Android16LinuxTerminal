#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

HANGOVER_INSTALL_FLAG="$HOME/.wine_hangover_installed.txt"
HUD_CONFIG_FILE="$HOME/.wine_hangover_hud.conf"

CONTAINER_BASE="$HOME/.wine_containers"
DEFAULT_CONTAINER="default"
CURRENT_CONTAINER_FILE="$HOME/.current_wine_container"

clear_and_center() {
    clear
    printf '\033[8;50;100t'
    printf '\033[3;0;0t'
    printf '\033[9;1t'
}

check_dependencies() {
    local deps=(wget tar dpkg)
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}Missing required dependencies: ${missing[*]}${NC}"
        echo -e "${YELLOW}Installing missing dependencies...${NC}"
        sudo apt install -y "${missing[@]}"
    fi
}

check_system_requirements() {
    local available_storage=$(df -h "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if (( $(echo "$available_storage < 2" | bc -l) )); then
        echo -e "${RED}Warning: Less than 2GB storage available. Installation may fail.${NC}"
        read -p "Continue anyway? (y/n): " choice
        [[ $choice != "y" ]] && exit 1
    fi
    
    if [ "$(uname -m)" != "aarch64" ]; then
        echo -e "${RED}Error: This script requires an ARM64 device.${NC}"
        exit 1
    fi
}

initialize_hud_config() {
    if [ ! -f "$HUD_CONFIG_FILE" ]; then
        echo "MANGOHUD=1" > "$HUD_CONFIG_FILE"
        echo "DXVK_HUD=fps,version,devinfo" >> "$HUD_CONFIG_FILE"
    fi
}

toggle_hud() {
    initialize_hud_config

    echo -e "${BLUE}HUD Configuration:${NC}"
    echo -e "${CYAN}1)${NC} Toggle MangoHUD"
    echo -e "${CYAN}2)${NC} Toggle DXVK HUD"
    echo -e "${CYAN}3)${NC} Back to Settings Menu"
    echo ""

    read -p "Enter your choice: " hud_choice

    case $hud_choice in
        1)
            if grep -q "MANGOHUD=1" "$HUD_CONFIG_FILE"; then
                sed -i 's/MANGOHUD=1/MANGOHUD=0/' "$HUD_CONFIG_FILE"
                echo -e "${YELLOW}MangoHUD disabled.${NC}"
            else
                sed -i 's/MANGOHUD=0/MANGOHUD=1/' "$HUD_CONFIG_FILE"
                echo -e "${GREEN}MangoHUD enabled.${NC}"
            fi
            ;;
        2)
            if grep -q "DXVK_HUD=fps,version,devinfo" "$HUD_CONFIG_FILE"; then
                sed -i 's/DXVK_HUD=fps,version,devinfo/DXVK_HUD=0/' "$HUD_CONFIG_FILE"
                echo -e "${YELLOW}DXVK HUD disabled.${NC}"
            else
                sed -i 's/DXVK_HUD=0/DXVK_HUD=fps,version,devinfo/' "$HUD_CONFIG_FILE"
                echo -e "${GREEN}DXVK HUD enabled.${NC}"
            fi
            ;;
        3)
            settings_menu
            return
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 1
            toggle_hud
            return
            ;;
    esac

    read -p "Press Enter to continue..."
    toggle_hud
}

start_container_menu() {
    if [ ! -f "$HANGOVER_INSTALL_FLAG" ]; then
        echo -e "${RED}Wine Hangover is not installed. Please install it first.${NC}"
        read -p "Press Enter to return to main menu..."
        main_menu
        return
    fi

    while true; do
        clear_and_center
        echo -e "${BLUE}┌───────────────────────────────────────────┐"
        echo -e "│           Container Management           │"
        echo -e "└───────────────────────────────────────────┘${NC}"
        echo ""

        if [ ! -d "$CONTAINER_BASE" ]; then
            mkdir -p "$CONTAINER_BASE/$DEFAULT_CONTAINER"
            echo "$DEFAULT_CONTAINER" > "$CURRENT_CONTAINER_FILE"
        fi

        current_container=$(cat "$CURRENT_CONTAINER_FILE" 2>/dev/null || echo "$DEFAULT_CONTAINER")
        if [ ! -d "$CONTAINER_BASE/$current_container" ]; then
            current_container="$DEFAULT_CONTAINER"
            echo "$DEFAULT_CONTAINER" > "$CURRENT_CONTAINER_FILE"
        fi

        echo -e "${GREEN}Current container:${NC} $current_container"
        echo ""
        echo -e "${GREEN}Available containers:${NC}"

        local containers=()
        local i=1

        for container in "$CONTAINER_BASE"/*/; do
            [ -d "$container" ] || continue
            container_name=$(basename "$container")
            containers+=("$container_name")
            if [ "$container_name" == "$current_container" ]; then
                echo -e "${CYAN}$i)${NC} $container_name ${GREEN}(Current)${NC}"
            else
                echo -e "${CYAN}$i)${NC} $container_name"
            fi
            ((i++))
        done

        if [ "${#containers[@]}" -eq 0 ]; then
            echo -e "${RED}No containers available.${NC}"
        fi

        echo ""
        echo -e "${GREEN}Options:${NC}"
        echo -e "${CYAN}n)${NC} Create New Container"
        echo -e "${CYAN}d)${NC} Delete Container"
        echo -e "${CYAN}b)${NC} Back to Main Menu"
        echo ""

        read -p "Select container to manage (or choose option): " selection

        case $selection in
            [Nn])
                read -p "Enter new container name: " new_container
                mkdir -p "$CONTAINER_BASE/$new_container"
                echo "$new_container" > "$CURRENT_CONTAINER_FILE"
                read -p "Do you want to start the container? (y/n): " start_choice
                if [[ "$start_choice" =~ ^[Yy]$ ]]; then
                    start_wine_hangover "$new_container"
                fi
                ;;
            [Dd])
                read -p "Enter container name to delete: " del_container
                if [ "$del_container" == "$current_container" ]; then
                    echo -e "${RED}Cannot delete the currently selected container.${NC}"
                elif [ -d "$CONTAINER_BASE/$del_container" ]; then
                    rm -rf "$CONTAINER_BASE/$del_container"
                    echo -e "${GREEN}Container deleted successfully.${NC}"
                else
                    echo -e "${RED}Container not found.${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            [Bb])
                main_menu
                return
                ;;
            *)
                if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#containers[@]}" ]; then
                    selected_container="${containers[$selection-1]}"
                    if [ -d "$CONTAINER_BASE/$selected_container" ]; then
                        echo "$selected_container" > "$CURRENT_CONTAINER_FILE"
                        read -p "Do you want to start '$selected_container'? (y/n): " start_choice
                        if [[ "$start_choice" =~ ^[Yy]$ ]]; then
                            start_wine_hangover "$selected_container"
                        fi
                    else
                        echo -e "${RED}Selected container no longer exists.${NC}"
                        read -p "Press Enter to continue..."
                    fi
                else
                    echo -e "${RED}Invalid selection.${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
        esac
    done
}

install_libvulkan() {
    echo -e "${BLUE}Installing libvulkan_wrapper.so for containers${NC}"

    if [ ! -d "$CONTAINER_BASE" ]; then
        echo -e "${RED}No container system found. Please set up containers first.${NC}"
        read -p "Press Enter to return to Settings menu..."
        settings_menu
        return
    fi

    current_container=$(cat "$CURRENT_CONTAINER_FILE" 2>/dev/null || echo "$DEFAULT_CONTAINER")
    TARGET_LIB_DIR="$CONTAINER_BASE/$current_container/lib"

    mkdir -p "$TARGET_LIB_DIR"

    if wget -q --show-progress -O "$TARGET_LIB_DIR/libvulkan_wrapper.so" https://github.com/Fcharan/WinlatorMali/releases/download/0.0/libvulkan_wrapper.so; then
        echo -e "${GREEN}libvulkan_wrapper.so installed successfully in '$current_container'!${NC}"
        chmod 755 "$TARGET_LIB_DIR/libvulkan_wrapper.so"
    else
        echo -e "${RED}Failed to download libvulkan_wrapper.so${NC}"
        return 1
    fi

    read -p "Press Enter to return to Settings menu..."
    settings_menu
}

main_menu() {
    clear_and_center
    echo -e "${BLUE}┌───────────────────────────────────────────┐"
    echo -e "│            Wine Hangover Menu           │"
    echo -e "└───────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${GREEN}Please choose an option:${NC}"
    echo ""
    
    if [ ! -f "$HANGOVER_INSTALL_FLAG" ]; then
        echo -e "${CYAN}1)${NC} Install Wine Hangover"
    else
        echo -e "${CYAN}1)${NC} Reinstall Wine Hangover"
    fi
    
    echo -e "${CYAN}2)${NC} Start Container"
    echo -e "${CYAN}3)${NC} Settings"
    echo -e "${CYAN}4)${NC} Exit"
    echo ""
    echo -e "${BLUE}───────────────────────────────────────────${NC}"
    echo ""

    read -p "Enter your choice: " choice

    case $choice in
        1) install_wine_hangover ;;
        2) start_container_menu ;;
        3) settings_menu ;;
        4) 
           clear
           exit 0 
           ;;
        *) 
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 1
            main_menu
            ;;
    esac
}

install_wine_hangover() {
    if [ -f "$HANGOVER_INSTALL_FLAG" ]; then
        echo -e "${YELLOW}Removing existing Wine Hangover installation...${NC}"
    fi
    
    local tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT
    
    echo -e "${BLUE}Starting Wine Hangover installation...${NC}"
    check_system_requirements
    
    if ! apt update -y && apt upgrade -y -o Dpkg::Options::="--force-confold"; then
        echo -e "${RED}Failed to update package lists. Check your internet connection.${NC}"
        return 1
    fi
    
    sudo apt install -y -o Dpkg::Options::="--force-confold" tur-repo x11-repo

    sed -i '1s/$/ tur-multilib/' /data/data/com.termux/files/usr/etc/apt/sources.list.d/tur.list
    pkg update -y && pkg upgrade -y -o Dpkg::Options::="--force-confold"

    sudo apt install -y -o Dpkg::Options::="--force-confold" hangover termux-x11-*

    sudo apt install -y -o Dpkg::Options::="--force-confold" mangohud

    local packages=(
        x11-repo tur-repo freetype git gnutls libandroid-shmem-static
        libx11 xorgproto libdrm libpixman libxfixes libjpeg-turbo
        mesa-demos mesa-zink pulseaudio termux-x11-nightly vulkan-tools
        xtrans libxxf86vm xorg-xrandr xorg-font-util xorg-util-macros
        libxfont2 libxkbfile libpciaccess xcb-util-renderutil
        xcb-util-image xcb-util-keysyms xcb-util-wm xorg-xkbcomp
        xkeyboard-config libxdamage libxinerama libxshmfence
    )
    
    echo -e "${BLUE}Installing required packages...${NC}"
    local total=${#packages[@]}
    local current=0
    
    for package in "${packages[@]}"; do
        ((current++))
        echo -e "${CYAN}[$current/$total] Installing $package...${NC}"
        if ! sudo apt install -y -o Dpkg::Options::="--force-confold" "$package"; then
            echo -e "${RED}Failed to install $package${NC}"
            return 1
        fi
    done

    wget -q --show-progress -O ~/mesa.deb https://github.com/Fcharan/WinlatorMali/releases/download/0.0/mesa.deb
    dpkg -i ~/mesa.deb

    touch "$HANGOVER_INSTALL_FLAG"
    initialize_hud_config

    echo -e "${GREEN}Wine Hangover installed successfully!${NC}"
    echo -e "${YELLOW}Please restart the Termux session to apply the changes.${NC}"
    
    bash $0
}

start_wine_hangover() {
    if [ ! -f "$HANGOVER_INSTALL_FLAG" ]; then
        echo -e "${RED}Wine Hangover is not installed. Please install it first.${NC}"
        read -p " Press Enter to return to main menu. . . "
        bash $0
    fi
    
    local container_name="$1"
    export WINEPREFIX="$CONTAINER_BASE/$container_name"

    if [ ! -d "$WINEPREFIX" ]; then
        mkdir -p "$WINEPREFIX"
        echo -e "${YELLOW}Initializing new Wine prefix for container '$container_name'...${NC}"
    fi
    
    initialize_hud_config
    source "$HUD_CONFIG_FILE"

    am start -n com.termux.x11/com.termux.x11.MainActivity
    termux-x11 :0 &>/dev/null &
    pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 &>/dev/null

    export VK_ICD_FILENAMES=$PREFIX/share/vulkan/icd.d/gamefusionvk_icd.aarch64.json
    export VK_ICD_FILENAMES=$PREFIX/share/vulkan/icd.d/wrapper_icd.aarch64.json
    export MESA_VK_WSI_PRESENT_MODE=mailbox
    export MESA_VK_WSI_DEBUG=blit
    export ZINK_DEBUG=compact
    export ZINK_DESCRIPTORS=auto
    export MESA_SHADER_CACHE=512MB
    export mesa_glthread=true
    export MESA_SHADER_CACHE_DISABLE=false
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    export DISPLAY=:0
    export PULSE_SERVER=127.0.0.1
    export XDG_RUNTIME_DIR=/tmp:${TMPDIR}
    export WINEESYNC=1
    export WINEESYNC_TERMUX=1

    if [ "$MANGOHUD" = "1" ]; then
        export MANGOHUD=1
        export MANGOHUD_CONFIG=fps,ram,gpu_name,vulkan_driver,present_mode
    else
        unset MANGOHUD
        unset MANGOHUD_CONFIG
    fi

    if [ "$DXVK_HUD" = "fps,version,devinfo" ]; then
        export DXVK_HUD=fps,version,devinfo
    else
        unset DXVK_HUD
    fi

    export WINEDEBUG=-all
    export WINEDLLOVERRIDES="advapi32=n,builtin;advpack=n,builtin;amstream=n,builtin;atl=n,builtin;avicap32=n,builtin;avifil32=n,builtin;bcrypt=n,builtin;cabinet=n,builtin;cfgmgr32=n,builtin;comctl32=n,builtin;comdlg32=n,builtin;d3d8=n,builtin;d3d9=n,builtin;d3d10=n,builtin;d3d10core=n,builtin;d3d11=n,builtin;d3d12=n,builtin;d3dcompiler_43=n,builtin;d3dcompiler_47=n,builtin;dinput=n,builtin;dinput8=n,builtin;dmusic=n,builtin;dsound=n,builtin;dwmapi=n,builtin;dxgi=n,builtin;gdiplus=n,builtin;gdi32=n,builtin;glu32=n,builtin;hal=n,builtin;hlink=n,builtin;imm32=n,builtin;kernel32=n,builtin;ksuser=n,builtin;mpr=n,builtin;msacm32=n,builtin;msvcrt=n,builtin;ntdll=n,builtin;ole32=n,builtin;oleaut32=n,builtin;opengl32=n,builtin;rpcrt4=n,builtin;shell32=n,builtin;shlwapi=n,builtin;urlmon=n,builtin;user32=n,builtin;usp10=n,builtin;uxtheme=n,builtin;version=n,builtin;winex11=n,builtin;winhttp=n,builtin;winmm=n,builtin;winspool.drv=n,builtin;wldap32=n,builtin;ws2_32=n,builtin;"

    wine explorer /desktop=shell,1920x1080 explorer
    
    read -p "Press Enter to return to container menu..."
    start_container_menu
}

settings_menu() {
    clear_and_center
    echo -e "${BLUE}┌───────────────────────────────────────────┐"
    echo -e "│              Settings Menu               │"
    echo -e "└───────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${CYAN} Script Version: $SCRIPT_VERSION${NC} (${SCRIPT_DATE})"
    echo -e "${GREEN}Please choose an option:${NC}"
    echo ""
    
    if [ -f "$HANGOVER_INSTALL_FLAG" ]; then
    echo -e "${CYAN}=== Graphical Settings ===${NC}"
        echo -e "${CYAN}1)${NC} Change Native Wrapper"
        echo -e "${CYAN}2)${NC} Change Resolution"
        echo -e "${CYAN}3)${NC} Toggle HUD Options"
        echo -e "${CYAN}4)${NC} Install libvulkan.so"
        echo ""
        echo -e "${CYAN}=== Storage Settings ===${NC}"
        echo -e "${CYAN}5)${NC} Map Drives"
        echo ""
        echo -e "${CYAN}=== System Settings ===${NC}"
        echo -e "${CYAN}6)${NC} Check for Script Updates"
        echo -e "${CYAN}7)${NC} Back to Main Menu"
    fi
    
    echo ""
    echo -e "${BLUE}───────────────────────────────────────────${NC}"
    echo ""

    read -p "Enter your choice: " settings_choice

    if [ ! -f "$HANGOVER_INSTALL_FLAG" ]; then
        main_menu
        return
    fi

    case $settings_choice in
    1) change_native_wrapper ;;
    2) change_resolution ;;
    3) toggle_hud ;;
    4) install_libvulkan ;;
    5) map_drives ;;
    6) check_script_updates ;;
    7) main_menu ;;
    *) 
        echo -e "${RED}Invalid option. Please try again.${NC}"
        sleep 1
        settings_menu
        ;;
esac
}

change_native_wrapper() {
    if [ ! -f "$HANGOVER_INSTALL_FLAG" ]; then
        echo -e "${RED}Wine Hangover must be installed first to change the wrapper.${NC}"
        read -p " Press Enter to return to Settings menu. . . "
        settings_menu
    fi

    echo -e "${BLUE}Choose a Wrapper Version:${NC}"
    echo -e "${CYAN}1)${NC} GameFusion Wrapper"
    echo -e "${CYAN}2)${NC} mesa-vulkan-icd-wrapper (24.2.5-9) ( Default )"
    echo -e "${CYAN}3)${NC} mesa-vulkan-icd-wrapper (25.0.0-1) ( Latest )"
    echo -e "${CYAN}4)${NC} mesa-vulkan-icd-wrapper (24.2.5-11)"
    echo -e "${CYAN}5)${NC} Cancel"
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
            wget -q --show-progress -O ~/mesa3.deb https://github.com/Fcharan/WinlatorMali/releases/download/0.0/mesa3.deb
            dpkg -i ~/mesa3.deb
            ;;
        4) wget -q --show-progress -O ~/mesa2.deb https://github.com/Fcharan/WinlatorMali/releases/download/0.0/mesa2.deb
            dpkg -i ~/mesa2.deb
            ;;
        5)
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

map_drives() {
    clear_and_center
    echo -e "${BLUE}┌───────────────────────────────────────────┐"
    echo -e "│            Map Wine Drives               │"
    echo -e "└───────────────────────────────────────────┘${NC}"

    local current_container=$(cat "$CURRENT_CONTAINER_FILE" 2>/dev/null || echo "$DEFAULT_CONTAINER")
    local container_prefix="$CONTAINER_BASE/$current_container"

    if [ ! -d "$container_prefix" ]; then
        echo -e "${RED}No active Wine container found!${NC}"
        echo -e "${YELLOW}Please follow these steps:${NC}"
        echo -e "1. Go to the Main Menu"
        echo -e "2. Select Start Container"
        echo -e "3. Create or select a container"
        echo -e "4. Initialize the Wine prefix"
        echo -e "5. Return to this Drive Mapping option"

        read -p "Press Enter to return to Settings menu..."
        settings_menu
        return
    fi

    mkdir -p "$container_prefix/dosdevices"

    echo -e "\n${CYAN}Current Container:${NC} $current_container"
    echo -e "${GREEN}Current Drive Mappings:${NC}"

    if [ -n "$(ls -A "$container_prefix/dosdevices" 2>/dev/null)" ]; then
        ls -l "$container_prefix/dosdevices"
    else
        echo -e "${YELLOW}No drive mappings found in this container.${NC}"
    fi

    echo -e "\n${GREEN}Choose an option:${NC}"
    echo -e "${CYAN}1)${NC} Map New Drive"
    echo -e "${CYAN}2)${NC} Remove Existing Drive Mapping"
    echo -e "${CYAN}3)${NC} Back to Settings Menu"
    echo ""

    read -p "Enter your choice: " drive_choice

    case $drive_choice in
        1)
            echo -e "\n${CYAN}Available default paths:${NC}"
            echo -e "1) /sdcard/Download"
            echo -e "2) /sdcard/Documents"
            echo -e "3) /sdcard"
            echo -e "4) Custom path"
            echo ""

            read -p "Choose path option (1-4): " path_choice
            case $path_choice in
                1) source_path="/sdcard/Download" ;;
                2) source_path="/sdcard/Documents" ;;
                3) source_path="/sdcard" ;;
                4) 
                    read -p "Enter full path to map: " source_path
                    ;;
                *)
                    echo -e "${RED}Invalid option.${NC}"
                    sleep 1
                    map_drives
                    return
                    ;;
            esac

            echo -e "\n${CYAN}Common drive letters:${NC}"
            echo -e "d - Downloads"
            echo -e "e - External Storage"
            echo -e "f - Files"
            echo -e "z - Custom"
            read -p "Enter drive letter: " drive_letter

            if [[ ! "$drive_letter" =~ ^[a-zA-Z]$ ]]; then
                echo -e "${RED}Invalid drive letter. Must be a single letter.${NC}"
                read -p "Press Enter to continue..."
                map_drives
                return
            fi

            if [ ! -d "$source_path" ]; then
                echo -e "${RED}Source path does not exist.${NC}"
                read -p "Press Enter to continue..."
                map_drives
                return
            fi

            ln -sf "$source_path" "$container_prefix/dosdevices/${drive_letter}:"
            
            echo -e "${GREEN}Drive mapped successfully:${NC}"
            ls -l "$container_prefix/dosdevices"
            ;;
        
        2)
            echo -e "\n${CYAN}Available mapped drives:${NC}"
            ls -l "$container_prefix/dosdevices" | grep "^l" | awk '{print $9}'
            echo ""

            read -p "Enter drive letter to remove (e.g., d): " remove_letter
            remove_path="$container_prefix/dosdevices/${remove_letter}:"

            if [ -L "$remove_path" ]; then
                rm "$remove_path"
                echo -e "${GREEN}Drive mapping removed successfully.${NC}"
            else
                echo -e "${RED}No such drive mapping found.${NC}"
            fi
            ;;
        
        3)
            settings_menu
            return
            ;;
        
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 1
            map_drives
            ;;
    esac

    read -p "Press Enter to continue..."
    map_drives
}

change_resolution() {
    if [ ! -f "$HANGOVER_INSTALL_FLAG" ]; then
        echo -e "${RED}Wine Hangover must be installed first to change resolution.${NC}"
        read -p " Press Enter to return to Settings menu. . . "
        settings_menu
        return
    fi

    current_container=$(cat "$CURRENT_CONTAINER_FILE" 2>/dev/null || echo "$DEFAULT_CONTAINER")
    CONTAINER_CONFIG="$CONTAINER_BASE/$current_container/config.ini"

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

    mkdir -p "$(dirname "$CONTAINER_CONFIG")"
    echo "resolution=$selected_res" > "$CONTAINER_CONFIG"

    echo -e "${GREEN}Resolution set to $selected_res for container '$current_container'${NC}"
    read -p " Press Enter to return to Settings menu. . . "
    settings_menu
}

SCRIPT_VERSION="0.5.1"
SCRIPT_DATE="2025-01-29"
SCRIPT_NOTES="
• Added GameFusion Wrapper 
• Added Container System 
• Updated , Fixed , Adapted Map Drives Option To Container System
• Adapt Change Resolution And Install Libvulkan.so option to Container System 
• Reinstall Required For This Update ( Clear Termux And Reinstall )
"

check_script_updates() {
    clear_and_center
    echo -e "${BLUE}┌───────────────────────────────────────────┐"
    echo -e "│           Script Information             │"
    echo -e "└───────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${CYAN}Current Version:${NC} $SCRIPT_VERSION"
    echo -e "${CYAN}Release Date:${NC} $SCRIPT_DATE"
    echo -e "${CYAN}Release Notes:${NC}$SCRIPT_NOTES"
    echo ""
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
                    echo -e "${GREEN}Script updated successfully!${NC}"
                    echo -e "${CYAN}Backup created:${NC} $0.bak"
                    read -p "Press Enter to restart the script..."
                    exec bash "$0"
                    ;;
                *)
                    echo -e "${YELLOW}Update cancelled. Keeping current version.${NC}"
                    rm "$TEMP_SCRIPT"
                    ;;
            esac
        else
            echo -e "${GREEN}Your script is up to date (Version $SCRIPT_VERSION)${NC}"
            rm "$TEMP_SCRIPT"
        fi
    else
        echo -e "${RED}Failed to check for updates. Check your internet connection.${NC}"
        rm -f "$TEMP_SCRIPT"
    fi
    
    read -p "Press Enter to return to Settings menu..."
    settings_menu
}

main_menu
