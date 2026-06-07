#!/bin/bash
# install.sh - Instalador de ambiente para automação de tarefas

# Cores
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
CIANO='\033[0;36m'
VERMELHO='\033[0;31m'
MAGENTA='\033[0;35m'
RESET='\033[0m'
BOLD='\033[1m'

# Variáveis de ambiente
SRC_DIR=$(pwd)
DEST_BIN="$HOME/bin"
DEST_ALIASES="$HOME/.bash_aliases"

echo -e "${AZUL}${BOLD}╔════════════════════════════════════════╗${RESET}"
echo -e "${AZUL}${BOLD}║     Instalador de Ambiente Linux      ║${RESET}"
echo -e "${AZUL}${BOLD}╚════════════════════════════════════════╝${RESET}"
echo ""

# 1. Configurar diretório de binários
mkdir -p "$DEST_BIN"

# 2. Processar todos os scripts na pasta bin/ de forma dinâmica
echo -e "${CIANO}┌─ ${BOLD}Scripts de execução${RESET}${CIANO} ──────────────────────┐${RESET}"
echo -e "${CIANO}Sincronizando scripts em ${BOLD}$DEST_BIN${RESET}"
for script in "$SRC_DIR/bin/"*; do
    if [ -f "$script" ]; then
        filename=$(basename "$script")
        cp "$script" "$DEST_BIN/$filename"
        chmod +x "$DEST_BIN/$filename"
        echo -e "  ${VERDE}✓${RESET} $filename"
    fi
done
echo -e "${CIANO}└────────────────────────────────────────────┘${RESET}"

# 3. Instalar/Atualizar aliases
echo -e "${MAGENTA}┌─ ${BOLD}Aliases do terminal${RESET}${MAGENTA} ─────────────────────┐${RESET}"
echo -e "${MAGENTA}Instalando aliases em ${BOLD}$DEST_ALIASES${RESET}"
cat "$SRC_DIR/.bash_aliases" > "$DEST_ALIASES"
source ~/.bash_aliases
echo -e "  ${VERDE}✓${RESET} Aliases atualizados"
echo -e "${MAGENTA}└────────────────────────────────────────────┘${RESET}"

# 4. Verificação de PATH
echo -e "${AMARELO}┌─ ${BOLD}Configuração de PATH${RESET}${AMARELO} ───────────────────┐${RESET}"
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo -e "  ${AMARELO}⚠${RESET} $DEST_BIN não está no PATH"
    echo -e "  ${AMARELO}Corrigindo automaticamente...${RESET}"
    if ! grep -q "export PATH=\"\$HOME/bin:\$PATH\"" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# Adicionado por configs-pc-linux/install.sh" >> "$HOME/.bashrc"
        echo "export PATH=\"\$HOME/bin:\$PATH\"" >> "$HOME/.bashrc"
        echo -e "  ${VERDE}✓${RESET} PATH adicionado ao ~/.bashrc"
    else
        echo -e "  ${CIANO}⊡${RESET} PATH já configurado em ~/.bashrc"
    fi
    export PATH="$HOME/bin:$PATH"
else
    echo -e "  ${VERDE}✓${RESET} $DEST_BIN já está no PATH"
fi
echo -e "${AMARELO}└────────────────────────────────────────────┘${RESET}"

# 5. Executar scripts de instalação (com confirmação)
echo ""
echo -e "${VERDE}${BOLD}╔════════════════════════════════════════╗${RESET}"
echo -e "${VERDE}${BOLD}║      Etapa de Instalação Adicional    ║${RESET}"
echo -e "${VERDE}${BOLD}╚════════════════════════════════════════╝${RESET}"
echo ""
for script in "$SRC_DIR/install/"*; do
    if [ -f "$script" ]; then
        filename=$(basename "$script")
        descricao=$(sed -n '3p' "$script" | sed 's/# //')
        echo -e "${CIANO}┌─────────────────────────────────────────┐${RESET}"
        echo -e "${CIANO}│${RESET} ${BOLD}$filename${RESET}"
        echo -e "${CIANO}│${RESET} $descricao"
        echo -e "${CIANO}└─────────────────────────────────────────┘${RESET}"
        echo -e "${AMARELO}❓ Deseja instalar?${RESET}"
        read -rp "$(echo -e "  ${BOLD}(s/N)${RESET} ")" confirm
        if [[ "$confirm" =~ ^[sS]$ ]]; then
            echo -e "  ${AZUL}▶ Executando $filename...${RESET}"
            echo ""
            bash "$script"
            echo ""
            echo -e "  ${VERDE}✓${RESET} $filename finalizado"
        else
            echo -e "  ${CIANO}⊡${RESET} $filename pulado"
        fi
        echo ""
    fi
done

echo -e "${VERDE}${BOLD}╔════════════════════════════════════════╗${RESET}"
echo -e "${VERDE}${BOLD}║       Instalação concluída! 🚀        ║${RESET}"
echo -e "${VERDE}${BOLD}╚════════════════════════════════════════╝${RESET}"
echo -e "${AZUL}Recarregando shell...${RESET}"

exec "$SHELL"
