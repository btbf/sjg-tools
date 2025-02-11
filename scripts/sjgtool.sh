#!/bin/bash
# shellcheck disable=SC1091,SC2086,SC1001,SC2317
# shellcheck source="$HOME/.bashrc"

source ${HOME}/.bashrc
source ${CNM_INST_DIR}/sjgtool.library
source ${CNM_INST_DIR}/components/node_install
source ${CNM_INST_DIR}/components/create_kes
source ${CNM_INST_DIR}/components/grafana_install
source ${CNM_INST_DIR}/components/create_metadata
source ${CNM_INST_DIR}/components/register_pool
source ${CNM_INST_DIR}/components/create_keys
source ${CNM_INST_DIR}/components/topology_management
source ${CNM_INST_DIR}/components/check_poolwallet
source ${CNM_INST_DIR}/components/air_gap
source ${CNM_INST_DIR}/components/manage_wallet
source ${CNM_INST_DIR}/components/manage_pool
source ${CNM_INST_DIR}/components/node_sync_check
source ${CNM_INST_DIR}/components/mithril_bootstrap
source ${envPath}

clear

#-------------------------------#
 #CNODE Managerプール構築メニュー
#-------------------------------#

PoolSetupMenu(){
  headerTitle="プール管理メニュー"

  case $NODE_TYPE in
    "ブロックプロデューサー" )
      while :
      do
      clear
      Header $headerTitle
      selection=$(gum filter --height=12 --no-show-help --header.foreground="075" --indicator=">" --placeholder="番号選択も可..." --prompt="◉ " "[1] ノードインストール" "[2] プールメタデータ作成" "[3] トポロジー設定" "[4] プール運用キー作成" "[5] プール運用証明書作成" "[6] ウォレット準備" "[7] ステークアドレス登録" "[8] プール登録" "[9] 監視ツールセットアップ" "[q] 終了")
      case $selection in
        "[1] ノードインストール" )
            FirstNodeSetup
        ;;

        "[2] プールメタデータ作成" )
            createMetadata
        ;;

        "[3] トポロジー設定" )
            topologyManagement
        ;;

        "[4] プール運用キー作成" )
            createKeys
        ;;

        "[5] プール運用証明書作成" )
          if [ ! -e "${NODE_HOME}"/"${KES_SKEY_FILENAME}" ] && [ ! -e "${NODE_HOME}"/"${KES_VKEY_FILENAME}" ] && [ ! -e "${NODE_HOME}"/"${NODE_CERT_FILENAME}" ]; then
            createKes
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

        "[6] ウォレット準備" )
        checkPoolwallet
        ;;

        "[7] ステークアドレス登録" )
        registerStakeadd
        ;;

        "[8] プール登録" )
        registarPool
        ;;

        "[9] 監視ツールセットアップ" )
          prometheusInstall
        ;;
        "[q] 終了" )
          tmux kill-session -t sjgtool
        ;;
      esac
      done
    ;;

    "リレー" )
      while :
      do
      clear
      Header $headerTitle
      selection=$(gum filter --height=12 --no-show-help --header.foreground="075" --indicator=">" --placeholder="番号選択も可..." --prompt="◉ " "[1] ノードインストール" "[2] トポロジー設定" "[3] 監視ツールセットアップ" "[q] 終了")
      case $selection in
        "[1] ノードインストール" )
            FirstNodeSetup
        ;;

        "[2] トポロジー設定" )
            topologyManagement
        ;;

        "[3] 監視ツールセットアップ" )
            grafanaInstall
        ;;

        "[q] 終了" )
          tmux kill-session -t sjgtool
        ;;
      esac
      done
    ;;
    "エアギャップ" )
      selection=$(gum filter --height=12 --no-show-help --header.foreground="075" --indicator=">" --placeholder="番号選択も可..." --prompt="◉ " "CLIインストール" "プール運用キー作成" "ノード運用証明書作成" "ステークアドレスTx署名" "プール登録証明書作成" "プール登録Tx署名" "[q] 終了")
      case $selection in

        "CLIインストール" )
          FirstNodeSetup
        ;;
      
        "プール運用キー作成" )
        createKeys
        ;;

        "ノード運用証明書作成" )
        createKes
        ;;

        "ステークアドレスTx署名" )
        signStakeAddressTx
        ;;

        "プール登録証明書作成" )
        CreatePoolCert
        ;;

        "プール登録Tx署名" )
        signPoolRegisterTx
        ;;

        "[q] 終了" )
          tmux kill-session -t sjgtool
        ;;
      esac
    ;;

  esac
}


#-------------------------------#
 #CNODE Managerプール管理メニュー
#-------------------------------#
CnmMain(){
  headerTitle="プール管理メニュー"
  case $NODE_TYPE in
    "ブロックプロデューサー" )
      while :
      do
      clear
      Header $headerTitle
      selection=$(gum filter --height=12 --no-show-help --header.foreground="075" --indicator=">" --placeholder="番号選択も可..." --prompt="◉ " "[1] ウォレット管理" "[2] プール情報管理" "[q] 終了")
      case $selection in
        "[1] ウォレット管理" )
        manageWallet
        ;;

        "[2] プール情報管理" )
        managePool
        ;;

        # "[3] ガバナンス管理" )
        # ;;

        "[q] 終了" )
          tmux kill-session -t sjgtool
        ;;
      esac
      done
    ;;
    
    "リレー" )
      while :
      do
      clear
      Header $headerTitle
      selection=$(gum filter --height=6 --no-show-help --header.foreground="075" --indicator=">" --placeholder="番号選択も可..." --prompt="◉ " "[1] ノードバージョンアップ" "[2] トポロジー変更" "[q] 終了")
      case $selection in
        "[1] ノードバージョンアップ" )
          NodeVirsionUp
        ;;

        "[2] トポロジー変更" )
            topologyManagement
        ;;

        "[q] 終了" )
          tmux kill-session -t sjgtool
        ;;
      esac
      done
    ;;

    "エアギャップ" )
     selection=$(gum filter --height=12 --no-show-help --header.foreground="075" --indicator=">" --placeholder="番号選択も可..." --prompt="◉ " "CLIバージョンアップ" "ノード運用証明書作成" "プール登録証明書作成" "プール登録Tx署名" "[q] 終了")
      case $selection in

        "CLIバージョンアップ" )
        ;;

        "ノード運用証明書作成" )
        createKes
        ;;

        "プール登録証明書作成" )
        CreatePoolCert
        ;;

        "プール登録Tx署名" )
        signPoolRegisterTx
        ;;

        "[q] 終了" )
          tmux kill-session -t sjgtool
        ;;
      esac
    ;;
  esac
}


clear
#env再読み込み
source ${envPath}

case $1 in
  "poolsetup" )
    PoolSetupMenu
  ;;

  "" )
    CnmMain
  ;;
esac