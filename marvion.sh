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

    # install socat for ssl
    install_package iptables
    install_package curl
    install_package socat 
    install_package xz-utils
    install_package wget
    install_package apt-transport-https
    install_package gnupg
    install_package gnupg2
    install_package gnupg1
    install_package dnsutils
    install_package lsb-release
    install_package socat
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
net.ipv4.tcp_congestion_control = bbr
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
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
    colorized_echo blue "Menyiapkan domain"
    check_running_as_root
    detect_os
    install_package curl
    install_package dnsutils

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
    sudo wget -N -P /var/lib/marzban/templates/subscription/ https://raw.githubusercontent.com/x0sina/marzban-sub/main/index.html

    cd /opt/marzban
    docker compose down && docker compose up -d
    colorized_echo green "Konfigurasi custom berhasil dipasang"
}

main() {
    colorized_echo cyan "Memulai proses instalasi..."

    check_running_as_root
    setup_domain
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
    install_custom_configuration
    
    colorized_echo green "Instalasi selesai!"
    colorized_echo yellow "Silakan gunakan perintah 'marzban' untuk mengelola layanan"
}

# Jalankan fungsi main
main "$@"


