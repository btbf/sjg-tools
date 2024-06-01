#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2086,SC1001,SC2317
# shellcheck source="$HOME/.bashrc"
# shellcheck source="${envPath}"

currentDir=$(pwd)
source ${HOME}/.bashrc
source ${currentDir}/sjgtool.library



envPath=${currentDir}/env

source ${envPath}



#gumモジュール関数

Header(){
  gum style \
	--foreground 212 --border-foreground 212 --border double \
	--align center --width 50 --margin "1 2" --padding "2 4" \
	'SJGTOOL V2' ${version}
}

SystemUpdate(){
  YellowStyle "システムアップデート..."
  echo
  gum input --password --no-show-help | sudo -S apt update -y && sudo apt upgrade -y
  YellowStyle "アップデートしました"
  sleep 3
}


#ユーザー関数 変数チェック
VariableEnabledCheck(){
  if [ -n "${1}" ]; then
    echo ${2}
  else
    echo ${3}
  fi
}

#ユーザー関数
PathEnabledCheck(){
  if [ -e "${1}" ]; then
    echo ${2}
  else
    echo ${3}
  fi
}


CreatePoolMetaJson(){
cat <<-EOF > ${NODE_HOME}/${POOL_META_FILENAME}
{
  "name": "$1",
  "description": "$2",
  "ticker": "$3",
  "homepage": "$4"
}
EOF
}


#ノードインストール
NodeInstall(){

  #依存関係インストール
  sudo apt install git jq bc automake tmux rsync htop curl build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ wget libncursesw5 libtool autoconf liblmdb-dev -y

  echo
  YellowStyle "依存関係をインストールしました..."
  echo

  #Libsodium Install
  echo
  YellowStyle "Libsodiumインストール..."
  echo
  sleep 3
  mkdir ${HOME}/git
  cd ${HOME}/git || exit
  git clone https://github.com/IntersectMBO/libsodium
  cd libsodium || exit
  git checkout dbb48cc
  ./autogen.sh
  ./configure
  make
  sudo make install

  #Secp256k1 Install
  echo
  YellowStyle "Secp256k1インストール..."
  echo
  sleep 3
  cd ${HOME}/git || exit
  git clone https://github.com/bitcoin-core/secp256k1.git
  cd secp256k1/ || exit
  git checkout ac83be33
  ./autogen.sh
  ./configure --prefix=/usr --enable-module-schnorrsig --enable-experimental
  make
  sudo make install

  #blst Install
  echo
  YellowStyle "blstインストール..."
  echo
  sleep 3
  cd ${HOME}/git || exit
  git clone https://github.com/supranational/blst
  cd blst || exit
  git checkout v0.3.10
  ./build.sh

  cat <<-EOF >libblst.pc
		prefix=/usr/local
		exec_prefix=\${prefix}
		libdir=\${exec_prefix}/lib
		includedir=\${prefix}/include

		Name: libblst
		Description: Multilingual BLS12-381 signature library
		URL: https://github.com/supranational/blst
		Version: 0.3.10
		Cflags: -I\${includedir}
		Libs: -L\${libdir} -lblst
		EOF

  sudo cp libblst.pc /usr/local/lib/pkgconfig/
  sudo cp bindings/blst_aux.h bindings/blst.h bindings/blst.hpp  /usr/local/include/
  sudo cp libblst.a /usr/local/lib
  sudo chmod u=rw,go=r /usr/local/{lib/{libblst.a,pkgconfig/libblst.pc},include/{blst.{h,hpp},blst_aux.h}}

  GHCUP Install
  echo
  YellowStyle "GHCUPインストール..."
  echo
  sleep 3
  cd ${HOME} || exit
  BOOTSTRAP_HASKELL_NONINTERACTIVE=1
  BOOTSTRAP_HASKELL_NO_UPGRADE=1
  BOOTSTRAP_HASKELL_ADJUST_BASHRC=1
  unset BOOTSTRAP_HASKELL_INSTALL_HLS
  export BOOTSTRAP_HASKELL_NONINTERACTIVE BOOTSTRAP_HASKELL_NO_UPGRADE BOOTSTRAP_HASKELL_ADJUST_BASHRC

  curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | bash

  source ${HOME}/.ghcup/env
  ghcup upgrade
  ghcup install cabal 3.8.1.0
  ghcup set cabal 3.8.1.0

  ghcup install ghc 8.10.7
  ghcup set ghc 8.10.7

  cabal update
  cabal --version
  ghc --version

  echo
  YellowStyle "ノードインストール"
  echo
  sleep 3
  mkdir ${HOME}/git/cardano-node
  cd ${HOME}/git/cardano-node || exit
  wget https://github.com/IntersectMBO/cardano-node/releases/download/8.9.3/cardano-node-8.9.3-linux.tar.gz
  tar zxvf cardano-node-8.9.3-linux.tar.gz ./cardano-node ./cardano-cli
  $(find ${HOME}/git/cardano-node -type f -name "cardano-cli") version
  $(find ${HOME}/git/cardano-node -type f -name "cardano-node") version

  sudo cp "$(find ${HOME}/git/cardano-node -type f -name "cardano-cli")" /usr/local/bin/cardano-cli
  sudo cp "$(find ${HOME}/git/cardano-node -type f -name "cardano-node")" /usr/local/bin/cardano-node

  cardano-cli version
  cardano-node version

  if [ "${NODE_TYPE}" != "エアギャップ" ]; then
    echo
    YellowStyle "設定ファイルダウンロード..."
    echo
    sleep 3
    mkdir ${NODE_CONFIG}
    cd ${NODE_CONFIG} || exit
    wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/byron-genesis.json -O ${NODE_CONFIG}-byron-genesis.json
    wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/topology.json -O ${NODE_CONFIG}-topology.json
    wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/shelley-genesis.json -O ${NODE_CONFIG}-shelley-genesis.json
    wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/alonzo-genesis.json -O ${NODE_CONFIG}-alonzo-genesis.json
    wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/conway-genesis.json -O ${NODE_CONFIG}-conway-genesis.json
    wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/config.json -O ${NODE_CONFIG}-config.json
    echo
    YellowStyle "設定ファイルダウンロードしました"
    echo

    sed -i ${NODE_CONFIG}-config.json \
        -e 's!"AlonzoGenesisFile": "alonzo-genesis.json"!"AlonzoGenesisFile": "'${NODE_CONFIG}'-alonzo-genesis.json"!' \
        -e 's!"ByronGenesisFile": "byron-genesis.json"!"ByronGenesisFile": "'${NODE_CONFIG}'-byron-genesis.json"!' \
        -e 's!"ShelleyGenesisFile": "shelley-genesis.json"!"ShelleyGenesisFile": "'${NODE_CONFIG}'-shelley-genesis.json"!' \
        -e 's!"ConwayGenesisFile": "conway-genesis.json"!"ConwayGenesisFile": "'${NODE_CONFIG}'-conway-genesis.json"!' \
        -e "s/TraceMempool\": false/TraceMempool\": true/g" \
        -e 's!"TraceBlockFetchDecisions": false!"TraceBlockFetchDecisions": true!' \
        -e 's!"rpKeepFilesNum": 10!"rpKeepFilesNum": 30!' \
        -e 's!"rpMaxAgeHours": 24!"rpMaxAgeHours": 48!' \
        -e '/"defaultScribes": \[/a\    \[\n      "FileSK",\n      "'${NODE_CONFIG}'/logs/node.json"\n    \],' \
        -e '/"setupScribes": \[/a\    \{\n      "scFormat": "ScJson",\n      "scKind": "FileSK",\n      "scName": "'${NODE_CONFIG}'/logs/node.json"\n    \},' \
        -e "s/127.0.0.1/0.0.0.0/g"

    echo
    YellowStyle "設定ファイルを書き換えました"
    echo

    echo
    YellowStyle "起動スクリプトを作成します"
    echo
    sleep 3
    PORT=6000
cat <<-EOF > ${NODE_CONFIG}/startBlockProducingNode.sh
#!/bin/bash
DIRECTORY=${NODE_HOME}
PORT=${PORT}
HOSTADDR=0.0.0.0
TOPOLOGY=\${DIRECTORY}/${NODE_CONFIG}-topology.json
DB_PATH=\${DIRECTORY}/db
SOCKET_PATH=\${DIRECTORY}/db/socket
CONFIG=\${DIRECTORY}/${NODE_CONFIG}-config.json
/usr/local/bin/cardano-node +RTS -N --disable-delayed-os-memory-return -I0.1 -Iw300 -A16m -F1.5 -H2500M -RTS run --topology \${TOPOLOGY} --database-path \${DB_PATH} --socket-path \${SOCKET_PATH} --host-addr \${HOSTADDR} --port \${PORT} --config \${CONFIG}
EOF

    cd ${NODE_CONFIG} || exit
    chmod +x startBlockProducingNode.sh

    echo
    YellowStyle "起動スクリプトを作成しました"
    echo

    echo
    YellowStyle "gliveViewをインストールします..."
    echo
    sleep 3
    mkdir ${NODE_CONFIG}/scripts
    cd ${NODE_CONFIG}/scripts || exit
    sudo sudo apt install bc tcptraceroute -y

    curl -s -o gLiveView.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/gLiveView.sh
    curl -s -o env https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/env
    chmod 755 gLiveView.sh

    sed -i ${NODE_CONFIG}/scripts/env \
    -e '1,73s!#CNODE_HOME="/opt/cardano/cnode"!CNODE_HOME=${NODE_HOME}!' \
    -e '1,73s!#CNODE_PORT=6000!CNODE_PORT='"${PORT}"'!' \
    -e '1,73s!#UPDATE_CHECK="Y"!UPDATE_CHECK="N"!' \
    -e '1,73s!#CONFIG="${CNODE_HOME}/files/config.json"!CONFIG="${CNODE_HOME}/'${NODE_CONFIG}'-config.json"!' \
    -e '1,73s!#SOCKET="${CNODE_HOME}/sockets/node0.socket"!SOCKET="${CNODE_HOME}/db/socket"!'

    echo
    YellowStyle "gliveViewをインストールしました..."
    echo


    echo
    YellowStyle "Mithrilクライアントをインストールします..."
    echo
    sleep 3
    #Rustインストール
    mkdir -p ${HOME}/.cargo/bin
    chown -R "${USER}" ${HOME}/.cargo
    touch ${HOME}/.profile
    chown "${USER}" ${HOME}/.profile

    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source ${HOME}/.cargo/env
    rustup install stable
    rustup default stable
    rustup update

    sudo apt install -y libssl-dev build-essential m4 jq
    cd ${HOME}/git || exit
    git clone https://github.com/input-output-hk/mithril.git
    cd mithril || exit
    git fetch --all --prune
    git checkout tags/2403.1
    cd mithril-client-cli || exit
    make build
    sudo mv mithril-client /usr/local/bin/mithril-client

    echo
    YellowStyle "Mithrilクライアントをインストールしました..."
    echo

    NETWORK=${NODE_CONFIG}
    AGGREGATOR_ENDPOINT="https://aggregator.release-mainnet.api.mithril.network/aggregator"
    GENESIS_VERIFICATION_KEY="$(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/genesis.vkey)"
    SNAPSHOT_DIGEST="latest"

    export NETWORK
    export AGGREGATOR_ENDPOINT
    export GENESIS_VERIFICATION_KEY
    export SNAPSHOT_DIGEST

    echo
    YellowStyle "DBスナップショットをダウンロードします..."
    echo
    sleep 3
    mithril-client snapshot download --download-dir ${NETWORK} latest

    echo
    YellowStyle "DBスナップショットをダウンロードしました..."
    echo

    echo
    YellowStyle "サービスファイルを作成します"
    echo
    sleep 3
cat > ${NODE_CONFIG}/cardano-node.service <<-EOF
# The Cardano node service (part of systemd)
# file: /etc/systemd/system/cardano-node.service

[Unit]
Description     = Cardano node service
Wants           = network-online.target
After           = network-online.target

[Service]
User            = ${USER}
Type            = simple
WorkingDirectory= ${NODE_HOME}
ExecStart       = /bin/bash -c '${NODE_HOME}/startBlockProducingNode.sh'
KillSignal=SIGINT
RestartKillSignal=SIGINT
TimeoutStopSec=300
LimitNOFILE=32768
Restart=always
RestartSec=5
SyslogIdentifier=cardano-node

[Install]
WantedBy    = multi-user.target
EOF

    gum input --password --no-show-help | sudo -S cp ${NODE_CONFIG}/cardano-node.service /etc/systemd/system/cardano-node.service
    sudo chmod 644 /etc/systemd/system/cardano-node.service
    sudo systemctl daemon-reload
    sudo systemctl enable cardano-node
    sudo systemctl start cardano-node

    echo
    YellowStyle "サービスファイルを作成しました"
    echo
  fi
}


#KES作成
KesCreate(){
    case ${1} in
    "ブロックプロデューサー" )
      #KEStimenig
      slotNumInt=$(curl -s http://localhost:12798/metrics | grep cardano_node_metrics_slotNum_int | awk '{ print $2 }')
      kesTiming=$(echo "scale=6; ${slotNumInt} / 129600" | bc | awk '{printf "%.5f\n", $0}')

      echo '------------------------------------------------------------------------'
      echo "KES作成(更新)作業にはブロックプロデューサーとエアギャップを使用します"
      echo
      echo -e "■ 実行フロー"
      echo ' 1.KESファイル/CERTファイル作成(バックアップ)'
      echo ' 2.新規KESファイル作成'
      echo " 3.KESファイルをエアギャップへコピー"
      echo ' 4.エアギャップ操作/CERTファイルBPコピー(手動)'
      echo ' 5.ノード再起動'
      echo '------------------------------------------------------------------------'
      echo
      echo "KESファイルを更新する前に、1時間以内にブロック生成スケジュールが無いことを確認してください"
      echo
      Gum_Confirm_YesNo "KES更新作業を開始しますか？" "Yes" "最初からやり直す場合はツールを再実行してください"
      
      if [ "$iniSettings" != "Yes" ]; then return 1; fi

      echo 
      echo  "KES更新タイミングチェック:$(MagentaStyle ${kesTiming})"
      sleep 1

      kesTimingDecimal=${kesTiming#*.}
      if [ ${kesTimingDecimal} -ge 99800 ]; then
        echo "KesStartがもうすぐ切り替わります(${kesTiming})"
        nextkes=$(echo ${kesTiming} | awk '{echo("%d\n",$1+1)}')
        echo "startKesPeriodが$nextkesへ切り替わってから再度実行してください"
        select_rtn
      else
        GreenStyle "OK"
      fi
      Gum_DotSpinner3 "準備中"
      echo
      #最新ブロックカウンター番号チェック
      if [ -e ${NODE_HOME}/${NODE_CERT_FILENAME} ]; then
        cardano-cli query kes-period-info $NODE_NETWORK --op-cert-file ${NODE_HOME}/${NODE_CERT_FILENAME} --out-file ${NODE_HOME}/kesperiod.json
        lastBlockCnt=$(cat ${NODE_HOME}/kesperiod.json | jq -r '.qKesNodeStateOperationalCertificateNumber')
        rm ${NODE_HOME}/kesperiod.json
      fi
    
      #現在のKESPeriod算出
      slotNo=$(cardano-cli query tip $NODE_NETWORK | jq -r '.slot')
      slotsPerKESPeriod=$(cat ${NODE_HOME}/${NODE_CONFIG}-shelley-genesis.json | jq -r '.slotsPerKESPeriod')
      kesPeriod=$(( ${slotNo} / ${slotsPerKESPeriod} ))
      startKesPeriod=${kesPeriod}
      
      kesfolder="${NODE_HOME}/kes-backup"
      if [ ! -e "${kesfolder}" ]; then
        mkdir $kesfolder
        echo "$kesfolderディレクトリを作成しました"
      fi

      date=$(date +\%Y\%m\%d\%H\%M)
      if [ -e "${NODE_HOME}/${KES_SKEY_FILENAME}" ]; then
        MagentaStyle "■旧KESファイルのバックアップ..."
        cp ${NODE_HOME}/${KES_VKEY_FILENAME} $kesfolder/$date-${KES_VKEY_FILENAME}
        YellowStyle "${NODE_HOME}/${KES_VKEY_FILENAME} を $kesfolder/$date-${KES_VKEY_FILENAME}へコピーしました"
        cp ${NODE_HOME}/${KES_SKEY_FILENAME} $kesfolder/$date-${KES_SKEY_FILENAME}
        YellowStyle "${NODE_HOME}/${KES_SKEY_FILENAME} を $kesfolder/$date-${KES_SKEY_FILENAME}へコピーしました"
        cp ${NODE_HOME}/${NODE_CERT_FILENAME} $kesfolder/$date-${NODE_CERT_FILENAME}
        YellowStyle "${NODE_HOME}/${NODE_CERT_FILENAME} を $kesfolder/$date-${NODE_CERT_FILENAME}へコピーしました"

        # チェックするディレクトリを指定
        # 特定のファイル名に含まれる文字列を指定（3種類）
        oldKessKey="*${KES_SKEY_FILENAME}"
        oldKesvKey="*${KES_VKEY_FILENAME}"
        oldNodecertKey="*${NODE_CERT_FILENAME}"

        # 関数: 古いファイルを削除する
        KesCleanupFiles() {
          local pattern=${1}
          local dir=${2}
          
          # 該当するファイルをリストアップ
          file_list=$(ls -1t ${dir} | grep ${pattern})
          
          # 該当するファイル数を取得
          file_count=$(echo "${file_list}" | wc -l)
          
          # ファイルが5つ以上ある場合
          if [ "$file_count" -ge 5 ]; then
            # 古いファイルをリストアップし、5番目のファイル以降を削除
            echo "$file_list" | tail -n +6 | while read -r file; do
              rm "$dir/$file"
            done
          fi
        }

        # 各パターンについて関数を呼び出す
        KesCleanupFiles "$oldKessKey" "$kesfolder"
        KesCleanupFiles "$oldKesvKey" "$kesfolder"
        KesCleanupFiles "$oldNodecertKey" "$kesfolder"

        MagentaStyle "${MAGENTA}■旧KESファイルの削除...${NC}"
        sleep 2
        rm ${NODE_HOME}/${KES_VKEY_FILENAME}
        YellowStyle "${NODE_HOME}/${KES_VKEY_FILENAME} を削除しました"
        rm ${NODE_HOME}/${KES_SKEY_FILENAME}
        YellowStyle "${NODE_HOME}/${KES_SKEY_FILENAME} を削除しました"
      fi

      MagentaStyle "■新しいKESファイルの作成..."
      cardano-cli node key-gen-KES --verification-key-file ${NODE_HOME}/${KES_VKEY_FILENAME} --signing-key-file ${NODE_HOME}/${KES_SKEY_FILENAME}
      sleep 5
      
      kesVkey256=$(sha256sum ${NODE_HOME}/${KES_VKEY_FILENAME} | awk '{ print $1 }')
      kesSkey256=$(sha256sum ${NODE_HOME}/${KES_SKEY_FILENAME} | awk '{ print $1 }')


      FilePathAndHash "${NODE_HOME}/${KES_VKEY_FILENAME}"
      FilePathAndHash "${NODE_HOME}/${KES_SKEY_FILENAME}"
      echo "KESキーペアを作成しました"
      sleep 5
      #clear
      read -p "Enter"
      
      sleep 2
      echo
      echo
      echo '■エアギャップオフラインマシンで以下の操作を実施してください'
      echo '(項目1～6まであります)'
      echo
      sleep 2
      echo
      echo -e "${YELLOW}1. BPの${KES_VKEY_FILENAME}と${KES_SKEY_FILENAME} をエアギャップのcnodeディレクトリにコピーしてください${NC}"
      echo '----------------------------------------'
      echo ">> [BP] ⇒ ${KES_VKEY_FILENAME} / ${KES_SKEY_FILENAME} ⇒ [エアギャップ]"
      echo '----------------------------------------'
      sleep 1
      echo
      echo '上記コマンドの戻り値が以下のハッシュ値と等しいか確認する'
      echo
      FilePathAndHash "${NODE_HOME}/${KES_VKEY_FILENAME}"
      FilePathAndHash "${NODE_HOME}/${KES_SKEY_FILENAME}"
      echo
      read -p "上記を終えたらEnterを押して次の操作を表示します"

      clear
      echo
      #lastBlockCnt=" "
      echo "■カウンター番号情報"
      if expr "$lastBlockCnt" : "[0-9]*$" >&/dev/null; then
        counterValue=$(( $lastBlockCnt +1 ))
        echo "チェーン上カウンター番号: ${lastBlockCnt}"
        echo "今回更新のカウンター番号: ${counterValue}"
        echo "node.cert生成時に指定するカウンター番号は\n必ずチェーン上カウンター番号 +1 を指定する必要があります\n\n\n"
      else
        counterValue=0
        echo
        echo "ブロック未生成です"
        echo -e "今回更新のカウンター番号は $counterValue で更新します"
      fi
      echo '■エアギャップオフラインマシンで以下の操作を実施してください'
      echo
      read -p "上記を終えたらEnterを押して次の操作を表示します"

      clear
      echo
      echo '■エアギャップオフラインマシンに以下の数字を入力してください'
      echo
      echo "現在のstartKesPeriod: ${startKesPeriod}"
      sleep 2
      echo
      echo
      echo -e "${YELLOW}6. エアギャップの ${NODE_CERT_FILENAME} をBPのcnodeディレクトリにコピーしてください${NC}"
      echo '----------------------------------------'
      echo ">> [エアギャップ] ⇒ ${NODE_CERT_FILENAME} ⇒ [BP]"
      echo '----------------------------------------'
      echo
      sleep 1

      read -p "操作が終わったらEnterを押してください"

      echo
      echo "新しいKESファイルを有効化するにはノードを再起動する必要があります"
      echo "ノードを再起動しますか？"
      echo
      echo "[1] このまま再起動する　[2] 手動で再起動する"
      echo
      while :
        do
          read -n 1 restartnum
          if [ "$restartnum" == "1" ] || [ "$restartnum" == "2" ]; then
            case ${restartnum} in
              1) 
                sudo systemctl reload-or-restart cardano-node
                echo "\n${GREEN}ノードを再起動しました。${NC}\nglive viewを起動して同期状況を確認してください\n\n"
                echo "${RED}ノード同期完了後、当ツールの[2] ブロック生成状態チェックを実行してください${NC}\n\n"
                break
                ;;
              2) 
                clear
                echo "SPO JAPAN GUILD TOOL Closed!" 
                exit ;;
            esac
            break
          elif [ "$kesnum" == '' ]; then
            echo "入力記号が不正です。再度入力してください\n"
          else
            echo "入力記号が不正です。再度入力してください\n"
          fi
      done
    ;;

    "エアギャップ" )
      echo "ノード運用証明書(${NODE_CERT_FILENAME})を作成します。"
      echo
      echo "ブロックプロデューサーで作成した${KES_SKEY_FILENAME}と${KES_VKEY_FILENAME}を作業ディレクトリ${NODE_HOME}にコピーしてください"
      read -p "コピーしたらEnterを押してください"

      while :
      do
        echo
        echo -e "${YELLOW}2. ファイルハッシュ値確認${NC}"
        echo
        echo -e "${YELLOW}ブロックプロデューサーに表示されているハッシュ値と同じであることを確認してください${NC}"
        echo '----------------------------------------'
        FilePathAndHash "${NODE_HOME}/${KES_VKEY_FILENAME}"
        FilePathAndHash "${NODE_HOME}/${KES_SKEY_FILENAME}"
        echo '----------------------------------------'
        echo
        Gum_Confirm_YesNo "ハッシュ値は同じですか？" "Yes" "新しいKESファイルを${NODE_HOME}にコピーしてください"
        if [ ${iniSettings} == "Yes" ]; then
         break
        else
          echo
          echo "${iniSettings}"
          read -p "コピーしたらEnterを押してください"
        fi
      done
      read -p "操作が終わったらEnterを押してください"

      echo -e "${YELLOW}3. カウンターファイル生成${NC} "
      echo
      inputCounterNum=$(gum input --char-limit=3 --width=100 --header="ブロックプロデューサー側に表示されているカウンター番号を入力してください" --header.foreground="99" --no-show-help --placeholder "Counter Number")


      chmod u+rwx $COLDKEYS_DIR
      cardano-cli node new-counter --cold-verification-key-file $COLDKEYS_DIR/$COLD_VKEY_FILENAME --counter-value $inputCounterNum --operational-certificate-issue-counter-file $COLDKEYS_DIR/$COUNTER_FILENAME

      sleep 1
      echo
      echo -e "${YELLOW}4. カウンター番号確認${NC}"
      echo '----------------------------------------'
      echo
      echo "入力カウンター番号:$inputCounterNum"
      echo "カウンターファイル番号:$(cardano-cli text-view decode-cbor --in-file  $COLDKEYS_DIR/$COUNTER_FILENAME | grep int | head -1 | cut -d"(" -f2 | cut -d")" -f1)"
      echo 
      echo -e "${RED}上記コマンド実行の戻り値が ${YELLOW}$inputCounterNum ${RED}であることを確認してください${NC}"
      echo
      Gum_Confirm_YesNo "カウンター番号は同じですか？" "Yes" "新しいKESファイルを${NODE_HOME}にコピーしてください"

      echo -e "${YELLOW}5. ${NODE_CERT_FILENAME}ファイルを作成する${NC}"
      echo
      inputStartKesPeriod=$(gum input --char-limit=3 --width=100 --header="ブロックプロデューサー側に表示されているstartKesPerod番号を入力してください" --header.foreground="99" --no-show-help --placeholder "startKesPeriod")

      cardano-cli node issue-op-cert --kes-verification-key-file ${NODE_HOME}/${KES_VKEY_FILENAME} --cold-signing-key-file $COLDKEYS_DIR/$COLD_SKEY_FILENAME --operational-certificate-issue-counter $COLDKEYS_DIR/$COUNTER_FILENAME --kes-period ${inputStartKesPeriod} --out-file ${NODE_HOME}/${NODE_CERT_FILENAME}
      if [ $? -eq 0 ]; then
        echo $NODE_HOME/$NODE_CERT_FILENAME ファイルを生成しました。
        chmod a-rwx $COLDKEYS_DIR
      else
        echo "${NODE_CERT_FILENAME}ファイル生成に失敗しました"
      fi

      echo
      echo -e "${YELLOW}6. エアギャップの ${NODE_CERT_FILENAME} をBPのcnodeディレクトリにコピーしてください${NC}"
      echo '----------------------------------------'
      echo ">> [エアギャップ] ⇒ ${NODE_CERT_FILENAME} ⇒ [BP]"
      echo '----------------------------------------'
      echo '----------------------------------------'
      FilePathAndHash "${NODE_HOME}/${NODE_CERT_FILENAME}"
      echo '----------------------------------------'
      echo "BP側で${NODE_CERT_FILENAME}のハッシュ値を確認してください"
      echo
      read -p "コピーしたらEnterを押してください"
    ;;
  esac
}

clear
nodeBynarlyPath=$(which cardano-node)
cliBynalyPath=$(which cardano-cli)
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
        . "${envPath}"

        #完了チェック
        installCheck=$(PathEnabledCheck "${nodeBynarlyPath}" "✅" "❌")
        if [[ $NODE_TYPE == "ブロックプロデューサー" ]]; then
          metaDataCheck=$(VariableEnabledCheck "${META_POOL_NAME}" "✅" "❌")
          if [ "${checkPaymentFile}" == "Yes" ]; then
            WalletBalance > /dev/null
            if [ "${total_balance}" -ge 600000000 ]; then
              walletCheck=" ✅"
            else
              walletCheck=" ❌"
            fi
          else
            walletCheck=" ❌"
          fi

          if [ -e "${NODE_HOME}"/"${KES_SKEY_FILENAME}" ] && [ -e "${NODE_HOME}"/"${KES_VKEY_FILENAME}" ] && [ -e "${NODE_HOME}"/"${NODE_CERT_FILENAME}" ] && [ -e "${NODE_HOME}"/"${VRF_SKEY_FILENAME}" ] && [ -e "${NODE_HOME}"/"${VRF_VKEY_FILENAME}" ]; then
            bpKeyCreateCheck=" ✅"
          else
            bpKeyCreateCheck=" ❌"
          fi
        fi
        

        #ヘッダー
        Header

        if [ "${NODE_TYPE}" == "ブロックプロデューサー" ]; then
          selection1=$(gum choose --header="" --height=12 --no-show-help "ノードインストール ${installCheck}" "プールメタデータ作成 ${metaDataCheck}" "トポロジー構成" "プールウォレット確認${walletCheck}" "BP用キー作成${bpKeyCreateCheck}" "ステークアドレス登録" "プール登録" "メインメニュー")
        elif [ "${NODE_TYPE}" == "リレー" ]; then
          selection1=$(gum choose --header="" --height=4 --no-show-help "ノードインストール" "メインメニュー")
        elif [ "${NODE_TYPE}" == "エアギャップ" ]; then
          walletKeyCheck=$(PathEnabledCheck "${NODE_HOME}/${PAYMENT_SKEY_FILENAME}" "✅" "❌")
          selection1=$(gum choose --header="" --height=10 --no-show-help "CLIインストール" "プールウォレット作成 ${walletKeyCheck}" "BP用キー作成" "ステークアドレスTx署名" "プール登録証明書作成" "プール登録Tx署名" "メインメニュー")
        else
          echo "ノードタイプ設定値が無効です"
          sleep 3
          break
        fi
        case $selection1 in
          "ノードインストール ${installCheck}" )
            if [ -z "${nodeBynarlyPath}" ]; then
              echo "ノードをインストールします..."
              echo
              sleep 2
              SystemUpdate
              NodeInstall
              echo "gliveコマンドを実行してgLiveViewを起動してください..."
              sleep 2
            else 
              cardano-node --version
              cardano-cli --version
              echo
              YellowStyle "cardano-nodeはインストール済みです"
              echo
              Gum_OneSelect "戻る"
            fi
          ;;
          "プールメタデータ作成 ${metaDataCheck}" )
            if [ -z "${META_POOL_NAME}" ]; then
              metaPoolName=$(gum input --width=0 --header="プール名を入力してください(日本語可)" --char-limit=100 --header.foreground="99" --no-show-help --placeholder "Pool Name")
              metaTicker=$(gum input --width=0 --header="プールティッカーを3～5文字で入力してください。(A-Zと0-9の組み合わせのみ)" --char-limit=5 --header.foreground="99" --no-show-help --placeholder "Ticker")
              metaDirscription=$(gum input --width=0 --header="プール説明を入力してください（255文字以内(255byte)※ただし日本語は2byte扱い)" --char-limit=255 --header.foreground="99" --no-show-help --placeholder "Discription")
              metaHomepageUrl=$(gum input --width=0 --header="プールホームページURLを入力してください（64byte以内)" --char-limit=64 --header.foreground="99" --no-show-help --placeholder "Pool Homepage URL")

              style "プール名:" "${metaPoolName}"
              style "ティッカー:" "${metaTicker}"
              style "プール説明:" "${metaDirscription}"
              style "プールURL:" "${metaHomepageUrl}"
              echo
              Gum_Confirm_YesNo "この値でよろしいですか？" "Yes" "最初からやり直す場合はツールを再実行してください"

              if [ "${iniSettings}" == "Yes" ]; then
                echo META_POOL_NAME=\""${metaPoolName}"\" >> "${envPath}"
                echo META_TICKER=\""${metaTicker}"\" >> "${envPath}"
                echo META_DISCRIPTION=\""${metaDirscription}"\" >> "${envPath}"
                echo META_HOMEPAGE_URL=\""${metaHomepageUrl}"\" >> "${envPath}"

                echo "設定ファイルに追記しました"
                Gum_DotSpinner3 "${POOL_META_FILENAME}を作成しています"
                echo
                echo "以下のパスで${POOL_META_FILENAME}を作成しました"
                CreatePoolMetaJson "${metaPoolName}" "${metaDirscription}" "${metaTicker}" "${metaHomepageUrl}"
                echo
                echo "${POOL_META_FILENAME}をGithubまたはホームページサーバーにアップロードしてください"
                echo
                gum choose --header="アップロードが完了したらEnter" --height=1 --no-show-help "OK"
                echo

                while :
                do
                  poolMetaurl=$(gum input --width=0 --header="${POOL_META_FILENAME}をアップロードしたフルURLを入力してください" --char-limit=64 --header.foreground="99" --no-show-help --placeholder "${POOL_META_FILENAME} URL")
                  httpResponsCode=$(curl -LI "${poolMetaurl}" -o /dev/null -w '%{http_code}\n' -s)
                  
                  if [ "${httpResponsCode}" == "200" ]; then
                    curl -s "${poolMetaurl}" | jq . > /dev/null 2>&1
                    # jqの終了ステータスを確認
                    if [ $? -ne 0 ]; then
                        echo "エラー: ${POOL_META_FILENAME}が正しいJSON形式ではありません"
                        echo
                    else
                        echo "サーバでホストされている${POOL_META_FILENAME}を参照しています"
                        curl -s "${poolMetaurl}" | jq .
                        echo
                        Gum_Confirm_YesNo "このデータでよろしいですか？" "Yes" "最初からやり直す場合はツールを再実行してください"
                        
                        if [[ ${iniSettings} == "Yes" ]]; then
                          echo "正常"
                          echo "POOL_METADATA_URL=\"${poolMetaurl}\"" >> ${currentDir}/env
                          wget -q -O ${NODE_HOME}/${POOL_META_FILENAME} ${poolMetaurl}
                          cardano-cli stake-pool metadata-hash --pool-metadata-file ${NODE_HOME}/${POOL_META_FILENAME} > ${NODE_HOME}/poolMetaDataHash.txt
                          echo "${NODE_HOME}/poolMetaDataHash.txtを作成しました"
                          echo
                          break
                        else
                          echo
                          echo "${iniSettings}"
                          echo
                          Gum_OneSelect "戻る"
                        fi
                    fi
                  else
                    echo "URLが無効です。再度ご確認ください。${httpResponsCode}"
                    echo
                  fi
                done
              else
                echo
                echo "${iniSettings}"
                echo
                Gum_OneSelect "戻る"
              fi
            else
              echo "プール情報がすでに登録されています"
              echo 
              style "プール名:" "${META_POOL_NAME}"
              style "ティッカー:" "${META_TICKER}"
              style "プール説明:" "${META_DISCRIPTION}"
              style "プールURL:" "${META_HOMEPAGE_URL}"
              echo
              Gum_OneSelect "戻る"
            fi
          ;;
          "プールウォレット確認${walletCheck}" )
            checkPaymentFile=$(PathEnabledCheck "${NODE_HOME}/${PAYMENT_ADDR_FILENAME}" "Yes" "No")
            if [ "${NODE_TYPE}" == "ブロックプロデューサー" ]; then
              if [ "${checkPaymentFile}" == "Yes" ]; then
                echo "${PAYMENT_ADDR_FILENAME}ファイルが見つかりました"
                while :
                do
                  CheckWallet
                  #total_balance=""
                  echo
                  if [ "${total_balance}" == 0 ]; then
                    echo "ウォレット残高がありません"
                    echo "まずは上記のアドレスに少額からテスト送金してください" 
                    echo
                    res=$(gum choose --header="処理を選択してください" --height=4 --no-show-help "残高再確認" "メニュへ戻る")
                    if [ "${res}" == "メニュへ戻る" ]; then
                      break
                    fi
                  elif [ "${total_balance}" -ge 1 ] && [ "${total_balance}" -le 600000000 ]; then
                    echo "ウォレットには1ADA以上が入金されています。"
                    echo
                    echo "プール登録には以下の費用が必要です。追加の費用を送金してください(最低600ADA)"
                    echo
                    style "プール登録料:" "500ADA"
                    style "ステークキー登録料": "2ADA"
                    style "Pledge(誓約金):" "誓約として設定したい額"
                    echo
                    res=$(gum choose --header="処理を選択してください" --height=4 --no-show-help "残高再確認" "メニュへ戻る")
                    if [ "${res}" == "メニュへ戻る" ]; then
                      break
                    fi
                  else
                    Gum_OneSelect "戻る"
                      break
                  fi
                done
              else
                echo "${PAYMENT_ADDR_FILENAME}ファイルが見つかりません"
                echo "エアギャップマシンで当ツールを起動し、「プール構築」→「プールウォレット作成」を実行してください"
                echo
                Gum_OneSelect "戻る"
              fi
            else
              echo "エアギャップマシンで当ツールを起動し、「プール構築」→「プールウォレット作成」を実行してください"
              echo
              Gum_OneSelect "戻る"
            fi
          ;;

          "トポロジー構成" )
          if [ "${NODE_TYPE}" == "ブロックプロデューサー" ]; then

            while :
            do
              inputRelayNum=$(gum input --value="2" --width=0 --header="運用するリレー数を入力してください" --char-limit=1 --header.foreground="99" --no-show-help --placeholder "Number Of Relay")
                # 入力が数字かどうかを確認
              if [[ "$inputRelayNum" =~ ^[0-9]+$ ]]; then
                # 配列を使用して変数を管理
                declare -a inputRelays
                declare -a inputPorts
                topologyRelays=""

                # ループを実行
                for ((i = 1; i <= $inputRelayNum; i++)); do
                  if [ "$i" -ge "2" ]; then poolRelaySet+="   "; fi
                  inputRelayAddress=$(gum input --width=0 --header="リレー${i}のIPまたはDNSアドレスを入力してください" --char-limit=255 --header.foreground="99" --no-show-help --placeholder "IP Address or DNS Name")
                  inputRelays[$i]=${inputRelayAddress}
                  inputRelayPort=$(gum input --value="6000" --width=0 --header="リレー${i}のポート番号を入力してください" --char-limit=255 --header.foreground="99" --no-show-help --placeholder "Realy Port")
                  inputPorts[$i]=${inputRelayPort}

                  # 正規表現でIPv4アドレスの形式をチェック
                  if [[ $inputRelayAddress =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                      # 各オクテットが0〜255の範囲内であることをチェック
                      IFS='.' read -r -a octets <<< "$inputRelayAddress"
                      valid=true
                      for octet in "${octets[@]}"; do
                          if (( octet < 0 || octet > 255 )); then
                              valid=false
                              break
                          fi
                      done
                      if [ "$valid" = true ]; then
                          topologyRelays+=$(cat << EOF
{
      "address": "${inputRelayAddress}",
      "port": "${inputRelayPort}"
      },

EOF
)
                      else
                          echo "無効なIPアドレスです"
                          break 1
                      fi
                  else
                      topologyRelays+=$(cat << EOF
{
"address": "${inputRelayAddress}",
"port": "${inputRelayPort}"
},
EOF
)
                  fi
                done
                break 1
              else
                echo "数字を入力してください"
                exit 1
              fi
            done
            createTopologyBp=$(cat <<- EOF
{
"bootstrapPeers": null,
"localRoots": [
    {
      "accessPoints": [
        ${topologyRelays}
      ],
      "advertise": false,
      "trustable": true,
      "valency": 2 
    }
],
"publicRoots": [],
"useLedgerAfterSlot": -1 
}
EOF
)
          echo "${createTopologyBp}"
          echo "${createTopologyBp}" > $NODE_HOME/${NODE_CONFIG}-topology.json
          echo
          Gum_Confirm_YesNo "この値でtopologyを生成しますか？" "Yes" "再度入力してください"
          if [[ ${iniSettings} == "Yes" ]]; then
          　echo "topologyを生成しました"
          else
          echo ${iniSettings}
          break 1
          echo
          fi
          elif [ "${NODE_TYPE}" == "リレー" ]; then
            echo "まだ実装していません"
          else
            echo "まだ実装していません"
          fi
          ;;

          "BP用キー作成${bpKeyCreateCheck}" )
          if [ "${NODE_TYPE}" == "エアギャップ" ] && [ ! -e ${COLDKEYS_DIR} ]; then

            mkdir ${COLDKEYS_DIR}
            cardano-cli node key-gen --cold-verification-key-file ${COLDKEYS_DIR}/${COLD_VKEY_FILENAME} --cold-signing-key-file ${COLDKEYS_DIR}/${COLD_SKEY_FILENAME} --operational-certificate-issue-counter ${COLDKEYS_DIR}/${COUNTER_FILENAME}
            if [ $? -eq 0 ]; then
              echo "コールドキーを読み取り専用で作成しました"
              echo ${COLDKEYS_DIR}/${COLD_VKEY_FILENAME}
              echo ${COLDKEYS_DIR}/${COLD_SKEY_FILENAME}
              echo
              echo "このキーペアはプール運営で最も大切な鍵ファイルであり、紛失するとプール運営を継続できなくなりますのでご注意下さい"
              echo "複数のUSBドライブなどにバックアップを推奨します"
              chmod 400 ${COLDKEYS_DIR}/${COLD_VKEY_FILENAME}; chmod 400 ${COLDKEYS_DIR}/${COLD_SKEY_FILENAME}
            else
              echo "コールドキーの生成に失敗しました"
            fi
          fi

          if [[ ${NODE_TYPE} == "ブロックプロデューサー" ]] && [ -e "${NODE_HOME}"/"${KES_SKEY_FILENAME}" ] && [ -e "${NODE_HOME}"/"${KES_VKEY_FILENAME}" ] && [ -e "${NODE_HOME}"/"${NODE_CERT_FILENAME}" ] && [ -e "${NODE_HOME}"/"${VRF_SKEY_FILENAME}" ] && [ -e "${NODE_HOME}"/"${VRF_VKEY_FILENAME}" ]; then
            echo
            echo "以下のBP用ファイルが存在します"
            FilePathAndHash ${NODE_HOME}/${KES_SKEY_FILENAME}
            FilePathAndHash ${NODE_HOME}/${KES_VKEY_FILENAME}
            FilePathAndHash ${NODE_HOME}/${NODE_CERT_FILENAME}
            echo
            FilePathAndHash ${NODE_HOME}/${VRF_VKEY_FILENAME}
            FilePathAndHash ${NODE_HOME}/${VRF_SKEY_FILENAME}
            echo
            Gum_OneSelect "戻る"
          elif [ ! -e "${NODE_HOME}"/"${VRF_SKEY_FILENAME}" ] && [ ! -e "${NODE_HOME}"/"${VRF_VKEY_FILENAME}" ]; then
            cardano-cli query protocol-parameters $NODE_NETWORK --out-file ${NODE_HOME}/params.json
            cardano-cli node key-gen-VRF --verification-key-file ${NODE_HOME}/${VRF_VKEY_FILENAME} --signing-key-file ${NODE_HOME}/${VRF_SKEY_FILENAME}
            if [ $? -eq 0 ]; then
              echo "VRFキーを読み取り専用で生成しました"
              FilePathAndHash ${NODE_HOME}/${VRF_VKEY_FILENAME}
              FilePathAndHash ${NODE_HOME}/${VRF_SKEY_FILENAME}
              echo
              echo "VRFキーペアはブロック生成で使用する鍵ファイルです。紛失するとブロック生成できなくなりますのでご注意ください"
              echo "複数のUSBドライブなどにバックアップを推奨します"
              chmod 400 ${NODE_HOME}/${VRF_VKEY_FILENAME}; chmod 400 ${NODE_HOME}/${VRF_VKEY_FILENAME}
              echo "ブロックプロデューサーで作成した${VRF_VKEY_FILENAME}と${VRF_VKEY_FILENAME}をエアギャップの作業ディレクトリにコピーしてください"

              read -p "ハッシュ値が一致したらEnterを押してください"
            else
              echo "VRFキーの生成に失敗しました"
            fi

          else
            KesCreate ${NODE_TYPE}
          fi
            # KES作成
            # node.cert作成
            # VRF作成

          ;;

          
          "プールウォレット作成 ${walletKeyCheck}" )
            if [ "${NODE_TYPE}" == "エアギャップ" ] && [ "${walletKeyCheck}" == "❌" ] ; then
              echo "プール運営に必要なウォレットとステークアドレスを作成します"
              echo "それぞれの秘密鍵(skey)、公開鍵(vkey)、アドレスファイル(addr)を生成します"
              echo
              Gum_Confirm_YesNo "作成してよろしいですか？" "Yes" "最初からやり直す場合はツールを再実行してください"

              if [ "${iniSettings}" == "Yes" ]; then
                cardano-cli address key-gen --verification-key-file ${NODE_HOME}/${PAYMENT_VKEY_FILENAME} --signing-key-file ${NODE_HOME}/${PAYMENT_SKEY_FILENAME}
                cardano-cli stake-address key-gen --verification-key-file ${NODE_HOME}/${STAKE_VKEY_FILENAME} --signing-key-file ${NODE_HOME}/${STAKE_SKEY_FILENAME}
                cardano-cli address build --payment-verification-key-file ${NODE_HOME}/${PAYMENT_VKEY_FILENAME} --stake-verification-key-file ${NODE_HOME}/${STAKE_VKEY_FILENAME} --out-file ${NODE_HOME}/${PAYMENT_ADDR_FILENAME} ${NODE_NETWORK}
                cardano-cli stake-address build --stake-verification-key-file ${NODE_HOME}/${STAKE_VKEY_FILENAME} --out-file ${NODE_HOME}/${STAKE_ADDR_FILENAME} ${NODE_NETWORK}
                cardano-cli stake-address registration-certificate --stake-verification-key-file ${NODE_HOME}/${STAKE_VKEY_FILENAME} --out-file ${NODE_HOME}/${STAKE_CERT_FILENAME}

                chmod 400 ${NODE_HOME}/${PAYMENT_VKEY_FILENAME}
                chmod 400 ${NODE_HOME}/${PAYMENT_SKEY_FILENAME}
                chmod 400 ${NODE_HOME}/${STAKE_VKEY_FILENAME}
                chmod 400 ${NODE_HOME}/${STAKE_SKEY_FILENAME}
                chmod 400 ${NODE_HOME}/${STAKE_ADDR_FILENAME}
                chmod 400 ${NODE_HOME}/${PAYMENT_ADDR_FILENAME}

                echo
                echo "ウォレットキーペアを以下のパスに生成しました"
                find ${NODE_HOME} -type f -name "payment.*key"
                find ${NODE_HOME} -type f -name "stake.*key"
                YellowStyle "skeyを紛失するとアドレス内の資産を失うことになりますのでご注意下さい"
                echo "複数USBドライブなどにバックアップすることをおすすめします"
                echo
                echo "アドレスファイルを以下のパスに生成しました"
                find ${NODE_HOME} -type f -name "${PAYMENT_ADDR_FILENAME}"
                find ${NODE_HOME} -type f -name "${STAKE_ADDR_FILENAME}"
                echo
                echo "ステーク証明書を以下のパスに生成しました"
                find ${NODE_HOME} -type f -name "${STAKE_CERT_FILENAME}"
                echo
                echo "以下の3ファイルをブロックプロデューサーの作業ディレクトリ(~/cnode) にコピーしてください。"
                YellowStyle "${PAYMENT_ADDR_FILENAME}"
                YellowStyle "${STAKE_ADDR_FILENAME}"
                YellowStyle "${STAKE_CERT_FILENAME}"
                echo
                Gum_OneSelect "戻る"
                echo
              else
                echo
                echo "${iniSettings}"
                echo
                Gum_OneSelect "戻る"
              fi
            else
              echo "ウォレット作成済みです"
              echo
              style "ウォレットアドレス：" "$(echo $(cat ${NODE_HOME}/${PAYMENT_ADDR_FILENAME}))"
              style "ステークアドレス：" "$(echo $(cat ${NODE_HOME}/${STAKE_ADDR_FILENAME}))"
              echo
              Gum_OneSelect "戻る"
            fi
          ;;

          "ステークアドレス登録" )
            echo "ステークアドレスをチェーンに登録します"
            Cli_CurrentSlot
            CheckWallet &> /dev/null
            echo $fee
            stakeAddressDeposit=$(cat $NODE_HOME/params.json | jq -r '.stakeAddressDeposit')
            style "ステークアドレス:" "$(cat ${NODE_HOME}/${STAKE_ADDR_FILENAME})"
            echo
            cardano-cli transaction build-raw ${tx_in} --tx-out $(cat ${NODE_HOME}/${PAYMENT_ADDR_FILENAME})+0 --invalid-hereafter $(( ${currentSlot} + 10000)) --fee 0 --certificate-file ${NODE_HOME}/${STAKE_CERT_FILENAME} --out-file ${NODE_HOME}/tx.tmp
            Cli_FeeCal
            txOut=$((${total_balance}-${stakeAddressDeposit}-${fee}))
            Gum_DotSpinner3 "トランザクションを構築しています"
            cardano-cli transaction build-raw ${tx_in} --tx-out $(cat ${NODE_HOME}/${PAYMENT_ADDR_FILENAME})+${txOut} --invalid-hereafter $(( ${currentSlot} + 10000)) --fee ${fee} --certificate-file ${NODE_HOME}/${STAKE_CERT_FILENAME} --out-file ${NODE_HOME}/tx.raw
            if [ $? -eq 0 ]; then
              Cli_TxRawCheck
            else
            echo "Txファイルの生成に失敗しました"
            echo
            Gum_OneSelect "戻る"
            fi
          ;;

          "プール登録" )
            if [ -e ${NODE_HOME}/pool.cert ] && [ -e ${NODE_HOME}/deleg.cert ]; then
              CheckWallet
              poolDeposit=$(cat ${NODE_HOME}/params.json | jq -r '.stakePoolDeposit')
              currentSlot=$(cardano-cli query tip $NODE_NETWORK | jq -r '.slot')
              cardano-cli transaction build-raw ${tx_in} --tx-out $(cat ${NODE_HOME}/payment.addr)+$(( ${total_balance} - ${poolDeposit}))  --invalid-hereafter $(( ${currentSlot} + 10000)) --fee 0 --certificate-file ${NODE_HOME}/pool.cert --certificate-file ${NODE_HOME}/deleg.cert --out-file ${NODE_HOME}/tx.tmp
              fee=$(cardano-cli transaction calculate-min-fee --tx-body-file ${NODE_HOME}/tx.tmp --tx-in-count ${txcnt} --tx-out-count 1 $NODE_NETWORK --witness-count 3 --byron-witness-count 0 --protocol-params-file ${NODE_HOME}/params.json | awk '{ print $1 }')
              txOut=$((${total_balance}-${poolDeposit}-${fee}))
              Gum_DotSpinner3 "トランザクションを構築しています"
              cardano-cli transaction build-raw ${tx_in} --tx-out $(cat ${NODE_HOME}/payment.addr)+${txOut} --invalid-hereafter $(( ${currentSlot} + 10000)) --fee ${fee} --certificate-file ${NODE_HOME}/pool.cert --certificate-file ${NODE_HOME}/deleg.cert --out-file ${NODE_HOME}/tx.raw
              if [ $? -eq 0 ]; then
                echo -e "プール登録料: ${poolDeposit}"
                echo -e トランザクション手数料: $fee
                echo
                Cli_TxRawCheck
              else
                echo "Txファイルの生成に失敗しました"
                echo
                Gum_OneSelect "戻る"
              fi
            else
              echo "登録用ファイルが見つかりません"
            fi
          ;;

          "ステークアドレスTx署名" )
            cardano-cli transaction sign --tx-body-file ${NODE_HOME}/tx.raw --signing-key-file ${NODE_HOME}/${PAYMENT_SKEY_FILENAME} --signing-key-file ${NODE_HOME}/${STAKE_SKEY_FILENAME} $NODE_NETWORK --out-file ${NODE_HOME}/tx.signed
            echo
            echo "トランザクション署名ファイルを生成しました"
            echo "${NODE_HOME}/tx.signed をBPの作業ディレクトリにコピーしてください"
            echo
            Gum_OneSelect "コピーしたらEnterを押して下さい"
          ;;

          "プール登録Tx署名" )
            chmod u+rwx $HOME/cold-keys
            cardano-cli transaction sign --tx-body-file ${NODE_HOME}/tx.raw  --signing-key-file ${NODE_HOME}/${PAYMENT_SKEY_FILENAME} --signing-key-file ${COLDKEYS_DIR}/${COLD_SKEY_FILENAME} --signing-key-file ${NODE_HOME}/${STAKE_SKEY_FILENAME} $NODE_NETWORK --out-file ${NODE_HOME}/tx.signed
            echo
            echo "プール登録Tx署名ファイルを生成しました"
            echo "${NODE_HOME}/tx.signed をBPの作業ディレクトリにコピーしてください"
            echo
            Gum_OneSelect "コピーしたらEnterを押して下さい"
          ;;

          "プール登録証明書作成" )
          CreatePoolCert
          echo
          Gum_OneSelect "完了したらEnterを押して下さい"
          ;;

          "メインメニュー" )
          break
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