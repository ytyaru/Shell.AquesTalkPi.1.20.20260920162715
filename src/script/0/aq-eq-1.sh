#!/bin/bash

# 1. 各種設定
AQTKPI="/home/pi/root/sys/env/tool/aquestalkpi/1.20/AquesTalkPi"
TEXT="アクエストークパイのラウドネス正規化テストです。サシスセソ、ツクシ。本日は晴天なり。"

# 一時ファイルの保存先
ORIGINAL_WAV="/tmp/aq_original.wav"
EQ_WAV="/tmp/aq_loudnorm.wav"

# 2. 音声ファイルの生成（8000Hzオリジナル）
"$AQTKPI" "$TEXT" > "$ORIGINAL_WAV"

# 3. 【YouTube基準(-14LUFS) ＆ 耳に刺さらない滑らかイコライザ】
# ・gain -3 で音割れマージンを確保
# ・lowpass 3500 で耳障りな超高域ノイズのカットを少し強める
# ・equalizer 2000 0.5h 5 で、2000Hzを中心に広く滑らかに持ち上げて刺さりを防止
# ・FFmpeg側を I=-14（YouTube基準）、LRA=7（短い音声向けにレンジを狭めて音量安定）に変更
"$AQTKPI" "$TEXT" | \
  sox -t wav - -t wav -r 44100 - gain -3 rate -v 44100 lowpass 3500 equalizer 2000 0.5h 5 | \
  ffmpeg -y -i - -af "loudnorm=I=-14:TP=-1.5:LRA=7" -ar 44100 "$EQ_WAV" 2> /dev/null
# -14: LUFS。Youtubeはこれより大きいと自動で音量を下げる。
# TP=-1.5: 0にすると音割れする可能性大なので-1.0〜-1.5に下げる
# LRA=11: テレビ番組や映画などで使われる、抑揚（強弱）を適度に残す標準的な値

# 4. 連続再生して聴き比べ
echo "========================================"
echo "◆ 1番目：【オリジナル】（制限あり 8000Hz）"
echo "========================================"
aplay -r 8000 -f S16_LE -c 1 "$ORIGINAL_WAV"

sleep 1

echo "========================================"
echo "◆ 2番目：【YouTube基準＆耳に刺さらない最終版】（44.1kHz）"
echo "========================================"
aplay -r 44100 -f S16_LE -c 1 "$EQ_WAV"

# 5. 後片付け
rm -f "$ORIGINAL_WAV" "$EQ_WAV"

exit 0
