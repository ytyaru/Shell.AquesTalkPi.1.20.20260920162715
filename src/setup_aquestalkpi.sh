#!/bin/bash
##############################################################################
# AquesTalkPi ダウンロード・展開・配置スクリプト。
# 2022/02/07 Ver.1.20 用。
# https://www.a-quest.com/products/aquestalkpi.html
# 公式サイトからダウンロードすると展開できなかったり実行したらエラーになったりする問題がある。
# これらを自動で解決するためのスクリプトである。
# 作成日時: 2026-09-20 
# 公式サイトの問題
# * 拡張子ミス: ダウンロードするとなぜかtgzでなくgzという間違った拡張子になる。このせいで正しくTar展開できない。
# * 参照エラー: bin64/AquesTalkPiの配置から実行すると以下のように実行エラーになる。これは同じ場所にaq_dic/がないせいだ。
#   $ /tmp/work/aquestalkpi/bin64/AquesTalkPi 'テスト' | aplay
#   ERR: cannot find or initialize Dictionary(200)
#   aplay: read_header:2912: リードエラー
##############################################################################
URL="https://www.a-quest.com/archive/package/aquestalkpi-20220207.tgz?download=1&readed=yes"
SAVE_FILE="aquestalkpi-20220207.tgz"
TARGET_DIR="aquestalkpi"

# 1. ダウンロードと展開
echo "=== パッケージを取得・展開します ==="
wget "$URL" -O "$SAVE_FILE"
tar -xzf "$SAVE_FILE"

# 展開先ディレクトリへ移動
cd "$TARGET_DIR" || { echo "エラー: ディレクトリが見つかりません"; exit 1; }

# 2. ディレクトリ構造の再配置
echo "=== ディレクトリ構造を整理します ==="

# 共通の bin ディレクトリを作成
mkdir -p bin

# 64bit環境用のディレクトリ移動（bin64 から bin/64 へ）
if [ -d "bin64" ]; then
    mv bin64 bin/64
fi

# 32bit環境用のディレクトリ移動（ルートから bin/32 へ）
if [ -f "AquesTalkPi" ] && [ ! -L "AquesTalkPi" ]; then
    mkdir -p bin/32
    mv AquesTalkPi bin/32/
fi

# 3. アーキテクチャの判定とシンボリックリンクの作成
ARCH=$(uname -m)
echo "=== 環境判定: $ARCH ==="

# 既存のリンクがあれば削除
rm -f AquesTalkPi

if [ "$ARCH" = "aarch64" ]; then
    echo "64bit環境用のシンボリックリンクを作成します。"
    ln -s bin/64/AquesTalkPi AquesTalkPi
else
    echo "32bit環境用のシンボリックリンクを作成します。"
    ln -s bin/32/AquesTalkPi AquesTalkPi
fi

# 4. 動作確認
echo "=== 動作確認を実行します ==="
if [ -L "AquesTalkPi" ] && [ -e "AquesTalkPi" ]; then
    ./AquesTalkPi 'アクエストークパイの再配置が完了しました' | aplay
    echo "=== すべての手順が正常に完了しました ==="
else
    echo "エラー: シンボリックリンクの作成、または実行バイナリに問題があります。"
fi

