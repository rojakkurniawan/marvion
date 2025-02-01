#!/bin/bash

# Mengambil domain dan token dari file konfigurasi
domain=$(cat /etc/data/domain)
token=$(cat /etc/data/token.json | jq -r .access_token)

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export LIGHT='\033[0;37m'
export NC='\033[0m'

export ERROR="[${RED} ERROR ${NC}]"
export INFO="[${YELLOW} INFO ${NC}]"
export OKEY="[${GREEN} OKEY ${NC}]"
export PENDING="[${YELLOW} PENDING ${NC}]"
export SEND="[${YELLOW} SEND ${NC}]"
export RECEIVE="[${YELLOW} RECEIVE ${NC}]"

check_nginx_status() {
    if [[ $(netstat -ntlp | grep -i nginx | grep -i 0.0.0.0:443 | awk '{print $4}' | cut -d: -f2 | xargs | sed -e 's/ /, /g') == '443' ]]; then
        echo "${GREEN}Okay${NC}"
    else
        echo "${RED}Not Okay${NC}"
    fi
}

check_marzban_status() {
    if [[ $(netstat -ntlp | grep -i python | grep -i "127.0.0.1:8000" | awk '{print $4}' | cut -d: -f2 | xargs | sed -e 's/ /, /g') == "8000" ]]; then
        echo "${GREEN}Okay${NC}"
    else
        echo "${RED}Not Okay${NC}"
    fi
}

check_ufw_status() {
    if [[ $(systemctl status ufw | grep -w Active | awk '{print $2}' | sed 's/(//g' | sed 's/)//g' | sed 's/ //g') == 'active' ]]; then
        echo "${GREEN}Okay${NC}"
    else
        echo "${RED}Not Okay${NC}"
    fi
}
get_marzban_info() {
    local marzban_api="https://${domain}/api/system"
    local marzban_info=$(curl -s -X 'GET' "$marzban_api" -H 'accept: application/json' -H "Authorization: Bearer $token")

    if [[ $? -eq 0 ]]; then
        echo "$marzban_info" | jq -r '.version'
    else
        echo -e "${ERROR} Failed to fetch Marzban information."
        exit 1
    fi
}

get_xray_core_version() {
    local xray_core_info=$(curl -s -X 'GET' \
        "https://${domain}/api/core" \
        -H 'accept: application/json' \
        -H "Authorization: Bearer ${token}")
    echo "$xray_core_info" | jq -r '.version'
}

NGINX=$(check_nginx_status)
MARZ=$(check_marzban_status)
UFW=$(check_ufw_status)
marzban_version=$(get_marzban_info)
xray_core_version=$(get_xray_core_version)

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\E[42;1;39m            ⇱ Service Information ⇲             \E[0m"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "❇️ Marzban Version     : ${GREEN}${marzban_version}${NC}"
echo -e "❇️ XrayCore Version    : ${GREEN}${xray_core_version}${NC}"
echo -e "❇️ Nginx               : $NGINX"
echo -e "❇️ Firewall            : $UFW"
echo -e "❇️ Marzban Panel       : $MARZ"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "               MARZBAN NGINX PORT 443"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""