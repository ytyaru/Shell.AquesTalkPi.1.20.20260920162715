#!/bin/bash

# 1. 各種設定
AQTKPI="/home/pi/root/sys/env/tool/aquestalkpi/1.20/AquesTalkPi"
TEXT="アクエストークパイの音質改善テストです。サシスセソ、ツクシ。"

# 一時ファイルの保存先
ORIGINAL_WAV="/tmp/aq_original.wav"
EQ_WAV="/tmp/aq_high_res.wav"

# 2. 音声ファイルの生成（8000Hzオリジナル）
"$AQTKPI" "$TEXT" > "$ORIGINAL_WAV"

# 3. 16kHzアップサンプリング＋イコライザ＋エラー（クリッピング）対策
"$AQTKPI" "$TEXT" | sox -t wav - -r 16000 -t wav - gain -3 highpass 100 equalizer 1800 1.0q 5 equalizer 3600 0.8q 7 norm -1 > "$EQ_WAV"

# 4. 連続再生して聴き比べ
echo "========================================"
echo "◆ 1番目：【オリジナル】（制限あり 8000Hz）"
echo "========================================"
aplay -r 8000 -f S16_LE -c 1 "$ORIGINAL_WAV"

sleep 1

echo "========================================"
echo "◆ 2番目：【制限解除・16kHz化イコライザ版】（エラー対策済）"
echo "========================================"
aplay -r 16000 -f S16_LE -c 1 "$EQ_WAV"

# 5. 後片付け
rm -f "$ORIGINAL_WAV" "$EQ_WAV"

exit 0
