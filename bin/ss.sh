#!/bin/bash
#
# ss.sh - Shadowsocks Proxy Manager
#
# Description:
#   Start/stop Shadowsocks SOCKS5 proxy and automatically
#   configure system proxy settings for GNOME or KDE.
#
# Usage:
#   ./ss.sh on   # Start proxy and enable system proxy
#   ./ss.sh off  # Stop proxy and disable system proxy
#
# Dependencies:
#   - shadowsocks-libev (ss-local)
#   - gsettings (GNOME) or kwriteconfig5 (KDE)
#

SS_DIR="$HOME/shadowsocks"
CONFIG_FILE="$SS_DIR/config.json"
PID_FILE="/tmp/ss-local-custom.pid"

# Configurações do seu arquivo gui-config.json
SERVER_IP="IP_SERVER"
SERVER_PORT=8080
PASSWORD="gHOw/5S1M0vwUv7rogAYIofyRC0SEy2N"
METHOD="aes-256-gcm"
LOCAL_PORT=1080

setup() {
    [ ! -d "$SS_DIR" ] && mkdir -p "$SS_DIR"
    if ! command -v ss-local &> /dev/null; then
        sudo apt update && sudo apt install shadowsocks-libev -y
    fi

    cat <<EOF > "$CONFIG_FILE"
{
    "server": "$SERVER_IP",
    "server_port": $SERVER_PORT,
    "local_address": "127.0.0.1",
    "local_port": $LOCAL_PORT,
    "password": "$PASSWORD",
    "timeout": 10,
    "method": "$METHOD",
    "mode": "tcp_and_udp"
}
EOF
}

set_proxy() {
    echo "[+] Aplicando configurações de proxy para $XDG_CURRENT_DESKTOP..."

    # GNOME
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        gsettings set org.gnome.system.proxy mode 'manual'
        gsettings set org.gnome.system.proxy.socks host '127.0.0.1'
        gsettings set org.gnome.system.proxy.socks port $LOCAL_PORT

    # KDE Plasma
    elif [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
        kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key "ProxyType" 1
        kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key "socksProxy" "socks://127.0.0.1:$LOCAL_PORT"
        # Força o KDE a recarregar a configuração
        dbus-send --type=signal /KIO/Scheduler org.kde.KIO.Scheduler.reparseSlaveConfiguration string:''
    fi
}

unset_proxy() {
    echo "[-] Removendo configurações de proxy..."

    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        gsettings set org.gnome.system.proxy mode 'none'

    elif [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
        kwriteconfig5 --file kioslaverc --group "Proxy Settings" --key "ProxyType" 0
        dbus-send --type=signal /KIO/Scheduler org.kde.KIO.Scheduler.reparseSlaveConfiguration string:''
    fi
}

case "$1" in
    on)
        setup
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "[!] Shadowsocks já está rodando."
        else
            ss-local -c "$CONFIG_FILE" -f "$PID_FILE"
            echo "[+] Shadowsocks iniciado (PID: $(cat $PID_FILE))."
        fi
        set_proxy
        ;;
    off)
        if [ -f "$PID_FILE" ]; then
            kill $(cat "$PID_FILE") && rm "$PID_FILE"
            echo "[-] Shadowsocks parado."
        fi
        unset_proxy
        ;;
    *)
        echo "Uso: $0 {on|off}"
        exit 1
        ;;
esac
