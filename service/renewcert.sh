#! /bin/bash

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
        "magenta")
        printf "\e[95m${text}\e[0m\n";;
        "cyan")
        printf "\e[96m${text}\e[0m\n";;
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

setup_domain() {
    colorized_echo blue "Menyiapkan domain"
    current_ip=$(curl -s https://ipinfo.io/ip)
    if [ -z "$current_ip" ]; then
        colorized_echo red "Tidak dapat menemukan IP publik saat ini."
        exit 1
    fi

    while true; do
        # Minta pengguna memasukkan domain
        mkdir -p /etc/data
        read -rp "Masukkan Domain: " domain
        echo "$domain" > /etc/data/domain
        domain=$(cat /etc/data/domain)

        # Dapatkan IP dari domain
        domain_ip=$(dig +short "$domain" | grep '^[.0-9]*$' | head -n 1)

        if [ -z "$domain_ip" ]; then
            colorized_echo red "Tidak dapat menemukan IP untuk domain: $domain"
        elif [ "$domain_ip" != "$current_ip" ]; then
            colorized_echo yellow "IP domain ($domain_ip) tidak sama dengan IP publik saat ini ($current_ip)."
        else
            colorized_echo green "IP domain ($domain_ip) sama dengan IP publik saat ini ($current_ip)."
            colorized_echo green "Domain berhasil digunakan."
            break
        fi

        echo "Silakan masukkan ulang domain."
    done
}

renew_cert() {
    colorized_echo blue "Memperbarui sertifikat SSL"
    
    # Pastikan berjalan sebagai root
    check_running_as_root
    
    # Setup domain baru
    setup_domain
    
    # Hapus sertifikat lama
    rm -rf /var/lib/marzban/certs/*
    
    # Buat direktori jika belum ada
    mkdir -p /var/lib/marzban/certs
    
    # Stop layanan
    cd /opt/marzban
    docker compose down

    # Perbarui sertifikat
    ~/.acme.sh/acme.sh --server letsencrypt --register-account -m admin@lumine.my.id --issue -d $domain --standalone -k ec-256 --force
    ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /var/lib/marzban/certs/xray.crt --keypath /var/lib/marzban/certs/xray.key --ecc --force
    # Restart layanan
    cd /opt/marzban
    docker compose up -d

    sleep 3
    profile

    colorized_echo green "Sertifikat berhasil diperbarui untuk domain: $domain"
}

# Jalankan fungsi renew_cert
renew_cert

