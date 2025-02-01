#! /bin/bash

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

# Fungsi untuk mengubah domain
change_domain() {
    check_running_as_root
    colorized_echo blue "Memulai proses pergantian domain..."
    
    # Dapatkan IP publik saat ini
    current_ip=$(curl -s https://ipinfo.io/ip)
    if [ -z "$current_ip" ]; then
        colorized_echo red "Tidak dapat menemukan IP publik saat ini."
        exit 1
    fi

    while true; do
        # Minta pengguna memasukkan domain baru
        read -rp "Masukkan Domain Baru: " new_domain
        
        # Simpan domain baru
        echo "$new_domain" > /etc/data/domain
        
        # Dapatkan IP dari domain baru
        domain_ip=$(dig +short "$new_domain" | grep '^[.0-9]*$' | head -n 1)

        if [ -z "$domain_ip" ]; then
            colorized_echo red "Tidak dapat menemukan IP untuk domain: $new_domain"
        elif [ "$domain_ip" != "$current_ip" ]; then
            colorized_echo yellow "IP domain ($domain_ip) tidak sama dengan IP publik saat ini ($current_ip)."
        else
            colorized_echo green "IP domain ($domain_ip) sama dengan IP publik saat ini ($current_ip)."
            break
        fi

        echo "Silakan masukkan ulang domain."
    done

    # Update database dengan domain baru
    cd /var/lib/marzban
    DB_NAME="db.sqlite3"

    if [ ! -f "$DB_NAME" ]; then
        colorized_echo red "Database $DB_NAME tidak ditemukan!"
        exit 1
    fi

    # Update semua entri domain dalam database
    SQL_QUERY="UPDATE hosts SET address = '$new_domain' WHERE 1=1; UPDATE hosts SET host = '$new_domain' WHERE 1=1; UPDATE hosts SET sni = '$new_domain' WHERE 1=1;"
    sqlite3 "$DB_NAME" "$SQL_QUERY"

    if [ $? -eq 0 ]; then
        colorized_echo green "Database berhasil diperbarui dengan domain baru."
    else
        colorized_echo red "Gagal memperbarui database."
        exit 1
    fi

    # Stop layanan
    cd /opt/marzban
    docker compose down

    # Generate ulang SSL certificate untuk domain baru
    mkdir -p /var/lib/marzban/certs
    /root/.acme.sh/acme.sh --server letsencrypt --register-account -m admin@lumine.my.id --issue -d $new_domain --standalone -k ec-256
    ~/.acme.sh/acme.sh --installcert -d $new_domain --fullchainpath /var/lib/marzban/certs/xray.crt --keypath /var/lib/marzban/certs/xray.key --ecc

    # Restart layanan
    cd /opt/marzban
    docker compose up -d

    sleep 3
    profile
    echo ""
    colorized_echo green "Domain berhasil diubah ke $new_domain"
    colorized_echo yellow "Silakan tunggu beberapa menit agar perubahan tersimpan sepenuhnya"
}

# Jalankan fungsi utama
change_domain