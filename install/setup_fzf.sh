#!/bin/bash

# 1. Atualizar repositórios e instalar via apt
sudo apt update
sudo apt install -y fzf

# 2. Configurar auto-completion e key bindings para o usuário atual
# O comando abaixo adiciona as linhas necessárias ao .bashrc se ainda não existirem
if ! grep -q "source /usr/share/doc/fzf/examples/key-bindings.bash" ~/.bashrc; then
    echo "source /usr/share/doc/fzf/examples/key-bindings.bash" >> ~/.bashrc
fi

if ! grep -q "source /usr/share/doc/fzf/examples/completion.bash" ~/.bashrc; then
    echo "source /usr/share/doc/fzf/examples/completion.bash" >> ~/.bashrc
fi

echo "Instalação concluída. Reinicie o terminal ou execute 'source ~/.bashrc' para aplicar."
