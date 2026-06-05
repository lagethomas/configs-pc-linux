#!/bin/bash
# install.sh - Instalador de ambiente para automação de tarefas

# Variáveis de ambiente
SRC_DIR=$(pwd)
DEST_BIN="$HOME/bin"
DEST_ALIASES="$HOME/.bash_aliases"

echo "[*] Iniciando instalação do ambiente..."

# 1. Configurar diretório de binários
mkdir -p "$DEST_BIN"

# 2. Processar todos os scripts na pasta bin/ de forma dinâmica
echo "[+] Sincronizando scripts em $DEST_BIN..."
for script in "$SRC_DIR/bin/"*; do
    if [ -f "$script" ]; then
        filename=$(basename "$script")
        cp "$script" "$DEST_BIN/$filename"
        chmod +x "$DEST_BIN/$filename" # Garante permissão de execução[cite: 1]
        echo "    * Script instalado: $filename"
    fi
done

# 3. Instalar/Atualizar aliases
# O uso de \$USER garante que o alias seja escrito corretamente no arquivo final[cite: 1]
echo "[+] Configurando aliases em $DEST_ALIASES..."
cat "$SRC_DIR/.bash_aliases" > "$DEST_ALIASES"
source ~/.bash_aliases

# 4. Verificação de PATH
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo "[!] AVISO: $DEST_BIN não está no seu PATH."
    echo "    Corrigindo automaticamente..."
    if ! grep -q "export PATH=\"\$HOME/bin:\$PATH\"" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# Adicionado por configs-pc-linux/install.sh" >> "$HOME/.bashrc"
        echo "export PATH=\"\$HOME/bin:\$PATH\"" >> "$HOME/.bashrc"
        echo "[+] $DEST_BIN adicionado ao PATH em ~/.bashrc"
    else
        echo "[~] $DEST_BIN já configurado em ~/.bashrc (pulando)"
    fi
    export PATH="$HOME/bin:$PATH"
fi

echo "[OK] Instalação concluída. Recarregando shell..."

exec "$SHELL"
