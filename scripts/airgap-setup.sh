#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2086,SC1001,SC2317
# shellcheck source="$HOME/.bashrc"

clear
spokit_version="$(curl -s https://api.github.com/repos/btbf/sjg-tools/releases/latest | jq -r '.tag_name')"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\e[36m'
PURPLE='\e[35m'
YELLOW='\e[33m'
BLUE='\e[34m'
WHITE='\e[37m'
BOLD='\e[1m'
UNDERLINE='\e[4m'
NC='\033[0m' # No Color



view_title_logo(){
    echo -e "${CYAN}"
    cat << "EOF"
███████╗██████╗  ██████╗ ██╗  ██╗██╗████████╗
██╔════╝██╔══██╗██╔═══██╗██║ ██╔╝██║╚══██╔══╝
███████╗██████╔╝██║   ██║█████╔╝ ██║   ██║   
╚════██║██╔═══╝ ██║   ██║██╔═██╗ ██║   ██║   
███████║██║     ╚██████╔╝██║  ██╗██║   ██║   
╚══════╝╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝ 
EOF
    echo -e "${NC}"
    echo -e "${GREEN}                   ${1}                    ${NC}"
    echo -e "${WHITE}============================================${NC}"
    echo -e "${CYAN}           Cardano SPO Tool Kit              ${NC}"
    echo -e "${YELLOW}         ${2}                           ${NC}"
    echo -e "${WHITE}============================================${NC}"
}



Main(){
    view_title_logo "${spokit_version}" "エアギャップマシンセットアップ"

    if [[ $whoami = "root" ]]; then
        echo -e "${RED}rootユーザーでは実行できません${NC}"
        exit 1
    fi

    #環境変数確認
    if [[ -z ${NODE_HOME} ]]; then
        echo export NODE_HOME=$HOME/cnode >> $HOME/.bashrc
        echo export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" >> $HOME/.bashrc
        echo alias airgap="'cd $NODE_HOME; tar -xOzf airgap-set.tar.gz airgap_script | bash -s verify'" >> $HOME/.bashrc
        source $HOME/.bashrc
        echo "環境変数を設定しました。"
        mkdir -p $NODE_HOME
        echo "プール作業ディレクトリを作成しました"
        echo $NODE_HOME
    else
        echo "環境変数は設定済みです。"
    fi
}

Main




