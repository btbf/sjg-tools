#!/bin/bash
title="SJG TOOL V2"
backtitle="SPO JAPAN GUILD"
version="0.1.0-α"

# Display menu results in a msgbox
display_result() {
  dialog --title "$1" \
    --backtitle "System Information" \
    --no-collapse \
    --msgbox "$result" 0 0
}

command_result() {
  dialog --title "$1" \
    --backtitle "System Information" \
    --programbox "$result" 30 100
}


#############################
# OS/ノード関連関数
#############################

#システムアップデート
system_update(){
  echo "$password" | sudo -S apt update -y && sudo apt upgrade -y
  sleep 3
}

input_password(){
  password=$(dialog --stdout --title "sudoパスワード" \
  --clear \
  --insecure \
  --passwordbox "sudoパスワードを入力してください" 10 30 2)
}


#ノードインストール
node_install(){

  echo "システムアップデート..."
  sleep 2
  system_update

  echo "$password" | sudo -S apt install git jq bc automake tmux rsync htop curl build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ wget libncursesw5 libtool autoconf liblmdb-dev -y


  #Libsodium Install
  echo "Libsodiumインストール..."
  sleep 2
  mkdir $HOME/git
  cd $HOME/git
  git clone https://github.com/IntersectMBO/libsodium
  cd libsodium
  git checkout dbb48cc
  ./autogen.sh
  ./configure
  make
  echo "$password" | sudo -S make install

  #Secp256k1 Install
  echo "Secp256k1インストール..."
  sleep 2
  cd $HOME/git
  git clone https://github.com/bitcoin-core/secp256k1.git
  cd secp256k1/
  git checkout ac83be33
  ./autogen.sh
  ./configure --prefix=/usr --enable-module-schnorrsig --enable-experimental
  make
  echo "$password" | sudo -S make install

  #blst Install
  echo "blstインストール..."
  sleep 2
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

  echo "$password" | sudo -S cp libblst.pc /usr/local/lib/pkgconfig/
  echo "$password" | sudo -S cp bindings/blst_aux.h bindings/blst.h bindings/blst.hpp  /usr/local/include/
  echo "$password" | sudo -S cp libblst.a /usr/local/lib
  echo "$password" | sudo -S chmod u=rw,go=r /usr/local/{lib/{libblst.a,pkgconfig/libblst.pc},include/{blst.{h,hpp},blst_aux.h}}

  #GHCUP Install
  echo "GHCUPインストール..."
  sleep 2
  cd $HOME
  BOOTSTRAP_HASKELL_NONINTERACTIVE=1
  BOOTSTRAP_HASKELL_NO_UPGRADE=1
  BOOTSTRAP_HASKELL_INSTALL_NO_STACK=yes
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
  echo "ノードインストール"

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

  echo "設定ファイルダウンロード..."

  mkdir $NODE_HOME
  cd $NODE_HOME
  wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/byron-genesis.json -O ${NODE_CONFIG}-byron-genesis.json
  wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/topology.json -O ${NODE_CONFIG}-topology.json
  wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/shelley-genesis.json -O ${NODE_CONFIG}-shelley-genesis.json
  wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/alonzo-genesis.json -O ${NODE_CONFIG}-alonzo-genesis.json
  wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/conway-genesis.json -O ${NODE_CONFIG}-conway-genesis.json
  wget -q https://book.play.dev.cardano.org/environments/${NODE_CONFIG}/config.json -O ${NODE_CONFIG}-config.json

  echo "設定ファイルダウンロードしました"


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
  echo "設定ファイルを書き換えました"
  echo

	echo
  echo "起動スクリプトを作成します"
  echo
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
  echo "起動スクリプトを作成しました"
  echo

	echo
	echo "gliveViewをインストールします..."
	echo

	mkdir $NODE_HOME/scripts
	cd $NODE_HOME/scripts
	echo "$password" | sudo -S sudo apt install bc tcptraceroute -y

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
	echo "gliveViewをインストールしました..."
	echo

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

  echo "$password" | sudo -S apt install -y libssl-dev build-essential m4 jq
  cd $HOME/git
  git clone https://github.com/input-output-hk/mithril.git
  cd mithril
  git fetch --all --prune
  git checkout tags/2347.0
  cd mithril-client-cli
  make build
  echo "$password" | sudo -S mv mithril-client /usr/local/bin/mithril-client

  export NETWORK=${NODE_CONFIG}
  export AGGREGATOR_ENDPOINT=https://aggregator.release-mainnet.api.mithril.network/aggregator
  export GENESIS_VERIFICATION_KEY=$(wget -q -O - https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/genesis.vkey)
  export SNAPSHOT_DIGEST=latest

  mithril-client snapshot download --download-dir $NODE_HOME latest


	echo
  echo "サービスファイルを作成します"
  echo

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

		echo "$password" | sudo -S cp $NODE_HOME/cardano-node.service /etc/systemd/system/cardano-node.service
		sudo chmod 644 /etc/systemd/system/cardano-node.service
		sudo systemctl daemon-reload
		sudo systemctl enable cardano-node
    sudo systemctl start cardano-node

		echo
		echo "サービスファイルを作成しました"
		echo

}


while true; do
  selection0=$(dialog --stdout --backtitle "$backtitle" --title "$title" \
  --clear --cancel-label "Exit" --menu "Please select:" 0 0 5 \
    "1" "プール構築" \
    "2" "プール運用" \
    "3" "ツール設定" \
     )
  exit_status=$?
  if [ $exit_status == 1 ] ; then
      clear
      exit
  fi
  case $selection0 in
    1 )
      selection1=$(dialog --stdout --backtitle "$backtitle" --title "$title" \
        --clear --cancel-label "戻る" --menu "Please select:" 0 0 5 \
        "1" "ノードセットアップ" \
        "2" "プール作成・登録" \
        )
        case $selection1 in
        1 )
          input_password
          node_install | dialog --programbox "Dependency Install" 50 200
        ;;
        esac
      ;;
    2 )
      result=$(df -h)
      display_result "Disk Space"
      ;;
    3 )
      result=$(vmstat --stats)
      display_result "Memory Stats"
      ;;
  esac
done