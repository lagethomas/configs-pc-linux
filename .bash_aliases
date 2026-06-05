## Meus aliases - Configurações de sistema e produtividade. Criar arquivo .bash_aliases

# Exibe o arquivo de aliases formatado como um manual colorido
alias ajuda='batcat --language=bash --paging=never ~/.bash_aliases'

# Atualiza a lista de pacotes dos repositórios
alias update='sudo apt update'

# Atualiza os pacotes instalados para as versões mais recentes
alias upgrade='sudo apt upgrade'

# Visualiza arquivos com syntax highlighting (usando batcat)
alias cat='batcat'

# Instala um novo pacote via APT
alias install='sudo apt install'

# Remove um pacote via APT
alias remove='sudo apt remove'

# Exibe endereços IP de forma colorida, breve e em colunas
alias ips='ip -c -br a'

# Sobe um nível na árvore de diretórios
alias ..='cd ..'

# Pesquisa por termos específicos no histórico de comandos
alias gh='history|grep'

# Lista arquivos usando eza (substituto moderno e colorido do ls)
alias ls='eza'

# Exibe todas as portas TCP/UDP abertas e os processos associados
alias ports='sudo ss -tulanp'

# Lista o ID (PID) e o nome de processos ativos que coincidem com a busca
alias pg='pgrep -l'

# Shadow Sockets
alias ss='/home/$USER/bin/ss.sh'

# Remmina Manager
alias rmn='/home/$USER/bin/remmina_manager.sh'

# VPN Backup Sistema Linux com NetworkManager.
alias vpn='/home/$USER/bin/vpn-backup-restore.sh'
