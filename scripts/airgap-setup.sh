#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2086,SC1001,SC2317
# shellcheck source="$HOME/.bashrc"
shopt -s expand_aliases
source ~/.bashrc 2>/dev/null

clear
spokit_version="0.4.2"

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
    if ! alias airgap >/dev/null 2>&1; then
        echo alias airgap="'cd $HOME/cnode; tar -xOzf airgap-set.tar.gz airgap_script | bash -s verify'" >> $HOME/.bashrc
        if [[ ! -d $HOME/cnode ]]; then
            echo PATH="$HOME/.local/bin:$PATH" >> $HOME/.bashrc
            echo export NODE_HOME=$HOME/cnode >> $HOME/.bashrc
            echo export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" >> $HOME/.bashrc
            mkdir -p $HOME/cnode
            echo "プール作業ディレクトリを作成しました"
            echo "$HOME/cnode"
        fi
        echo "環境変数を設定しました"
    else
        echo "環境変数は設定済みです"
    fi

    #依存関係インストール
    echo -e "${YELLOW}依存関係のインストールを開始します${NC}"
    sudo apt-get update
    sudo apt-get install -y git jq bc automake tmux htop curl build-essential pkg-config make g++ wget zstd -y
    echo -e "${GREEN}依存関係のインストールが完了しました${NC}"

    #cardano-cliインストール
    source <(curl -fsSL https://raw.githubusercontent.com/btbf/sjg-tools/refs/heads/main/scripts/spokit.library)

    echo "アーキテクチャ判定中..."
    arch=$(uname -m)
    case $arch in
        x86_64)
            nodeBinary_URL="https://github.com/IntersectMBO/cardano-node/releases/download/${recommend_node_version}/cardano-node-${recommend_node_version}-linux.tar.gz"
            extract_cmd="tar -xzf"
            ;;
        aarch64 | arm64)
            nodeBinary_URL="https://github.com/armada-alliance/cardano-node-binaries/raw/main/static-binaries/cardano-cli-10_11_0_0-aarch64-static-musl-ghc_9101.tar.zst"
            extract_cmd="tar -I zstd -xvf"
            ;;
        *)
            echo -e "${RED}サポートされていないアーキテクチャ: $arch${NC}"
            exit 1
            ;;
    esac

    echo "URL確認: $nodeBinary_URL"
    if ! wget --spider -q "$nodeBinary_URL"; then
        echo -e "${RED}cardano-cliのURL確認に失敗しました${NC}"
        exit 1
    fi

    echo -e "${YELLOW}cardano-cliのダウンロード開始...${NC}"
    mkdir -p "$HOME/git/cardano-cli"
    cd "$HOME/git/cardano-cli"
    wget -q "$nodeBinary_URL" -O cardano-cli.tar

    echo -e "${YELLOW}解凍中...${NC}"
    $extract_cmd cardano-cli.tar

    echo -e "${YELLOW}インストール中...${NC}"
    sudo cp $(find $HOME/git/cardano-node -type f -name "cardano-cli") /usr/local/bin/cardano-cli

    echo -e "${GREEN}✅ cardano-cliインストール完了${NC}"
    cardano-cli --version

    echo -e  "${YELLOW}エアギャップ初期設定を終了します${NC}"
    echo
    echo -e "${RED}①下記コマンドを実行して環境変数を再読み込みしてください${NC}"
    echo "------------------------"
    echo "source $HOME/.bashrc"
    echo "------------------------"
}

Main




