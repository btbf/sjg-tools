# New SJG-Tools

SJGTOOL V2 α
※現時点ではエラー処理が不十分です。既存で発見されるバグはすでに認知しています。ご利用の際はテストネットでご利用下さい

## 前提条件
```
- OS:Ubuntu20.04/22.04
- sudo権限を持つ任意ユーザーでログイン
```

### インストール
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/btbf/sjg-tools/0.3.0/scripts/install.sh)"
```

### 環境変数再読み込み
```
source $HOME/.bashrc
```

### 起動
プール構築メニュー呼び出し
```
cnm poolsetup
```

プール管理メニュー呼び出し
```
cnm
```