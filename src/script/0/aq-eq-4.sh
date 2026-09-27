#!/bin/bash

# 1. 各種設定
AQTKPI="/home/pi/root/sys/env/tool/aquestalkpi/1.20/AquesTalkPi"

# 使い方のアナウンス（引数がない場合）
if [ -z "$1" ]; then
  echo "【使い方】: $0 [オプション] \"喋らせたいセリフ\""
  echo "  例1 (f1・デフォルト高音): $0 \"こんにちは。\""
  echo "  例2 (f2・少し低い声に指定): $0 -v f2 \"こんにちは。\""
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

# 【f1 / f2 限定・自動微調整ロジック】
if [[ "$OPTIONS" == *"f2"* ]]; then
  # ◆ 少し低い女性声（f2）用のノイズ・歯擦音対策設定
  # ザラザラ感を消すために lowpass を 3200Hz まで下げてノイズを遮断します。
  # また、1700Hzのイコライザを +3dB に控えめにして、トゲが立つ音割れを防ぎます。
  LOWPASS_FREQ="3200"
  EQ_PARAM="equalizer 1700 0.5h 3"
else
  # ◆ 高い女性声（f1・デフォルト）の最適化設定
  # 鉄板の「いい感じ」だった設定です。
  LOWPASS_FREQ="3500"
  EQ_PARAM="equalizer 2000 0.5h 5"
fi

# 一時ファイルの保存先
ORIGINAL_WAV="/tmp/aq_original.wav"
EQ_WAV="/tmp/aq_loudnorm.wav"

# 2. 音声ファイルの生成
# オリジナルの生データ（8000Hz）を作成
"$AQTKPI" $OPTIONS "$TEXT" > "$ORIGINAL_WAV"

# 声質ごとに最適化された LOWPASS_FREQ と EQ_PARAM を適用
"$AQTKPI" $OPTIONS "$TEXT" | \
  sox -t wav - -t wav -r 44100 - gain -3 rate -v 44100 lowpass $LOWPASS_FREQ $EQ_PARAM | \
  ffmpeg -y -i - -af "loudnorm=I=-14:TP=-1.5:LRA=7" -ar 44100 "$EQ_WAV" 2> /dev/null

# 3. 連続再生して聴き比べ
echo "========================================"
echo "◆ 1番目：【オリジナル】（制限あり 8000Hz）"
echo "========================================"
aplay -r 8000 -f S16_LE -c 1 "$ORIGINAL_WAV"

sleep 1

echo "========================================"
echo "◆ 2番目：【声質自動最適化＋ラウドネス正規化版】（44.1kHz）"
echo "========================================"
aplay -r 44100 -f S16_LE -c 1 "$EQ_WAV"

# 4. 後片付け
rm -f "$ORIGINAL_WAV" "$EQ_WAV"

exit 0


#!/bin/bash

# 1. 各種設定
AQTKPI="/home/pi/root/sys/env/tool/aquestalkpi/1.20/AquesTalkPi"

# 使い方のアナウンス（引数がない場合）
if [ -z "$1" ]; then
  echo "【使い方】: $0 [オプション] \"喋らせたいセリフ\""
  echo "  例1 (f1・デフォルト高音): $0 \"こんにちは。\""
  echo "  例2 (f2・少し低い声に指定): $0 -v f2 \"こんにちは。\""
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

# 【f1 / f2 限定・自動微調整ロジック】
if [[ "$OPTIONS" == *"f2"* ]]; then
  # ◆ 少し低い女性声（f2）用のデジタルノイズ丸め込み設定
  # lowpass を 3000Hz まで少し下げつつ、deemph（ディエンファシス）を追加。
  # デジタル特有のザラザラした歯擦音のトゲだけを滑らかに削り落とします。
  LOWPASS_FREQ="3000"
  EQ_PARAM="deemph equalizer 1700 0.5h 3"
else
  # ◆ 高い女性声（f1・デフォルト）の最適化設定
  # 鉄板の「いい感じ」だった設定を維持します。
  LOWPASS_FREQ="3500"
  EQ_PARAM="equalizer 2000 0.5h 5"
fi

# 一時ファイルの保存先
ORIGINAL_WAV="/tmp/aq_original.wav"
EQ_WAV="/tmp/aq_loudnorm.wav"

# 2. 音声ファイルの生成
# オリジナルの生データ（8000Hz）を作成
"$AQTKPI" $OPTIONS "$TEXT" > "$ORIGINAL_WAV"

# 声質ごとに最適化された設定を適用
"$AQTKPI" $OPTIONS "$TEXT" | \
  sox -t wav - -t wav -r 44100 - gain -3 rate -v 44100 lowpass $LOWPASS_FREQ $EQ_PARAM | \
  ffmpeg -y -i - -af "loudnorm=I=-14:TP=-1.5:LRA=7" -ar 44100 "$EQ_WAV" 2> /dev/null

# 3. 連続再生して聴き比べ
echo "========================================"
echo "◆ 1番目：【オリジナル】（制限あり 8000Hz）"
echo "========================================"
aplay -r 8000 -f S16_LE -c 1 "$ORIGINAL_WAV"

sleep 1

echo "========================================"
echo "◆ 2番目：【声質自動最適化＋ラウドネス正規化版】（44.1kHz）"
echo "========================================"
aplay -r 44100 -f S16_LE -c 1 "$EQ_WAV"

# 4. 後片付け
rm -f "$ORIGINAL_WAV" "$EQ_WAV"

exit 0
