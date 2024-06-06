# New SJG-Tools

SJGTOOL V2 α
※現時点ではエラー処理が不十分です。既存で発見されるバグはすでに認知しています。ご利用の際はテストネットでご利用下さい

前提条件
```
- OS:Ubuntu20.04/22.04
- sudo権限を持つ任意ユーザーでログイン
```

環境設定
```
cat > ~/.tmux.conf << EOF
set -g default-terminal "screen-256color"
EOF
```

ライブラリインストール
# Debian/Ubuntu
```
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
sudo apt update && sudo apt install gum
```

ダウンロード
```
git clone https://github.com/btbf/sjg-tools.git
cd sjg-tools
git fetch --all --recurse-submodules --tags
git checkout tags/0.2.0-alpha
```

```
cd scripts
chmod 755 start.sh
chmod 755 sjgtool.sh
./start.sh
```