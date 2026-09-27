#!/bin/bash

# AquesTalkPiの実行ファイルのパス（必要に応じて変更してください）
#AQUESTALK_BIN="./AquesTalkPi"
AQUESTALK_BIN="/home/pi/root/sys/env/tool/aquestalkpi/1.20/AquesTalkPi"

# 引数のチェック
if [ $# -eq 0 ]; then
    echo "使用方法: $0 \"しゃべらせるテキスト\""
    exit 1
fi

TEXT="$1"

# AquesTalkPiの出力をSoXでイコライジングしてaplayで再生
# - equalizer 3000 1.5k +6 : 3kHz周辺を+6dBブーストし、明瞭度を上げてこもりを解消
# - equalizer 500 1k -2    : こもり感の原因になりやすい500Hz周辺を-2dBカットしてすっきりさせる
"$AQUESTALK_BIN" "$TEXT" | sox -t wav - -t wav - \
    equalizer 3000 1.5k +6 \
    equalizer 500 1k -2 | aplay -q
