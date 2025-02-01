#!/bin/bash

# Fungsi untuk mewarnai output
colorized_echo() {
    local color=$1
    local text=$2
    
    case $color in
        "red")
        printf "\e[91m${text}\e[0m\n";;
        "green")
        printf "\e[92m${text}\e[0m\n";;
        "yellow")
        printf "\e[93m${text}\e[0m\n";;
        "blue")
        printf "\e[94m${text}\e[0m\n";;
        *)
            echo "${text}"
        ;;
    esac
}

check_running_as_root() {
    if [ "$(id -u)" != "0" ]; then
        colorized_echo red "Perintah ini harus dijalankan sebagai root."
        exit 1
    fi
}

update_geo() {
    check_running_as_root
    
    # Mendapatkan versi terbaru
    latest=$(curl -s https://api.github.com/repos/malikshi/v2ray-rules-dat/releases/latest | grep tag_name | cut -d '"' -f 4)
    
    if [ -z "$latest" ]; then
        colorized_echo red "Gagal mendapatkan versi terbaru."
        exit 1
    fi
    
    colorized_echo blue "Versi terbaru yang tersedia: ${latest}"
    read -rp "Apakah Anda ingin melanjutkan update GeoSite dan GeoIP? (y/n): " answer
    
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        colorized_echo blue "Memulai proses update..."
        
        cd /var/lib/marzban/assets || exit
        
        # Download GeoSite
        if wget -O geosite.dat "https://github.com/malikshi/v2ray-rules-dat/releases/download/${latest}/GeoSite.dat"; then
            colorized_echo green "GeoSite berhasil diupdate!"
        else
            colorized_echo red "Gagal mengupdate GeoSite"
        fi

        # Download GeoIP
        if wget -O geoip.dat "https://github.com/malikshi/v2ray-rules-dat/releases/download/${latest}/GeoIP.dat"; then
            colorized_echo green "GeoIP berhasil diupdate!"
        else
            colorized_echo red "Gagal mengupdate GeoIP"
        fi
        
        profile
        echo ""
        colorized_echo green "GeoSite dan GeoIP berhasil diupdate!"
    else
        colorized_echo yellow "Update dibatalkan."
    fi
}

# Jalankan fungsi update_geo
update_geo

