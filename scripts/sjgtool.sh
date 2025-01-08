#!/bin/bash
# shellcheck disable=SC1091,SC2086,SC1001,SC2317
# shellcheck source="$HOME/.bashrc"

source ${HOME}/.bashrc
source ${CNM_INST_DIR}/sjgtool.library
source ${CNM_INST_DIR}/components/node_install
source ${CNM_INST_DIR}/components/kes_create
source ${CNM_INST_DIR}/components/grafana_install
source ${CNM_INST_DIR}/components/create_metadata
source ${CNM_INST_DIR}/components/register_pool
source ${CNM_INST_DIR}/components/create_keys
source ${CNM_INST_DIR}/components/topology_management
source ${CNM_INST_DIR}/components/check_poolwallet
source ${envPath}

clear
nodeBinaryPath=$(which cardano-node)
cliBinaryPath=$(which cardano-cli)
checkPaymentFile=$(PathEnabledCheck "${NODE_HOME}/${PAYMENT_ADDR_FILENAME}" "Yes" "No")
Header

style "ノードタイプ:" "${NODE_TYPE}"
style "対象ネットワーク:" ${NODE_CONFIG}
echo
while :
do
selection0=$(gum choose --header="" --height=8 --no-show-help "プール構築" "プール運用" "ツール設定" "終了")

case $selection0 in
    "プール構築" )
      while :
      do
        clear

        #env再読み込み
        source ${envPath}

        # #完了チェック
        # installCheck=$(PathEnabledCheck "${nodeBinaryPath}" "✅" "❌")
        # if [[ $NODE_TYPE == "ブロックプロデューサー" ]]; then
        #   metaDataCheck=$(VariableEnabledCheck "${META_POOL_NAME}" "✅" "❌")
        #   if [ "${checkPaymentFile}" == "Yes" ]; then
        #     WalletBalance > /dev/null
        #     if [ "${total_balance}" -ge 600000000 ]; then
        #       walletCheck=" ✅"
        #     else
        #       walletCheck=" ❌"
        #     fi
        #   else
        #     walletCheck=" ❌"
        #   fi

        #   if [ -e "${NODE_HOME}"/"${KES_SKEY_FILENAME}" ] && [ -e "${NODE_HOME}"/"${KES_VKEY_FILENAME}" ] && [ -e "${NODE_HOME}"/"${NODE_CERT_FILENAME}" ] && [ -e "${NODE_HOME}"/"${VRF_SKEY_FILENAME}" ] && [ -e "${NODE_HOME}"/"${VRF_VKEY_FILENAME}" ]; then
        #     bpKeyCreateCheck=" ✅"
        #   else
        #     bpKeyCreateCheck=" ❌"
        #   fi
        # fi
        

        #ヘッダー
        Header

        case $NODE_TYPE in
          "ブロックプロデューサー" )
            # selection=$(gum choose --header="" --height=12 --no-show-help "1.ノードインストール ${installCheck}" "2.プールメタデータ作成 ${metaDataCheck}" "3.トポロジー設定" "4.プールキー作成${bpKeyCreateCheck}" "5.運用ウォレット準備${walletCheck}" "6.ステークアドレス登録" "7.プール登録" "8.監視ツールインストール" "メインメニュー")
            selection=$(gum choose --header="" --height=12 --no-show-help "1.ノードインストール" "2.プールメタデータ作成" "3.トポロジー設定" "4.プール運用キー作成" "5.プール運用証明書作成" "6.ウォレット準備" "7.ステークアドレス登録" "8.プール登録" "メインメニュー")
            case $selection in
              "1.ノードインストール" )
                  nodeInstMain
              ;;

              "2.プールメタデータ作成" )
                  createMetadata
              ;;

              "3.トポロジー設定" )
                  topologyManagement
              ;;

              "4.プール運用キー作成" )
                  createKeys
              ;;

              "5.プール運用証明書作成" )
                if [ ! -e "${NODE_HOME}"/"${KES_SKEY_FILENAME}" ] && [ ! -e "${NODE_HOME}"/"${KES_VKEY_FILENAME}" ] && [ ! -e "${NODE_HOME}"/"${NODE_CERT_FILENAME}" ]; then
                  kesCreate
                else
                  echo
                  echo "以下のBP用ファイルが存在します"
                  FilePathAndHash ${NODE_HOME}/${KES_SKEY_FILENAME}
                  FilePathAndHash ${NODE_HOME}/${KES_VKEY_FILENAME}
                  FilePathAndHash ${NODE_HOME}/${NODE_CERT_FILENAME}
                  echo
                  Gum_OneSelect "戻る"
                fi
              ;;

              "6.ウォレット準備" )
              checkPoolwallet
              ;;

              "7.ステークアドレス登録" )
              registerStakeadd
              ;;

              "8.プール登録" )
              registarPool
              ;;

              "メインメニュー" )
              break
              ;;
            esac
          ;;

          "リレー" )
            selection=$(gum choose --header="" --height=6 --no-show-help "ノードインストール" "監視ツールインストール" "メインメニュー")

            case $selection in
              "ノードインストール" )
              nodeInstMain
              ;;

              "監視ツールインストール" )
              GrafanaInstall
              ;;

              "メインメニュー" )
              break
              ;;
            esac
          ;;
          "エアギャップ" )
            selection=$(gum choose --header="" --height=10 --no-show-help "CLIインストール" "プール運用キー作成" "ノード運用証明書作成" "ステークアドレスTx署名" "プール登録証明書作成" "プール登録Tx署名" "メインメニュー")
            case $selection in

              "CLIインストール" )
              nodeInstMain
              ;;
            
              "プール運用キー作成" )
              createKeys
              ;;

              "ノード運用証明書作成" )
              kesCreate
              ;;

              "ステークアドレスTx署名" )
              signStakeAddressTx
              ;;

              "プール登録Tx署名" )
              signPoolRegisterTx
              ;;

              "メインメニュー" )
              break
              ;;
            esac
          ;;

        esac

      done
      ;;
    "プール運用" )
        clear
        echo "プール運用します"
      ;;
    "設定" )
        clear
        echo "ツール設定します"

      ;;
    "終了" )
        tmux kill-session -t sjgtool
      ;;
esac
done