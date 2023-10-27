#!/usr/bin/env bash

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

dependency_install(){
  echo
  echo "システムアップデートを開始します"
  echo

  sudo apt update -y && sudo apt upgrade -y
  sleep 3

  echo
  echo "依存関係インストールを開始します"
  echo
  sudo apt install git jq bc automake tmux rsync htop curl build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ wget libncursesw5 libtool autoconf liblmdb-dev -y
  sleep 3


  echo
  echo "libsodiumインストールを開始します"
  echo
  git clone https://github.com/input-output-hk/libsodium
  cd libsodium
  git checkout dbb48cc
  ./autogen.sh
  ./configure
  make
  make check
  sudo make install

  echo
  echo "Secp256k1ライブラリインストールを開始します"
  echo

  cd $HOME/git
  git clone https://github.com/bitcoin-core/secp256k1.git
  cd secp256k1/
  git checkout ac83be33
  ./autogen.sh
  ./configure --prefix=/usr --enable-module-schnorrsig --enable-experimental
  make
  make check
  sudo make install

  echo
  echo "Secp256k1ライブラリインストールしました"
  echo
}

while true; do
  selection=$(dialog --stdout \
    --backtitle "SPO JAPAN GUILD" \
    --title "SJGTOOLV2 POC" \
    --clear \
    --cancel-label "Exit" \
    --menu "Please select:" 0 0 4 \
    "1" "依存関係インストール" \
    "2" "Cardano-nodeインストール" \
     )
  exit_status=$?
  if [ $exit_status == 1 ] ; then
      clear
      exit
  fi
  case $selection in
    1 )
      dependency_install 2>/dev/null | dialog --programbox "Dependency Install" 50 200
      #result=$(sudo apt-get update -y && sudo apt upgrade -y)
      #command_result "Update"
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