#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2086,SC1001,SC2317
# shellcheck source="$HOME/.bashrc"


#環境設定
cat > ~/.tmux.conf << EOF
set -g default-terminal "screen-256color"
EOF

#ライブラリインストール
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum

#ファイルダウンロード
cd /usr/local/bin || { echo "Failure"; exit 1; }
git clone https://github.com/btbf/sjg-tools.git
cd sjg-tools || { echo "Failure"; exit 1; }
git fetch --all --recurse-submodules --tags
git checkout tags/0.2.0-alpha

cd scripts || { echo "Failure"; exit 1; }
chmod 755 start.sh
chmod 755 sjgtool.sh

./start.sh