#!/bin/bash

domain=$(cat /etc/data/domain)

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

get_token() {
    colorized_echo blue "Membuat token admin..."
    read -rp "Masukkan username: " ADMIN_USERNAME
    read -rsp "Masukkan password: " ADMIN_PASSWORD
    echo ""

    if grep -q "# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440" /opt/marzban/.env; then
        sed -i 's/# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440/JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 0/g' /opt/marzban/.env
    elif grep -q "# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 0" /opt/marzban/.env; then
        sed -i 's/# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 0/JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 0/g' /opt/marzban/.env
    elif grep -q "JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440" /opt/marzban/.env; then
        sed -i 's/JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440/JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 0/g' /opt/marzban/.env
    else
        sed -i 's/JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 0/JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 0/g' /opt/marzban/.env
    fi
    
    cd /opt/marzban
    docker compose down && docker compose up -d
    sleep 15s

    
    response=$(curl -s -X 'POST' \
        "https://${domain}/api/admin/token" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        -d "grant_type=password&username=${ADMIN_USERNAME}&password=${ADMIN_PASSWORD}")

    if echo "$response" | grep -q "Incorrect username or password"; then
        colorized_echo red "Error: Username atau password salah. Silakan coba lagi."
        cd /opt/marzban
        docker compose down && docker compose up -d
        sleep 15s
        return 1
    else
        echo "$response" > /etc/data/token.json
        
        if grep -q "# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440" /opt/marzban/.env; then
            sed -i 's/JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 0/# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440/g' /opt/marzban/.env
        elif grep -q "# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 0" /opt/marzban/.env; then
            sed -i 's/JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 0/# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440/g' /opt/marzban/.env
        elif grep -q "JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440" /opt/marzban/.env; then
            sed -i 's/JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 0/# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440/g' /opt/marzban/.env
        else
            sed -i 's/JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 0/# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440/g' /opt/marzban/.env
        fi

        cd /opt/marzban
        docker compose down && docker compose up -d
        sleep 15s
        profile
        echo ""
        colorized_echo green "Token berhasil disimpan di /etc/data/token.json"
    fi
}

get_token