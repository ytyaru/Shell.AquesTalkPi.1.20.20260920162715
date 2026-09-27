#!/bin/bash

# --- 設定 ---
# 読み上げさせたいテキスト
TEXT="こんにちは。ラズパイのAquesTalkPiの音質をイコライザで改善します。"

# 出力ファイル名
RAW_FILE="raw_output.wav"
IMP_FILE="improved_output.wav"

# AquesTalkPiの実行ファイル名（パスが異なる場合は適宜変更してください）
# ※AquesTalkPiは標準出力にWAVデータを出力するため、リダイレクトで保存します
#AQUESTALK_BIN="./AquesTalkPi"
AQUESTALK_BIN="/home/pi/root/sys/env/tool/aquestalkpi/1.20/AquesTalkPi"

# 1. チェック
if [ ! -f "$AQUESTALK_BIN" ]; then
    echo "エラー: AquesTalkPiの実行ファイルが見つかりません ($AQUESTALK_BIN)"
    exit 1
fi

# 2. 生データ（未加工）の出力
echo "1/2: 生データ（こもった状態）を出力中..."
"$AQUESTALK_BIN" "$TEXT" > "$RAW_FILE"

# 3. SoXによるイコライザ・音質改善処理
#   - treble +8     : 高音域を+8dBブーストして抜けを良くする
#   - equalizer ... : こもり感の原因になる中音域（約2500Hz付近）を少し削る
#   - gain -h       : 音割れ（クリッピング）を防ぐ自動ゲイン調整
echo "2/2: SoXでイコライザ処理を適用中..."
sox "$RAW_FILE" "$IMP_FILE" treble +8 equalizer 2500 1.5q -3 gain -h

echo "-----------------------------------"
echo "処理が完了しました！"
echo "  - 生データ:   $RAW_FILE"
echo "  - 改善データ: $IMP_FILE"
echo "-----------------------------------"
echo "【聞き比べ用コマンド】"
echo "  生データ再生:   aplay $RAW_FILE"
echo "  改善データ再生: aplay $IMP_FILE"
