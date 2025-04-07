#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2086,SC1001,SC2317
# shellcheck source="$HOME/.bashrc"
# shellcheck source="${envPath}"


SPOKIT_INST_DIR=/opt/spokit
SPOKIT_HOME=$HOME/spokit
gum_version="0.15.2"

source ${HOME}/.bashrc


style(){
  echo -e '{{ Color "15" " '"$1"' " }}''{{ Color "11" " '"$2"' " }}' "\n" | gum format -t template; echo
}


CreateEnv(){
mkdir -p ${SPOKIT_HOME}
cat <<-EOF > ${SPOKIT_HOME}/env
#!/bin/bash
#主要な値は環境変数に入っています。 "${HOME}"/.bashrc

NODE_TYPE="${1}"
SYNC_NETWORK="${2}"
COLDKEYS_DIR="${HOME}/cold-keys"
COLD_SKEY_FILENAME="node.skey"
COLD_VKEY_FILENAME="node.vkey"
COUNTER_FILENAME="node.counter"
KES_SKEY_FILENAME="kes.skey"
KES_VKEY_FILENAME="kes.vkey"
VRF_SKEY_FILENAME="vrf.skey"
VRF_VKEY_FILENAME="vrf.vkey"
NODE_CERT_FILENAME="node.cert"
POOL_CERT_FILENAME="pool.cert"
PAYMENT_SKEY_FILENAME="payment.skey"
PAYMENT_VKEY_FILENAME="payment.vkey"
PAYMENT_ADDR_FILENAME="payment.addr"
STAKE_SKEY_FILENAME="stake.skey"
STAKE_VKEY_FILENAME="stake.vkey"
STAKE_ADDR_FILENAME="stake.addr"
STAKE_CERT_FILENAME="stake.cert"
POOL_META_FILENAME="poolMetaData.json"
POOL_ID_FILENAME="pool.id"
POOL_ID_BECH32_FILENAME="pool.id-bech32"
KOIOS_API="${3}"
NODE_PROMETHEUS_PORT="12798"
EOF
}

DotSpinner3(){
    gum spin --spinner dot --title "${1}" -- sleep 3
}


##############
#起動タイトル
##############
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}====================================${NC}"
echo -e "${RED}              Spokit!                 ${NC}"
echo -e "${RED}        Cardano SPO Tool Kit          ${NC}"
echo -e "${GREEN}====================================${NC}"
sleep 3

if [[ ! -d $SPOKIT_INST_DIR ]]; then
#環境設定
cat > ~/.tmux.conf << EOF
set -g default-terminal "screen-256color"
EOF

    #ライブラリインストール
    YellowStyle "ライブラリをインストール..."
    if [ ! -e "/usr/bin/gum" ]; then
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
        sudo apt update && sudo apt install gum=${gum_version}
    fi
    sudo apt install git jq bc ccze automake tmux rsync htop curl build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ wget libncursesw5 libtool autoconf liblmdb-dev chrony fail2ban -y
    sudo apt-mark hold gum
    gum --version
    echo

    #Spokitインストール
    spokit_version="$(curl -s https://api.github.com/repos/btbf/sjg-tools/releases/latest | jq -r '.tag_name')"
    YellowStyle "Spokitをインストール..."
    mkdir -p $HOME/git
    cd $HOME/git

    wget -q https://github.com/btbf/sjg-tools/archive/refs/tags/${spokit_version}.tar.gz -O spokit.tar.gz
    tar xzvf spokit.tar.gz
    rm spokit.tar.gz


    sudo mkdir -p ${SPOKIT_INST_DIR}
    cd sjg-tools-${spokit_version}/scripts
    sudo cp -pR ./* ${SPOKIT_INST_DIR}

    chmod 755 spokit_run.sh
    chmod 755 spokit.sh

    rm -rf $HOME/git/sjg-tools-${spokit_version}
else
    echo "Spokitはすでにインストールされています"
    echo "spokit または spokit setup で起動できます"
fi


##------初期設定
clear
if [ ! -d "${SPOKIT_HOME}" ]; then
    gum style --foreground 110  --border-foreground 111  --border rounded --align center --width 60 --margin "1 1 0 1" --padding "0 0" "Spokit v${spokit_version}" "ノードセットアップ初期設定"

    if [ -d "${NODE_HOME}" ]; then 
        echo -e "既存のネットワーク設定が見つかりました : ${NODE_CONFIG}\n"
        workDir=${NODE_HOME}
        syncNetwork=${NODE_CONFIG}
    else
        syncNetwork=$(gum choose --header.foreground="244" --header="接続ネットワークを選択してください" --no-show-help "mainnet" "preview" "preprod" "Sancho-net")
        workDir=$(gum input --value "${HOME}/cnode" --width=0 --no-show-help --header.foreground="244" --header="プール管理ディレクトリを作成します。デフォルトの場合はそのままEnterを押して下さい" --header.foreground="99" --placeholder "${HOME}/cnode")
    fi

    NODE_TYPE=$(gum choose --header.foreground="244" --header="セットアップノードタイプを選択して下さい" "ブロックプロデューサー" "リレー" "エアギャップ" --no-show-help)
    

    echo
    case "${syncNetwork}" in
        "mainnet" )
            NODE_CONFIG=mainnet
            NODE_NETWORK='"--mainnet"'
            CARDANO_NODE_NETWORK_ID=mainnet
            KOIOS_DOMAIN="https://api.koios.rest/api/v1"
        ;;
        "preview" )
            NODE_CONFIG=preview
            NODE_NETWORK='"--testnet-magic 2"'
            CARDANO_NODE_NETWORK_ID=2
            KOIOS_DOMAIN="https://preview.koios.rest/api/v1"
        ;;
        "preprod" )
            NODE_CONFIG=preprod
            NODE_NETWORK='"--testnet-magic 1"'
            CARDANO_NODE_NETWORK_ID=1
            KOIOS_DOMAIN="https://preprod.koios.rest/api/v1"
        ;;
        "Sancho-net" )
            NODE_CONFIG=sanchonet
            NODE_NETWORK='"--testnet-magic 4"'
            CARDANO_NODE_NETWORK_ID=4
            KOIOS_DOMAIN="https://sancho.koios.rest/api/v1"
        ;;
    esac

    style "ノードタイプ:" "${NODE_TYPE}"
    style "ネットワーク:" "${NODE_CONFIG}"
    style "プール管理ディレクトリ:" "${workDir}"
    echo
    gum confirm "この設定でよろしいですか？" --default=true --no-show-help --affirmative="はい" --negative="いいえ" && iniSettings="Yes" || iniSettings="No"

    if [ "${iniSettings}" == "Yes" ]; then
        if [ ! -d "$NODE_HOME" ]; then
            echo "環境変数を追加します"
            echo PATH="$HOME/.local/bin:$PATH" >> "${HOME}"/.bashrc
            echo export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" >> "${HOME}"/.bashrc
            echo export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" >> "${HOME}"/.bashrc
            echo export NODE_HOME="${HOME}"/cnode >> "${HOME}"/.bashrc
            echo export CARDANO_NODE_SOCKET_PATH="${HOME}/cnode/db/socket" >> "${HOME}"/.bashrc
            echo export SPOKIT_INST_DIR="${SPOKIT_INST_DIR}" >> "${HOME}"/.bashrc
            echo export SPOKIT_HOME="${SPOKIT_HOME}" >> "${HOME}"/.bashrc
            echo export NODE_CONFIG="${NODE_CONFIG}" >> "${HOME}"/.bashrc
            echo export NODE_NETWORK="${NODE_NETWORK}" >> "${HOME}"/.bashrc
            echo export CARDANO_NODE_NETWORK_ID="${CARDANO_NODE_NETWORK_ID}" >> "${HOME}"/.bashrc
            echo alias cnode='"sudo journalctl -u cardano-node -f | ccze -A"' >> "${HOME}"/.bashrc
            echo alias cnstart='"sudo systemctl start cardano-node"' >> "${HOME}"/.bashrc
            echo alias cnrestart='"sudo systemctl reload-or-restart cardano-node"' >> "${HOME}"/.bashrc
            echo alias cnstop='"sudo systemctl stop cardano-node"' >> "${HOME}"/.bashrc
            echo alias cnreload='"kill -HUP $(pidof cardano-node)"' >> "${HOME}"/.bashrc
            echo alias glive="'cd ${HOME}/cnode/scripts; ./gLiveView.sh'" >> "${HOME}"/.bashrc
            echo alias spokit="'${SPOKIT_INST_DIR}/spokit_run.sh'" >> $HOME/.bashrc
        else
            echo export SPOKIT_INST_DIR="${SPOKIT_INST_DIR}" >> "${HOME}"/.bashrc
            echo export SPOKIT_HOME="${SPOKIT_HOME}" >> "${HOME}"/.bashrc
            echo alias spokit="'${SPOKIT_INST_DIR}/spokit_run.sh'" >> $HOME/.bashrc
        fi
        
        #設定ファイル作成
        CreateEnv "${NODE_TYPE}" "${NODE_CONFIG}" "${UFW_STATUS}" "${KOIOS_DOMAIN}"

        echo
        style "設定ファイルを作成しました" "${SPOKIT_HOME}/env"
        echo

        DotSpinner3 "初期設定を終了します"
    else
        clear
        echo
        echo "最初からやり直す場合はツールを再実行してください"
        exit
    fi

fi

echo "------------------------------------------------------------"
echo "source $HOME/.bashrc"
echo "上記コマンドを実行して環境変数を再読み込みしてください"
echo
echo "プール構築開始コマンド \"spokit setup\" "
echo "プール運営コマンド \"spokit\" "
