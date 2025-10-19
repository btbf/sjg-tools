# SPOKIT

SPOKIT v0.4.0

## インストール前の準備物
- Ubuntuサーバー(メインネットの場合は最低3台)
- エアギャップマシン
- 各マシンはsudo権限を持つ一般ユーザーでログイン
- ターミナルソフト(R-Login/Termius/etc...)
- SFTPソフト(FileZilla/etc...)

## 推奨サーバースペック
項目 | BP/リレー | エアギャプ |
|-----|-----|-----|
OS | Ubuntu22.04 | Win/Mac/Ubuntu
RAM | 24GB以上 | 8GB以上 |
SSD | 500GB以上 | 100GB以上 |

## プール用サーバーセットアップ

### インストール
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/btbf/sjg-tools/refs/heads/main/scripts/install.sh)"
```

### 環境変数再読み込み
```
source $HOME/.bashrc
```

### 起動
①Ubuntuセキュリティ設定
```
spokit ubuntu
```

②プール構築
```
spokit pool
```

③プール運用
```
spokit
```

## エアギャップセットアップ

```
**Win/Macの場合は以下手順でUbuntu仮想環境を作成する**
仮想環境セットアップ手順
https://docs.spojapanguild.net/setup/air-gap-guid/
```

### インストール
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/btbf/sjg-tools/refs/heads/main/scripts/airgap-setup.sh)"
```

### 環境変数再読み込み
```
source $HOME/.bashrc
```