#!/usr/bin/env bash

#sudo apt update -y && sudo apt upgrade -y
#echo export NODE_CONFIG=mainnet >> $HOME/.bashrc

mkdir $HOME/git

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