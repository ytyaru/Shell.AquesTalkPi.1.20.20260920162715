#!/bin/bash

# 読み上げるテキスト
#TEXT="${1:-こんにちは、ラズパイのAquesTalkPiの音質をイコライザで改善するテストです。}"
TEXT="${1:-こんにちは、ラズパイ4Bで使うアクエストークパイの音質をイコライザで改善するテストです。}"
RAW_WAV="aq_raw.wav"
IMP_WAV="aq_improved.wav"

# AquesTalkPiコマンドのパス確認
AQUESTALK_BIN="/home/pi/root/sys/env/tool/aquestalkpi/1.20/AquesTalkPi"
if command -v AquesTalkPi &> /dev/null; then
    AQ_CMD="AquesTalkPi"
elif [ -f "${AQUESTALK_BIN}" ]; then
    AQ_CMD="${AQUESTALK_BIN}"
else
    echo "エラー: AquesTalkPiが見つかりません。パスを確認してください。" >&2
    exit 1
fi

# SoXのインストール確認
if ! command -v sox &> /dev/null; then
    echo "エラー: soxがインストールされています。「sudo apt install sox」を実行してください。" >&2
    exit 1
fi

echo "=== 処理開始 ==="

# 1. 生データ（オリジナル）の生成
echo "[1/2] 生データを出力中: $RAW_WAV"
#$AQ_CMD -v "$TEXT" -w "$RAW_WAV"
$AQ_CMD "$TEXT" > "$RAW_WAV"
#$AQ_CMD -v f2 "$TEXT" > "$RAW_WAV"

# 2. イコライザによる音質改善（こもり解消・明瞭度アップ）
echo "[2/2] イコライザ処理を適用中: $IMP_WAV"
# - 300Hz周辺のコモり（こもり感・ブーミーさ）を -3dB カット
# - 3500Hz周辺の抜け（明瞭度）を +4dB ブースト
# （※カットとブーストを組み合わせて、全体の音量が大きく変わらないように調整しています）
#sox "$RAW_WAV" "$IMP_WAV" equalizer 300 1.5q -3.0 equalizer 3500 2.0q 4.0
# 2. イコライザ＋倍音付加（エキサイター効果）による音質改善
#sox "$RAW_WAV" "$IMP_WAV" \
#    highpass 150 \
#    equalizer 400 2.0q -4.0 \
#    overdrive 5 20 \
#    treble 3
# - 700Hz付近の「こもり・箱鳴り感」を -5dB しっかり削る
# - highpassで低域のモタつきをカット
# - 音量が大きく変わらない（またはクリップしない）ように調整
#sox "$RAW_WAV" "$IMP_WAV" highpass 180 equalizer 700 1.5q -5.0

#sox "$RAW_WAV" "$IMP_WAV" \
#    highpass 180 \
#    equalizer 700 1.5q -4.5 \
#    equalizer 2800 2.0q 1.5 \
#    gain 2.5

# こもりだけを改善
sox "$RAW_WAV" "$IMP_WAV" highpass 180 equalizer 700 1.5q -5.0 #gain +1.0
# こもりと聞き取りやすさを改善
sox -v 0.8 "$RAW_WAV" "aq_improved-2.wav" rate 44100 highpass 150 equalizer 400 1.0q -4 equalizer 1500 1.2q +3
#sox -v 0.8 "$RAW_WAV" "aq_improved-2.wav" rate 44100 highpass 100 equalizer 400 1.5q -3 equalizer 1200 1.2q +2 lowpass 3500
#sox "$RAW_WAV" "aq_improved-3.wav" -t wav - -t wav -r 44100 - gain -3 rate -v 44100 lowpass 3600 equalizer 2000 1.0q 5 norm -1 > "$EQ_WAV";

# 3. 【YouTube基準(-14LUFS) ＆ 耳に刺さらない滑らかイコライザ】
# ・gain -3 で音割れマージンを確保
# ・lowpass 3500 で耳障りな超高域ノイズのカットを少し強める
# ・equalizer 2000 0.5h 5 で、2000Hzを中心に広く滑らかに持ち上げて刺さりを防止
# ・FFmpeg側を I=-14（YouTube基準）、LRA=7（短い音声向けにレンジを狭めて音量安定）に変更
cat "$RAW_WAV" | sox -t wav - -t wav -r 44100 - gain -3 rate -v 44100 lowpass 3500 equalizer 2000 0.5h 5 | \
  ffmpeg -y -i - -af "loudnorm=I=-14:TP=-1.5:LRA=7" -ar 44100 "aq_improved-4.wav" 2> /dev/null
# -14: LUFS。Youtubeはこれより大きいと自動で音量を下げる。
# TP=-1.5: 0にすると音割れする可能性大なので-1.0〜-1.5に下げる
# LRA=11: テレビ番組や映画などで使われる、抑揚（強弱）を適度に残す標準的な値



echo "=== 完了しました ==="
echo "  - 生データ   : $RAW_WAV"
echo "  - 改善データ : $IMP_WAV"
