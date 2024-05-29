#!/bin/bash

style(){
  echo -e '{{ Color "15" " '"$1"' " }}''{{ Color "11" " '"$2"' " }}' "\n" \
    | gum format -t template
}

CreateEnv(){
cat <<-EOF > ./env 
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
KOIOS_API="${3}"
EOF
}

DotSpinner3(){
    gum spin --spinner dot --title "${1}" -- sleep 3
}



currentDir=$(pwd)
envPath="${currentDir}"/env


##------初期設定
clear
if [ ! -e "${envPath}" ]; then
    if [ -z "${NODE_HOME}" ]; then
        gum style \
            --foreground 212 --border-foreground 212 --border double \
            --align center --width 50 --margin "1 2" --padding "2 4" \
            'SJGTOOL V2' 'v.0.2.0' '' 'ツール初期設定'

        nodeType=$(gum choose --header="当サーバーにセットアップするノードタイプを選択して下さい" "ブロックプロデューサー" "リレー" "エアギャップ")

        syncNetwork=$(gum choose --header="接続ネットワークを選択してください" "Mainnet" "Preview-testnet" "PreProd-testnet" "Sancho-net")

        workDir=$(gum input --value "${HOME}/cnode" --width=0 --header="作業ディレクトリを作成します。任意のパスを指定可能です。デフォルトの場合はそのままEnterを押して下さい" --header.foreground="99" --placeholder "Please specify the working directory")


        echo
        case "${syncNetwork}" in
            "Mainnet" )
                NODE_CONFIG=mainnet
                NODE_NETWORK='"--mainnet"'
                CARDANO_NODE_NETWORK_ID=mainnet
                koios_domain="https://api.koios.rest"
            ;;
            "Preview-testnet" )
                NODE_CONFIG=preview
                NODE_NETWORK='"--testnet-magic 2"'
                CARDANO_NODE_NETWORK_ID=2
                koios_domain="https://preview.koios.rest"
            ;;
            "PreProd-testnet" )
                NODE_CONFIG=preprod
                NODE_NETWORK='"--testnet-magic 1"'
                CARDANO_NODE_NETWORK_ID=1
                koios_domain="https://preprod.koios.rest"
            ;;
            "Sancho-net" )
                NODE_CONFIG=sanchonet
                NODE_NETWORK='"--testnet-magic 4"'
                CARDANO_NODE_NETWORK_ID=4
                koios_domain="https://sancho.koios.rest"
            ;;
        esac

        style "ノードタイプ:" "${nodeType}"
        style "ネットワーク:" "${syncNetwork}"
        style "作業ディレクトリ:" "${workDir}"
        echo
        gum confirm "この設定でよろしいですか？" --default=false --affirmative="はい" --negative="いいえ" && iniSettings="Yes" || iniSettings="最初からやり直す場合はツールを再実行してください"

        if [ "${iniSettings}" == "Yes" ]; then
            
            echo PATH="$HOME/.local/bin:$PATH" >> "${HOME}"/.bashrc
            echo export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" >> "${HOME}"/.bashrc
            echo export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" >> "${HOME}"/.bashrc
            echo export NODE_HOME="${HOME}"/cnode >> "${HOME}"/.bashrc
            echo export CARDANO_NODE_SOCKET_PATH="${HOME}/cnode/db/socket" >> "${HOME}"/.bashrc

            echo export NODE_CONFIG="${NODE_CONFIG}" >> "${HOME}"/.bashrc
            echo export NODE_NETWORK="${NODE_NETWORK}" >> "${HOME}"/.bashrc
            echo export CARDANO_NODE_NETWORK_ID="${CARDANO_NODE_NETWORK_ID}" >> "${HOME}"/.bashrc

            echo alias cnode='"journalctl -u cardano-node -f"' >> "${HOME}"/.bashrc
            echo alias cnstart='"sudo systemctl start cardano-node"' >> "${HOME}"/.bashrc
            echo alias cnrestart='"sudo systemctl reload-or-restart cardano-node"' >> "${HOME}"/.bashrc
            echo alias cnstop='"sudo systemctl stop cardano-node"' >> "${HOME}"/.bashrc
            echo alias cnreload='"kill -HUP $(pidof cardano-node)"' >> "${HOME}"/.bashrc
            echo alias glive="'cd ${HOME}/cnode/scripts; ./gLiveView.sh'" >> "${HOME}"/.bashrc
            
            #設定ファイル作成
            CreateEnv "${nodeType}" "${syncNetwork}" "${koios_domain}"

            echo
            style "設定ファイルを作成しました" "${currentDir}/env"
            echo

            DotSpinner3 "初期設定を終了します"
        else
            clear
            echo
            echo "${iniSettings}"
            exit
        fi
    else
        echo "既存のSJG設定を検知しました"
        echo
        echo "接続ネットワーク：${NODE_CONFIG}"
        echo "作業ディレクトリ：${nodeHome}"
        echo
        nodeType=$(gum choose --header="このサーバーのノードタイプを選択してください" "ブロックプロデューサー" "リレー" "エアギャップ")
        echo "ノードタイプ：${nodeType}" 
        echo
        gum confirm "ツール用設定ファイルを作成します。この値でよろしいですか？" --default=false --affirmative="はい" --negative="いいえ" && iniSettings="Yes" || iniSettings="最初からやり直す場合はツールを再実行してください"

        if [ "${iniSettings}" == "Yes" ]; then
            #設定ファイル作成
            CreateEnv "${nodeType}" "${syncNetwork}"
            echo
            style "設定ファイルを作成しました" "${currentDir}/env"
            echo

            DotSpinner3 "初期設定を終了します"
        else
            clear
            echo
            echo "${iniSettings}"
            echo
            exit
        fi
    fi
fi

# #------初期設定

tmux new-session -d -s sjgtool

tmux send-keys -t sjgtool $HOME/sjg-tools/scripts/sjgtool.sh Enter

tmux a -t sjgtool
