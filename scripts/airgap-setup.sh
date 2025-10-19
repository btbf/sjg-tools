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
        echo "一般ユーザーで再度実行してください"
        exit 1
    fi

    #環境変数確認
    if [[ -d ${NODE_HOME} ]]; then
        echo export NODE_HOME=$HOME/cnode >> $HOME/.bashrc
        echo export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" >> $HOME/.bashrc
        echo alias airgap="'cd $NODE_HOME; tar -xOzf airgap-set.tar.gz airgap_script | bash -s verify'" >> $HOME/.bashrc
        echo "環境変数を設定しました。"
        mkdir -p $NODE_HOME
        echo "プール作業ディレクトリを作成しました"
        echo $NODE_HOME
    else
        echo "環境変数は設定済みです"
    fi

    #cardano-cliインストール
    source <(curl -fsSL https://raw.githubusercontent.com/btbf/sjg-tools/refs/heads/main/scripts/components/node_install)
    nodeBinary_URL="https://github.com/IntersectMBO/cardano-node/releases/download/${recommend_node_version}/cardano-node-${recommend_node_version}-linux.tar.gz"
    wget --spider -q "$nodeBinary_URL"
    local status=$?
    if [ $status -eq 0 ]; then
        echo -e "${YELLOW}ノードインストール開始${NC}"
        mkdir -p ${HOME}/git/cardano-node
        cd ${HOME}/git/cardano-node || exit
        wget -q "$nodeBinary_URL"
        tar zxvf "cardano-node-${recommend_node_version}-linux.tar.gz" ./bin/cardano-cli > /dev/null 2>&1
        sudo cp "$(find ${HOME}/git/cardano-node -type f -name "cardano-cli")" /usr/local/bin/cardano-cli
        echo -e "${GREEN}cardano-cliをインストールしました${NC}"
        echo -e "${GREEN}バージョン: $(cardano-cli --version | head -n 1)${NC}"
    else
        echo -e "${RED}cardano-cliのダウンロードに失敗しました。 インターネット接続を確認してください。${NC}"
        exit 1
    fi

    DotSpinner3 "エアギャップ初期設定を終了します"
    echo
    echo -e "${RED}①下記コマンドを実行して環境変数を再読み込みしてください${NC}"
    echo "------------------------"
    echo "source $HOME/.bashrc"
    echo "------------------------"
}

Main




