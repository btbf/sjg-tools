#!/usr/bin/env bash

source $HOME/.bashrc

style(){
  echo '{{ Color "15" "0" " '$1' " }}''{{ Color "11" "0" " '$2' " }}' \
    | gum format -t template
}

yellow_style(){
  echo '{{ Color "11" "0" " '$1' " }}' \
    | gum format -t template
}

system_update(){
  yellow_style "システムアップデート..."
  echo
  gum input --password | sudo -S apt update -y && sudo apt upgrade -y
  yellow_style "アップデートしました"
  sleep 3
}

style "対象ネットワーク:" "$NODE_CONFIG"



#ノードインストール
node_install(){

  #依存関係インストール
  sudo apt install git jq bc automake tmux rsync htop curl build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ wget libncursesw5 libtool autoconf liblmdb-dev -y

  echo
  yellow_style "依存関係をインストールしました..."
  echo

  #Libsodium Install
  echo
  yellow_style "Libsodiumインストール..."
  echo
  sleep 3
  mkdir $HOME/git
  cd $HOME/git
  git clone https://github.com/IntersectMBO/libsodium
  cd libsodium
  git checkout dbb48cc
  ./autogen.sh
  ./configure
  make
  sudo make install

  #Secp256k1 Install
  echo
  yellow_style "Secp256k1インストール..."
  echo
  sleep 3
  cd $HOME/git
  git clone https://github.com/bitcoin-core/secp256k1.git
  cd secp256k1/
  git checkout ac83be33
  ./autogen.sh
  ./configure --prefix=/usr --enable-module-schnorrsig --enable-experimental
  make
  sudo make install

  #blst Install
  echo
  yellow_style "blstインストール..."
  echo
  sleep 3
  cd $HOME/git
  git clone https://github.com/supranational/blst
  cd blst
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
  yellow_style "GHCUPインストール..."
  echo
  sleep 3
  cd $HOME
  BOOTSTRAP_HASKELL_NONINTERACTIVE=1
  BOOTSTRAP_HASKELL_NO_UPGRADE=1
  BOOTSTRAP_HASKELL_ADJUST_BASHRC=1
  unset BOOTSTRAP_HASKELL_INSTALL_HLS
  export BOOTSTRAP_HASKELL_NONINTERACTIVE BOOTSTRAP_HASKELL_INSTALL_STACK BOOTSTRAP_HASKELL_ADJUST_BASHRC

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
  yellow_style "ノードインストール"
  echo
  sleep 3
  mkdir $HOME/git/cardano-node
  cd $HOME/git/cardano-node
  wget https://github.com/IntersectMBO/cardano-node/releases/download/8.7.3/cardano-node-8.7.3-linux.tar.gz
  tar zxvf cardano-node-8.7.3-linux.tar.gz ./cardano-node ./cardano-cli
  $(find $HOME/git/cardano-node -type f -name "cardano-cli") version
  $(find $HOME/git/cardano-node -type f -name "cardano-node") version

  sudo cp $(find $HOME/git/cardano-node -type f -name "cardano-cli") /usr/local/bin/cardano-cli
  sudo cp $(find $HOME/git/cardano-node -type f -name "cardano-node") /usr/local/bin/cardano-node

  cardano-cli version
  cardano-node version
  echo
  yellow_style "設定ファイルダウンロード..."
  echo
  sleep 3
  mkdir $NODE_HOME
  cd $NODE_HOME
  wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/byron-genesis.json -O ${NODE_CONFIG}-byron-genesis.json
  wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/topology.json -O ${NODE_CONFIG}-topology.json
  wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/shelley-genesis.json -O ${NODE_CONFIG}-shelley-genesis.json
  wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/alonzo-genesis.json -O ${NODE_CONFIG}-alonzo-genesis.json
  wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/conway-genesis.json -O ${NODE_CONFIG}-conway-genesis.json
  wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/config.json -O ${NODE_CONFIG}-config.json
  echo
  yellow_style "設定ファイルダウンロードしました"
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
      -e '/"defaultScribes": \[/a\    \[\n      "FileSK",\n      "'${NODE_HOME}'/logs/node.json"\n    \],' \
      -e '/"setupScribes": \[/a\    \{\n      "scFormat": "ScJson",\n      "scKind": "FileSK",\n      "scName": "'${NODE_HOME}'/logs/node.json"\n    \},' \
      -e "s/127.0.0.1/0.0.0.0/g"

  echo
  yellow_style "設定ファイルを書き換えました"
  echo

  echo
  yellow_style "起動スクリプトを作成します"
  echo
  sleep 3
	PORT=6000
	cat <<-EOF > ${NODE_HOME}/startBlockProducingNode.sh
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

  cd $NODE_HOME
  chmod +x startBlockProducingNode.sh

	echo
  yellow_style "起動スクリプトを作成しました"
  echo

  echo
  yellow_style "gliveViewをインストールします..."
  echo
  sleep 3
  mkdir $NODE_HOME/scripts
  cd $NODE_HOME/scripts
  sudo sudo apt install bc tcptraceroute -y

  curl -s -o gLiveView.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/gLiveView.sh
  curl -s -o env https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/env
  chmod 755 gLiveView.sh

  sed -i $NODE_HOME/scripts/env \
  -e '1,73s!#CNODE_HOME="/opt/cardano/cnode"!CNODE_HOME=${NODE_HOME}!' \
  -e '1,73s!#CNODE_PORT=6000!CNODE_PORT='${PORT}'!' \
  -e '1,73s!#UPDATE_CHECK="Y"!UPDATE_CHECK="N"!' \
  -e '1,73s!#CONFIG="${CNODE_HOME}/files/config.json"!CONFIG="${CNODE_HOME}/'${NODE_CONFIG}'-config.json"!' \
  -e '1,73s!#SOCKET="${CNODE_HOME}/sockets/node0.socket"!SOCKET="${CNODE_HOME}/db/socket"!'

  echo
  yellow_style "gliveViewをインストールしました..."
  echo


  echo
  yellow_style "Mithrilクライアントをインストールします..."
  echo
  sleep 3
  #Rustインストール
  mkdir -p $HOME/.cargo/bin
  chown -R $USER\: $HOME/.cargo
  touch $HOME/.profile
  chown $USER\: $HOME/.profile

  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source $HOME/.cargo/env
  rustup install stable
  rustup default stable
  rustup update

  sudo apt install -y libssl-dev build-essential m4 jq
  cd $HOME/git
  git clone https://github.com/input-output-hk/mithril.git
  cd mithril
  git fetch --all --prune
  git checkout tags/2403.1
  cd mithril-client-cli
  make build
  sudo mv mithril-client /usr/local/bin/mithril-client

  echo
  yellow_style "Mithrilクライアントをインストールしました..."
  echo

  export NETWORK=${NODE_CONFIG}
  export AGGREGATOR_ENDPOINT=https://aggregator.release-mainnet.api.mithril.network/aggregator
  export GENESIS_VERIFICATION_KEY=$(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/genesis.vkey)
  export SNAPSHOT_DIGEST=latest

  echo
  yellow_style "DBスナップショットをダウンロードします..."
  echo
  sleep 3
  mithril-client snapshot download --download-dir $NODE_HOME latest

  echo
  yellow_style "DBスナップショットをダウンロードしました..."
  echo

  echo
  yellow_style "サービスファイルを作成します"
  echo
  sleep 3
	cat > $NODE_HOME/cardano-node.service <<-EOF
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

  gum input --password | sudo -S cp $NODE_HOME/cardano-node.service /etc/systemd/system/cardano-node.service
  sudo chmod 644 /etc/systemd/system/cardano-node.service
  sudo systemctl daemon-reload
  sudo systemctl enable cardano-node
  sudo systemctl start cardano-node

  echo
  yellow_style "サービスファイルを作成しました"
  echo
}

gum style \
	--foreground 212 --border-foreground 212 --border double \
	--align center --width 50 --margin "1 2" --padding "2 4" \
	'SJGTOOL V2' 'v.0.1.1-alpha'


selection0=$(gum choose "プール構築" "プール運用" "ツール設定")

case $selection0 in
    "プール構築" )
      selection1=$(gum choose "ノードセットアップ" "プール作成・登録")

        case $selection1 in
        "ノードセットアップ" )
          echo "ノードセットアップをスタートします..."
          echo
          sleep 2
          system_update
          node_install
          echo "gliveコマンドを実行してgLiveViewを起動してください..."
          sleep 2
        ;;
        esac
      ;;
    "プール運用" )
        echo "プール運用します"
      ;;
    "ツール設定" )
        echo "ツール設定します"

      ;;
  esac