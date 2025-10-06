# SPOKIT

SPOKIT v0.3.9
※現時点でのご利用はテストネットを推奨します。プール運用機能に関しては既知のバグが残っております。v0.4.0で解消予定です。

## 推奨スペック
```
- OS: ubunt22.04
- RAM: 24GB
- STRAGE: 500GB
- sudo権限を持つ任意ユーザーでログイン
```

### インストール前の準備物
- オフラインエアギャップマシン
```
airgap-setup.shを実行してセットアップ
```
- Ubuntuサーバー

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