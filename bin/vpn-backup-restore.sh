#!/bin/bash
#
# vpn-backup-restore.sh - VPN Manager Backup & Cloud Restore
#
# Description:
#   Backup and restore NetworkManager VPN connections with
#   optional Google Drive sync via rclone.
#
# Usage:
#   ./vpn-backup-restore.sh
#
# Options:
#   1) Backup (Local + GDrive)
#   2) Restore (Cloud/Local -> System)
#   0) Exit
#
# Dependencies:
#   - rclone (configured remote)
#   - sudo privileges
#

# Configurações de Diretórios e Variáveis
USUARIO=$(logname 2>/dev/null || echo $SUDO_USER)
BACKUP_DIR="/home/$USUARIO/.vpnbackup"
BACKUP_FILE="$BACKUP_DIR/vpn_backup.tar.gz"
NM_DIR="/etc/NetworkManager/system-connections"
GDRIVE_REMOTE="REMOTE_DRIVE_NAME"
GDRIVE_PATH="PATH_FOR_ARCHIVE"

# Função: Backup (Local + Cloud)
backup_vpn() {
    echo "🔐 [1/3] Filtrando conexões VPN..."
    
    sudo mkdir -p "$BACKUP_DIR"

    # Obtém apenas arquivos de VPN/Wireguard/OpenVPN ignorando Wi-Fi/Ethernet
    mapfile -t FILES < <(sudo grep -rliE "type=(vpn|wireguard|openvpn)|\[vpn\]" "$NM_DIR" | xargs -I {} basename "{}")

    if [ ${#FILES[@]} -eq 0 ]; then
        echo "⚠️  Nenhuma VPN encontrada. Abortando."
        return 1
    fi

    echo "📦 [2/3] Criando arquivo compactado..."
    if sudo tar -czf "$BACKUP_FILE" -C "$NM_DIR" "${FILES[@]}"; then
        sudo chown "$USUARIO:$USUARIO" "$BACKUP_FILE"
        echo "✅ Backup local gerado: $(basename "$BACKUP_FILE")"
        
        echo "☁️  [3/3] Sincronizando com Google Drive..."
        rclone copy "$BACKUP_FILE" "$GDRIVE_REMOTE:$GDRIVE_PATH" -v
        echo "🚀 Processo de backup finalizado com sucesso!"
    else
        echo "❌ Erro crítico ao compactar arquivos."
    fi
}

# Função: Restore (Cloud -> Local -> System)
restore_vpn() {
    echo "♻️  Iniciando restauração..."

    # Verifica se o arquivo existe localmente; se não, tenta baixar do Drive
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "🔍 Backup local não encontrado. Buscando no Google Drive..."
        rclone copy "$GDRIVE_REMOTE:$GDRIVE_PATH/$(basename "$BACKUP_FILE")" "$BACKUP_DIR/" -v
    fi

    if [ -f "$BACKUP_FILE" ]; then
        echo "📂 Extraindo arquivos para o sistema..."
        sudo tar -xzf "$BACKUP_FILE" -C "$NM_DIR"
        
        # Ajustes de permissão necessários para o NetworkManager reconhecer os arquivos
        sudo chown root:root "$NM_DIR"/*
        sudo chmod 600 "$NM_DIR"/*
        
        sudo systemctl restart NetworkManager
        echo "✅ Restore concluído. O NetworkManager foi reiniciado."
    else
        echo "❌ Falha: Arquivo de backup não localizado (Local ou Cloud)."
    fi
}

# Menu de Opções
while true; do
    echo -e "\n=========================================="
    echo "       VPN MANAGER: BACKUP & CLOUD"
    echo "=========================================="
    echo "1) Backup (Local + GDrive)"
    echo "2) Restore (Cloud/Local -> System)"
    echo "0) Sair"
    read -rp "Escolha: " OPCAO

    case "$OPCAO" in
        1) backup_vpn ;;
        2) restore_vpn ;;
        0) break ;;
        *) echo "❌ Opção inválida." ;;
    esac
done
