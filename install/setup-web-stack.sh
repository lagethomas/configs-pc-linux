#!/bin/bash
#
# web-stack-installer.sh - Web Stack Installer (aaPanel-style)
#
# Description:
#   Install or remove a complete web development stack:
#   Nginx, PHP, MariaDB, Redis, and phpMyAdmin on Debian/Ubuntu.
#
# Usage:
#   ./web-stack-installer.sh
#
# Options:
#   1) Install all (Nginx, PHP 8.4, MariaDB, Redis, phpMyAdmin)
#   2) Remove all (complete cleanup)
#   3) Exit
#
# Dependencies:
#   - Debian/Ubuntu based system
#   - sudo privileges
#

# Configurações de Versão
PHP_VER="8.4"
PMA_VER="latest"
# Novo padrão de diretório (Estilo aaPanel)
WWW_ROOT="/www/wwwroot"

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "${YELLOW}--- Gerenciador de Stack Web (Debian) ---${NC}"
    echo "1) Instalar Tudo (Nginx, PHP 8.4, MariaDB, Redis, phpMyAdmin)"
    echo "2) Remover Tudo (Limpeza completa)"
    echo "3) Sair"
    echo -n "Escolha uma opção: "
}

install_stack() {
    # Solicitar credenciais do Banco de Dados
    echo -e "${YELLOW}--- Configuração do Banco de Dados ---${NC}"
    read -p "Defina o nome do usuário admin do DB: " DB_USER
    read -s -p "Defina a senha para o usuário $DB_USER: " DB_PASS
    echo -e "\n"

    echo -e "${GREEN}[*] Atualizando repositórios...${NC}"
    sudo apt update
    sudo apt install -y lsb-release ca-certificates apt-transport-https software-properties-common gnupg curl wget unzip

    # PHP Sury Repo
    if [ ! -f /etc/apt/sources.list.d/php.list ]; then
        curl -sS https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /usr/share/keyrings/deb.sury.org-php.gpg
        echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
        sudo apt update
    fi

    echo -e "${GREEN}[*] Instalando pacotes...${NC}"
    sudo apt install -y nginx mariadb-server redis-server \
    php$PHP_VER-fpm php$PHP_VER-mysql php$PHP_VER-xml php$PHP_VER-mbstring \
    php$PHP_VER-curl php$PHP_VER-zip php$PHP_VER-gd php$PHP_VER-intl php$PHP_VER-redis

    # Configurar Usuário no MariaDB
    echo -e "${GREEN}[*] Configurando acessos no MariaDB...${NC}"
    sudo mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost' WITH GRANT OPTION;"
    sudo mysql -e "FLUSH PRIVILEGES;"

    # phpMyAdmin
    if [ ! -d /usr/share/phpmyadmin ]; then
        echo -e "${GREEN}[*] Instalando phpMyAdmin...${NC}"
        wget -q https://www.phpmyadmin.net/downloads/phpMyAdmin-$PMA_VER-all-languages.tar.gz
        tar -xzf phpMyAdmin-$PMA_VER-all-languages.tar.gz
        sudo mv phpMyAdmin-*-all-languages /usr/share/phpmyadmin
        sudo mkdir -p /var/lib/phpmyadmin/tmp
        sudo chown -R www-data:www-data /usr/share/phpmyadmin /var/lib/phpmyadmin
        rm phpMyAdmin-$PMA_VER-all-languages.tar.gz
    fi

    # Configuração de Diretórios (Padrão aaPanel)
    echo -e "${GREEN}[*] Configurando diretórios em $WWW_ROOT...${NC}"
    sudo mkdir -p "$WWW_ROOT/default/public"
    sudo chown -R www-data:www-data /www

    # Nginx VHost (Ajustado para o novo root)
    sudo tee /etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    server_name localhost;
    root $WWW_ROOT/default/public;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location /phpmyadmin {
        alias /usr/share/phpmyadmin/;
        location ~ \.php$ {
            fastcgi_pass unix:/run/php/php$PHP_VER-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$request_filename;
        }
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php$PHP_VER-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF
    sudo systemctl restart nginx php$PHP_VER-fpm
    echo -e "${GREEN}[OK] Pronto! Root em: $WWW_ROOT/default/public${NC}"
    echo -e "${GREEN}Acesse http://localhost/phpmyadmin com o usuário '$DB_USER'${NC}"
    read -p "Pressione Enter para continuar..."
}

remove_stack() {
    echo -e "${RED}[!] ATENÇÃO: Isso removerá todos os dados, bancos e a pasta $WWW_ROOT!${NC}"
    read -p "Tem certeza? (s/n): " confirm
    if [[ $confirm == [sS] ]]; then
        sudo systemctl stop nginx php$PHP_VER-fpm mariadb redis-server 2>/dev/null
        sudo apt purge -y nginx* php$PHP_VER* mariadb* redis-server*
        sudo apt autoremove -y
        sudo rm -rf /etc/nginx /etc/php/$PHP_VER /var/lib/mysql /var/lib/redis /usr/share/phpmyadmin /var/lib/phpmyadmin
        sudo rm -rf /www
        sudo rm -f /etc/apt/sources.list.d/php.list
        echo -e "${GREEN}[OK] Sistema limpo e diretório /www removido.${NC}"
    fi
    read -p "Pressione Enter para continuar..."
}

while true; do
    show_menu
    read opt
    case $opt in
        1) install_stack ;;
        2) remove_stack ;;
        3) exit 0 ;;
        *) echo "Opção inválida."; sleep 1 ;;
    esac
done
