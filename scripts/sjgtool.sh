#!/bin/bash
# shellcheck disable=SC1091

source "${HOME}"/.bashrc

Header(){
  gum style \
	--foreground 212 --border-foreground 212 --border double \
	--align center --width 50 --margin "1 2" --padding "2 4" \
	'SJGTOOL V2' 'v.0.1.2'
}

style(){
  echo '{{ Color "15" " '"$1"' " }}''{{ Color "11" " '"$2"' " }}' \
    | gum format -t template
}

YellowStyle(){
  echo '{{ Color "11" "0" " '"$1"' " }}' \
    | gum format -t template
}

SystemUpdate(){
  YellowStyle "システムアップデート..."
  echo
  gum input --password | sudo -S apt update -y && sudo apt upgrade -y
  YellowStyle "アップデートしました"
  sleep 3
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
  mkdir "${HOME}"/git
  cd "${HOME}"/git || exit
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
  cd "${HOME}"/git || exit
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
  cd "${HOME}"/git || exit
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
  cd "${HOME}" || exit
  BOOTSTRAP_HASKELL_NONINTERACTIVE=1
  BOOTSTRAP_HASKELL_NO_UPGRADE=1
  BOOTSTRAP_HASKELL_ADJUST_BASHRC=1
  unset BOOTSTRAP_HASKELL_INSTALL_HLS
  export BOOTSTRAP_HASKELL_NONINTERACTIVE BOOTSTRAP_HASKELL_NO_UPGRADE BOOTSTRAP_HASKELL_ADJUST_BASHRC

  curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | bash

  source "${HOME}"/.ghcup/env
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
  mkdir "${HOME}"/git/cardano-node
  cd "${HOME}"/git/cardano-node || exit
  wget https://github.com/IntersectMBO/cardano-node/releases/download/8.7.3/cardano-node-8.7.3-linux.tar.gz
  tar zxvf cardano-node-8.7.3-linux.tar.gz ./cardano-node ./cardano-cli
  $(find "${HOME}"/git/cardano-node -type f -name "cardano-cli") version
  $(find "${HOME}"/git/cardano-node -type f -name "cardano-node") version

  sudo cp "$(find "${HOME}"/git/cardano-node -type f -name "cardano-cli")" /usr/local/bin/cardano-cli
  sudo cp "$(find "${HOME}"/git/cardano-node -type f -name "cardano-node")" /usr/local/bin/cardano-node

  cardano-cli version
  cardano-node version
  echo
  YellowStyle "設定ファイルダウンロード..."
  echo
  sleep 3
  mkdir "${NODE_HOME}"
  cd "${NODE_HOME}" || exit
  wget -q https://book.play.dev.cardano.org/environments/"${NODE_CONFIG}"/byron-genesis.json -O "${NODE_CONFIG}"-byron-genesis.json
  wget -q https://book.play.dev.cardano.org/environments/"${NODE_CONFIG}"/topology.json -O "${NODE_CONFIG}"-topology.json
  wget -q https://book.play.dev.cardano.org/environments/"${NODE_CONFIG}"/shelley-genesis.json -O "${NODE_CONFIG}"-shelley-genesis.json
  wget -q https://book.play.dev.cardano.org/environments/"${NODE_CONFIG}"/alonzo-genesis.json -O "${NODE_CONFIG}"-alonzo-genesis.json
  wget -q https://book.play.dev.cardano.org/environments/"${NODE_CONFIG}"/conway-genesis.json -O "${NODE_CONFIG}"-conway-genesis.json
  wget -q https://book.play.dev.cardano.org/environments/"${NODE_CONFIG}"/config.json -O "${NODE_CONFIG}"-config.json
  echo
  YellowStyle "設定ファイルダウンロードしました"
  echo

  sed -i "${NODE_CONFIG}"-config.json \
      -e 's!"AlonzoGenesisFile": "alonzo-genesis.json"!"AlonzoGenesisFile": "'"${NODE_CONFIG}"'-alonzo-genesis.json"!' \
      -e 's!"ByronGenesisFile": "byron-genesis.json"!"ByronGenesisFile": "'"${NODE_CONFIG}"'-byron-genesis.json"!' \
      -e 's!"ShelleyGenesisFile": "shelley-genesis.json"!"ShelleyGenesisFile": "'"${NODE_CONFIG}"'-shelley-genesis.json"!' \
      -e 's!"ConwayGenesisFile": "conway-genesis.json"!"ConwayGenesisFile": "'"${NODE_CONFIG}"'-conway-genesis.json"!' \
      -e "s/TraceMempool\": false/TraceMempool\": true/g" \
      -e 's!"TraceBlockFetchDecisions": false!"TraceBlockFetchDecisions": true!' \
      -e 's!"rpKeepFilesNum": 10!"rpKeepFilesNum": 30!' \
      -e 's!"rpMaxAgeHours": 24!"rpMaxAgeHours": 48!' \
      -e '/"defaultScribes": \[/a\    \[\n      "FileSK",\n      "'"${NODE_CONFIG}"'/logs/node.json"\n    \],' \
      -e '/"setupScribes": \[/a\    \{\n      "scFormat": "ScJson",\n      "scKind": "FileSK",\n      "scName": "'"${NODE_CONFIG}"'/logs/node.json"\n    \},' \
      -e "s/127.0.0.1/0.0.0.0/g"

  echo
  YellowStyle "設定ファイルを書き換えました"
  echo

  echo
  YellowStyle "起動スクリプトを作成します"
  echo
  sleep 3
	PORT=6000
	cat <<-EOF > "${NODE_HOME}"/startBlockProducingNode.sh
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

  cd "${NODE_HOME}" || exit
  chmod +x startBlockProducingNode.sh

	echo
  YellowStyle "起動スクリプトを作成しました"
  echo

  echo
  YellowStyle "gliveViewをインストールします..."
  echo
  sleep 3
  mkdir "${NODE_HOME}"/scripts
  cd "${NODE_HOME}"/scripts || exit
  sudo sudo apt install bc tcptraceroute -y

  curl -s -o gLiveView.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/gLiveView.sh
  curl -s -o env https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/env
  chmod 755 gLiveView.sh

  sed -i "${NODE_HOME}"/scripts/env \
  -e '1,73s!#CNODE_HOME="/opt/cardano/cnode"!CNODE_HOME=${NODE_HOME}!' \
  -e '1,73s!#CNODE_PORT=6000!CNODE_PORT='"${PORT}"'!' \
  -e '1,73s!#UPDATE_CHECK="Y"!UPDATE_CHECK="N"!' \
  -e '1,73s!#CONFIG="${CNODE_HOME}/files/config.json"!CONFIG="${CNODE_HOME}/'"${NODE_CONFIG}"'-config.json"!' \
  -e '1,73s!#SOCKET="${CNODE_HOME}/sockets/node0.socket"!SOCKET="${CNODE_HOME}/db/socket"!'

  echo
  YellowStyle "gliveViewをインストールしました..."
  echo


  echo
  YellowStyle "Mithrilクライアントをインストールします..."
  echo
  sleep 3
  #Rustインストール
  mkdir -p "${HOME}"/.cargo/bin
  chown -R "${USER}" "${HOME}"/.cargo
  touch "${HOME}"/.profile
  chown "${USER}" "${HOME}"/.profile

  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source "${HOME}"/.cargo/env
  rustup install stable
  rustup default stable
  rustup update

  sudo apt install -y libssl-dev build-essential m4 jq
  cd "${HOME}"/git || exit
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

  NETWORK="${NODE_CONFIG}"
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
  mithril-client snapshot download --download-dir "${NETWORK}" latest

  echo
  YellowStyle "DBスナップショットをダウンロードしました..."
  echo

  echo
  YellowStyle "サービスファイルを作成します"
  echo
  sleep 3
	cat > "${NODE_HOME}"/cardano-node.service <<-EOF
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

  gum input --password | sudo -S cp "${NODE_HOME}"/cardano-node.service /etc/systemd/system/cardano-node.service
  sudo chmod 644 /etc/systemd/system/cardano-node.service
  sudo systemctl daemon-reload
  sudo systemctl enable cardano-node
  sudo systemctl start cardano-node

  echo
  YellowStyle "サービスファイルを作成しました"
  echo
}


clear
Header
style "対象ネットワーク:" "$NODE_CONFIG"
selection0=$(gum choose "プール構築" "プール運用" "ツール設定" "終了")

case $selection0 in
    "プール構築" )
      while :
      do
        clear
        Header
        selection1=$(gum choose "ノードセットアップ" "プール作成・登録" "終了")
        nodeBynarlyPath=$(which cardano-node)
        cliBynalyPath=$(which cardano-cli)
          case $selection1 in
            "ノードセットアップ" )
              if [ -z "${nodeBynarlyPath}" ]; then
                echo "ノードセットアップをスタートします..."
                echo
                sleep 2
                SystemUpdate
                NodeInstall
                echo "gliveコマンドを実行してgLiveViewを起動してください..."
                sleep 2
              else 
                cardano-node --version
                cardano-cli --version
                echo "cardano-nodeはインストール済みです"
                echo
                gum choose "戻る"
              fi
            ;;
            "プール作成・登録" )
              echo "この機能はまだありません"
              echo
              gum choose "戻る"
            ;;
            "終了" )
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