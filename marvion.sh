#!/usr/bin/env bash
set -e

GITHUB_USERNAME="rojakkurniawan"
REPO_NAME="marvion"

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

detect_os() {
    # Mendeteksi sistem operasi
    if [ -f /etc/lsb-release ]; then
        OS=$(lsb_release -si)
    elif [ -f /etc/os-release ]; then
        OS=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
    elif [ -f /etc/redhat-release ]; then
        OS=$(cat /etc/redhat-release | awk '{print $1}')
    elif [ -f /etc/arch-release ]; then
        OS="Arch"
    else
        colorized_echo red "Sistem operasi tidak didukung"
        exit 1
    fi
}

detect_and_update_package_manager() {
    colorized_echo blue "Memperbarui package manager"
    if [[ "$OS" == "Ubuntu"* ]] || [[ "$OS" == "Debian"* ]]; then
        PKG_MANAGER="apt-get"
        $PKG_MANAGER update
    elif [[ "$OS" == "CentOS"* ]] || [[ "$OS" == "AlmaLinux"* ]]; then
        PKG_MANAGER="yum"
        $PKG_MANAGER update -y
        $PKG_MANAGER install -y epel-release
    elif [ "$OS" == "Fedora"* ]; then
        PKG_MANAGER="dnf"
        $PKG_MANAGER update
    elif [ "$OS" == "Arch" ]; then
        PKG_MANAGER="pacman"
        $PKG_MANAGER -Sy
    elif [[ "$OS" == "openSUSE"* ]]; then
        PKG_MANAGER="zypper"
        $PKG_MANAGER refresh
    else
        colorized_echo red "Sistem operasi tidak didukung"
        exit 1
    fi
}

install_package () {
    if [ -z $PKG_MANAGER ]; then
        detect_and_update_package_manager
    fi
    
    PACKAGE=$1
    colorized_echo blue "Installing $PACKAGE"
    if [[ "$OS" == "Ubuntu"* ]] || [[ "$OS" == "Debian"* ]]; then
        $PKG_MANAGER -y install "$PACKAGE"
    elif [[ "$OS" == "CentOS"* ]] || [[ "$OS" == "AlmaLinux"* ]]; then
        $PKG_MANAGER install -y "$PACKAGE"
    elif [ "$OS" == "Fedora"* ]; then
        $PKG_MANAGER install -y "$PACKAGE"
    elif [ "$OS" == "Arch" ]; then
        $PKG_MANAGER -S --noconfirm "$PACKAGE"
    else
        colorized_echo red "Sistem operasi tidak didukung"
        exit 1
    fi
}

install_necessary_tools() {
    detect_os
    install_package neofetch
    install_package ufw
    install_package sqlite3
    install_package curl
    install_package net-tools
    install_package unzip
    install_package python3-bcrypt
    
    # install socat for ssl
    install_package iptables
    install_package socat 
    install_package xz-utils
    install_package wget
    install_package apt-transport-https
    install_package gnupg
    install_package gnupg2
    install_package gnupg1
    install_package dnsutils
    install_package lsb-release
    install_package cron
    install_package bash-completion
}

install_marzban_script() {
    colorized_echo blue "Memasang skrip marzban"
    sudo bash -c "$(curl -sL https://github.com/$GITHUB_USERNAME/Marzban-scripts/raw/master/marzban.sh)" @ install
    colorized_echo green "Skrip marzban berhasil dipasang"
}

install_bbr(){
    colorized_echo blue "Memasang BBR"
    echo 'fs.file-max = 500000
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.rmem_max = 4000000
net.ipv4.tcp_mtu_probing = 1
net.ipv4.ip_forward = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr' >> /etc/sysctl.conf
    sysctl -p;
    colorized_echo green "BBR berhasil dipasang"
}

install_warp(){
    colorized_echo blue "Memasang WARP"
    wget -O /root/warp "https://raw.githubusercontent.com/hamid-gh98/x-ui-scripts/main/install_warp_proxy.sh"
    sudo chmod +x /root/warp
    sudo bash /root/warp -y 
    colorized_echo green "WARP berhasil dipasang"
}

install_vnstat(){
    colorized_echo blue "Memasang vnstat"
    install_package vnstat
    /etc/init.d/vnstat restart
    install_package libsqlite3-dev
    install_package build-essential
    wget https://github.com/$GITHUB_USERNAME/$REPO_NAME/raw/refs/heads/main/vnstat-2.6.tar.gz
    tar zxvf vnstat-2.6.tar.gz
    cd vnstat-2.6
    ./configure --prefix=/usr --sysconfdir=/etc && make && make install 
    cd
    chown vnstat:vnstat /var/lib/vnstat -R
    systemctl enable vnstat
    /etc/init.d/vnstat restart
    rm -f /root/vnstat-2.6.tar.gz 
    rm -rf /root/vnstat-2.6
    colorized_echo green "vnstat berhasil dipasang"
}

update_database(){
    colorized_echo blue "Memperbarui database"
    wget -O /var/lib/marzban/db.sqlite3 "https://github.com/$GITHUB_USERNAME/$REPO_NAME/raw/refs/heads/main/db.sqlite3"
    cd /var/lib/marzban

    # Nama database
    DB_NAME="db.sqlite3"

    if [ ! -f "$DB_NAME" ]; then
        colorized_echo red "Database $DB_NAME tidak ditemukan!"
        exit 1
    fi

    SQL_QUERY="UPDATE hosts SET address = '$domain' WHERE address = 'subdomain.domain.com'; UPDATE hosts SET host = '$domain' WHERE host = 'subdomain.domain.com'; UPDATE hosts SET sni = '$domain' WHERE sni = 'subdomain.domain.com';"

    sqlite3 "$DB_NAME" "$SQL_QUERY"

    # Periksa apakah query berhasil dijalankan
    if [ $? -eq 0 ]; then
        colorized_echo green "Update domain database berhasil dilakukan."
    else
        colorized_echo red "Gagal melakukan update domain database."
    fi
}

enable_firewall(){
    colorized_echo blue "Mengaktifkan firewall"
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https
    sudo ufw allow 4001/tcp
    sudo ufw allow 4001/udp
    yes | sudo ufw enable
    sudo systemctl restart ufw
    colorized_echo green "Firewall berhasil diaktifkan"

}

install_speedtest(){
    colorized_echo blue "Memasang speedtest"
    check_running_as_root
    if [[ "$OS" == "Ubuntu"* ]] || [[ "$OS" == "Debian"* ]]; then
        install_package curl
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
        install_package speedtest
    elif [[ "$OS" == "CentOS"* ]] || [[ "$OS" == "AlmaLinux"* ]] || [ "$OS" == "Fedora"* ]; then
        install_package curl
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | sudo bash
        install_package speedtest
    else
        colorized_echo red "Sistem operasi tidak didukung untuk instalasi speedtest"
        return 1
    fi
    
    colorized_echo green "Speedtest berhasil dipasang"
}

setup_domain() {
    detect_os
    install_package curl
    install_package dnsutils

    clear
    colorized_echo yellow "Silahkan masukkan domain panel"
    echo ""
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

install_cert(){
    colorized_echo blue "Memasang certificate untuk domain"
    mkdir -p /var/lib/marzban/certs
    curl https://get.acme.sh | sh -s email=admin@lumine.my.id
    /root/.acme.sh/acme.sh --server letsencrypt --register-account -m admin@lumine.my.id --issue -d $domain --standalone -k ec-256
    ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /var/lib/marzban/certs/xray.crt --keypath /var/lib/marzban/certs/xray.key --ecc
    colorized_echo green "Certificate berhasil dipasang"
}

install_xray(){
    colorized_echo blue "Memasang Xray"
    mkdir -p /var/lib/marzban/assets
    mkdir -p /var/lib/marzban/core
    wget -O /var/lib/marzban/core/xray.zip "https://github.com/XTLS/Xray-core/releases/download/v24.11.30/Xray-linux-64.zip"
    cd /var/lib/marzban/core && unzip xray.zip && chmod +x xray
    rm -f /var/lib/marzban/core/xray.zip
    colorized_echo green "Xray berhasil dipasang"
}

install_custom_configuration(){
    colorized_echo blue "Memasang konfigurasi custom"
    # Install .env
    wget -O /opt/marzban/.env "https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/refs/heads/main/env"

    # Install docker-compose.yml
    wget -O /opt/marzban/docker-compose.yml "https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/refs/heads/main/docker-compose.yml"

    # Install nginx.conf
    wget -O /opt/marzban/nginx.conf "https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/refs/heads/main/nginx.conf"

    # Install xray config
    wget -O /var/lib/marzban/xray_config.json "https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/refs/heads/main/xray_config.json"

    mkdir -p /var/log/nginx
    touch /var/log/nginx/access.log
    touch /var/log/nginx/error.log

    mkdir -p /var/www/html
    echo "<pre>Setup by AutoScript Marvion</pre>" > /var/www/html/index.html

    # Install subscription template
    sudo wget -N -P /var/lib/marzban/templates/subscription/ https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/refs/heads/main/index.html

    sed -i 's/# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440/JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 0/g' /opt/marzban/.env
    cd /opt/marzban
    docker compose down && docker compose up -d
    sleep 15s
    get_token

    sed -i 's/JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 0/# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440/g' /opt/marzban/.env
    cd /opt/marzban
    docker compose down && docker compose up -d
    sleep 15s
    colorized_echo green "Konfigurasi custom berhasil dipasang"
}

install_service(){
    colorized_echo blue "Memasang layanan"
    
    wget -O /usr/bin/changedomain "https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/refs/heads/main/service/changedomain.sh"
    chmod +x /usr/bin/changedomain

    wget -O /usr/bin/renewcert "https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/refs/heads/main/service/renewcert.sh"
    chmod +x /usr/bin/renewcert

    echo -e 'profile' >> /root/.profile
    wget -O /usr/bin/profile "https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/refs/heads/main/service/profile.sh"
    chmod +x /usr/bin/profile

    wget -O /usr/bin/cekservice "https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/refs/heads/main/service/cekservice.sh"
    chmod +x /usr/bin/cekservice

    wget -O /usr/bin/updategeo "https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/refs/heads/main/service/updategeo.sh"
    chmod +x /usr/bin/updategeo

    wget -O /usr/bin/menu "https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/refs/heads/main/service/menu.sh"
    chmod +x /usr/bin/menu

    wget -O /usr/bin/createtoken "https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/refs/heads/main/service/createtoken.sh"
    chmod +x /usr/bin/createtoken

    colorized_echo green "Layanan berhasil dipasang"
}

add_admin(){
    colorized_echo blue "Menambahkan admin"
    cd /var/lib/marzban

    DB_NAME="db.sqlite3"

    if [ ! -f "$DB_NAME" ]; then
        colorized_echo red "Database $DB_NAME tidak ditemukan!"
        exit 1
    fi
    
    HASHED_PASSWORD=$(python3 -c "import bcrypt; print(bcrypt.hashpw('${ADMIN_PASSWORD}'.encode(), bcrypt.gensalt(rounds=12)).decode())")

    SQL_QUERY_ADMIN="INSERT INTO admins (username, hashed_password, is_sudo, created_at) 
                        VALUES ('$ADMIN_USERNAME', '$HASHED_PASSWORD', 1, datetime('now'));"

    sqlite3 "$DB_NAME" "$SQL_QUERY_ADMIN"
    colorized_echo green "Admin berhasil ditambahkan"
}

get_token(){
    curl -X 'POST' \
  "https://${domain}/api/admin/token" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "grant_type=password&username=${ADMIN_USERNAME}&password=${ADMIN_PASSWORD}" > /etc/data/token.json
}

clean_up(){
    if command -v apt >/dev/null 2>&1; then
        apt clean
        apt autoremove -y
    elif command -v dnf >/dev/null 2>&1; then
        dnf clean all
        dnf autoremove -y
    elif command -v yum >/dev/null 2>&1; then
        yum clean all
        yum autoremove -y
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Scc --noconfirm
        pacman -Rns $(pacman -Qtdq) --noconfirm
    fi
}

admin_setup(){
    clear
    colorized_echo yellow "Silakan buat akun admin untuk panel Marzban"
    echo ""
    while true; do
        read -rp "Masukkan username admin: " ADMIN_USERNAME
        if [[ -z "$ADMIN_USERNAME" ]]; then
            colorized_echo red "Username tidak boleh kosong!"
            continue
        elif [[ ${#ADMIN_USERNAME} -lt 4 ]]; then
            colorized_echo red "Username minimal 4 karakter!"
            continue
        elif [[ ! "$ADMIN_USERNAME" =~ ^[a-zA-Z0-9_]+$ ]]; then
            colorized_echo red "Username hanya boleh mengandung huruf, angka dan underscore!"
            continue
        fi
        break
    done

    while true; do
        read -rp "Masukkan password admin: " ADMIN_PASSWORD
        if [[ -z "$ADMIN_PASSWORD" ]]; then
            colorized_echo red "Password tidak boleh kosong!"
            continue
        elif [[ ${#ADMIN_PASSWORD} -lt 8 ]]; then
            colorized_echo red "Password minimal 8 karakter!"
            continue
        elif [[ ! "$ADMIN_PASSWORD" =~ [A-Z] ]]; then
            colorized_echo red "Password harus mengandung minimal 1 huruf kapital!"
            continue
        elif [[ ! "$ADMIN_PASSWORD" =~ [a-z] ]]; then
            colorized_echo red "Password harus mengandung minimal 1 huruf kecil!"
            continue
        elif [[ ! "$ADMIN_PASSWORD" =~ [0-9] ]]; then
            colorized_echo red "Password harus mengandung minimal 1 angka!"
            continue
        fi
        break
    done
}

configure_dns() {
    colorized_echo blue "Mengkonfigurasi DNS resolver"
    
    # Backup resolv.conf yang lama jika ada
    if [ -f /etc/resolv.conf ]; then
        cp /etc/resolv.conf /etc/resolv.conf.backup
    fi

    # Hapus resolv.conf yang lama
    if [ -f /etc/resolv.conf ]; then
        sudo rm -f /etc/resolv.conf
    fi
    # Tulis konfigurasi DNS baru
    cat > /etc/resolv.conf << EOF
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 8.8.8.8
EOF
    
    
    # Verifikasi konfigurasi
    if [ -f /etc/resolv.conf ] && grep -q "nameserver" /etc/resolv.conf; then
        colorized_echo green "Konfigurasi DNS berhasil"
    else
        colorized_echo red "Gagal mengkonfigurasi DNS"
    fi
}

main() {
    colorized_echo cyan "Memulai proses instalasi..."

    check_running_as_root
    admin_setup
    setup_domain
    configure_dns
    install_necessary_tools
    timedatectl set-timezone Asia/Jakarta;
    install_speedtest
    install_vnstat
    enable_firewall
    install_marzban_script
    install_cert
    install_bbr
    install_warp
    install_xray
    update_database
    add_admin
    install_service
    install_custom_configuration

    clear
    clean_up

    profile
    echo ""
    touch /root/log-install.txt
    echo "Untuk data login dashboard Marzban: " | tee -a /root/log-install.txt
    echo "===================================" | tee -a /root/log-install.txt
    echo "URL HTTPS : https://${domain}/dashboard" | tee -a /root/log-install.txt
    echo "Username  : ${ADMIN_USERNAME}" | tee -a /root/log-install.txt
    echo "Password  : ${ADMIN_PASSWORD}" | tee -a /root/log-install.txt
    echo "===================================" | tee -a /root/log-install.txt
    echo ""
    colorized_echo green "Instalasi selesai!"
    colorized_echo yellow "Silakan gunakan perintah 'marzban' untuk mengelola layanan"
    rm /root/marvion.sh

    echo -e "\e[1;31m[WARNING]\e[0m Sistem akan reboot dalam 30 detik..."
    sleep 30
    cat /dev/null > ~/.bash_history && history -c && sudo reboot
}

# Jalankan fungsi main
main "$@"


