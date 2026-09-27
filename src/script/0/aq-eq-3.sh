#!/bin/bash

# 1. 各種設定
AQTKPI="/home/pi/root/sys/env/tool/aquestalkpi/1.20/AquesTalkPi"

# 使い方のアナウンス（引数がない場合）
if [ -z "$1" ]; then
  echo "【使い方】: $0 [オプション] \"喋らせたいセリフ\""
  echo "  例1 (デフォルト声): $0 \"こんにちは。\""
  echo "  例2 (女性声2に指定): $0 -v f2 \"こんにちは。\""
  exit 1
fi

# 引数のパース（最後の引数を喋るテキスト、それ以外をオプションとして扱う）
for last; do true; done
TEXT="$last"

OPTIONS=""
while [ $# -gt 1 ]; do
  OPTIONS="$OPTIONS $1"
  shift
done

# 一時ファイルの保存先
ORIGINAL_WAV="/tmp/aq_original.wav"
EQ_WAV="/tmp/aq_loudnorm.wav"

# 2. 音声ファイルの生成
# オリジナルの生データ（8000Hz）を作成
"$AQTKPI" $OPTIONS "$TEXT" > "$ORIGINAL_WAV"

# 声の種類に依存しない「高音全体を緩やかに持ち上げる(treble 3)」＋「YouTube基準(-14LUFS)ラウドネス正規化」
"$AQTKPI" $OPTIONS "$TEXT" | \
  sox -t wav - -t wav -r 44100 - gain -3 rate -v 44100 lowpass 3500 treble 3 | \
  ffmpeg -y -i - -af "loudnorm=I=-14:TP=-1.5:LRA=7" -ar 44100 "$EQ_WAV" 2> /dev/null

# 3. 連続再生して聴き比べ
echo "========================================"
echo "◆ 1番目：【オリジナル】（制限あり 8000Hz）"
echo "========================================"
aplay -r 8000 -f S16_LE -c 1 "$ORIGINAL_WAV"

sleep 1

echo "========================================"
echo "◆ 2番目：【最終改善版】（音量引き上げ・44.1kHz）"
echo "========================================"
aplay -r 44100 -f S16_LE -c 1 "$EQ_WAV"

# 4. 後片付け
rm -f "$ORIGINAL_WAV" "$EQ_WAV"

exit 0
