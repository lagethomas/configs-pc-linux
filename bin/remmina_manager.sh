#!/bin/bash
#
# remmina_manager.sh - Remmina Flatpak Profile Manager
#
# Description:
#   Backup and restore Remmina remote desktop profiles
#   with numeric file selection for restore.
#
# Usage:
#   ./remmina_manager.sh
#
# Options:
#   1) Backup
#   2) Restore (select from numbered list)
#   3) Exit
#

# Configurações de Caminhos
BACKUP_DIR="$HOME/backups_remmina"
mkdir -p "$BACKUP_DIR"

# Detectar instalação do Remmina (Flatpak ou nativo)
if [ -d "$HOME/.var/app/org.remmina.Remmina" ]; then
    REMMINA_DIR="$HOME/.var/app/org.remmina.Remmina"
    TIPO="Flatpak"
elif [ -d "$HOME/.local/share/remmina" ]; then
    REMMINA_DIR="$HOME/.local/share/remmina"
    TIPO="nativo"
else
    echo "[ERRO] Remmina não encontrado (nem Flatpak, nem nativo)."
    exit 1
fi

echo "--- Gerenciador Remmina ($TIPO) ---"
echo "1) Backup"
echo "2) Restore"
echo "3) Sair"
read -p "Escolha uma opção: " OPCAO

case $OPCAO in
    1)
        BACKUP_FILE="$BACKUP_DIR/remmina_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
        tar -czvf "$BACKUP_FILE" -C "$(dirname "$REMMINA_DIR")" "$(basename "$REMMINA_DIR")"
        echo -e "\n[OK] Backup criado: $BACKUP_FILE"
        ;;
    2)
        files=($(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null))
        
        if [ ${#files[@]} -eq 0 ]; then
            echo "[ERRO] Nenhum backup encontrado em $BACKUP_DIR"
            exit 1
        fi

        echo -e "\nSelecione o arquivo para restaurar:"
        for i in "${!files[@]}"; do
            echo "$((i+1)) - $(basename "${files[$i]}")"
        done

        read -p "Digite o número: " NUM
        INDEX=$((NUM-1))

        if [[ -n "${files[$INDEX]}" ]]; then
            DEST_DIR="$(dirname "$REMMINA_DIR")"
            mkdir -p "$DEST_DIR"
            tar -xzvf "${files[$INDEX]}" -C "$DEST_DIR"
            echo -e "\n[OK] Restauração concluída com sucesso."
        else
            echo "[ERRO] Opção inválida."
        fi
        ;;
    3)
        exit 0
        ;;
    *)
        echo "Opção inválida."
        ;;
esac
