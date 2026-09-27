#!/bin/bash

AQTKPI="/home/pi/root/sys/env/tool/aquestalkpi/1.20/AquesTalkPi"

# 1. 動作モードの初期化（silent, stdout, play）
MODE="play"
if [ "$1" == "silent" ] || [ "$1" == "stdout" ]; then
  MODE="$1"
  shift
fi

# 2. 声種の事前判定（引数全体から -v f2 を厳密にチェック）
LOWPASS_FREQ="3500"
EQ_PARAM="equalizer 2000 0.5h 5"

for arg in "$@"; do
  if [ "$arg" == "f2" ]; then
    LOWPASS_FREQ="3200"
    EQ_PARAM="equalizer 1700 0.5h 3"
    break
  fi
done

# 3. 引数の分離パース
AQTKPI_ARGS=()
RAW_OUT_PATH=""

while [ $# -gt 0 ]; do
  if [ "$1" == "-o" ]; then
    RAW_OUT_PATH="$2"
    shift 2
  else
    AQTKPI_ARGS+=("$1")
    shift
  fi
done

# 【1対1 並列パース・インテリジェントロジック】
# シングルクォーテーションで囲まれたブレース表現から、対応するインデックス同士のパスを1対1で組み立てる
OUT_FILES=()
if [ -n "$RAW_OUT_PATH" ]; then
  if [[ "$RAW_OUT_PATH" == *"{"* ]]; then
    # 1つ目のブレース（ディレクトリ）と、2つ目のブレース（拡張子）の「中身のカンマ区切り文字列」を確実に抽出
    dirs_str=$(echo "$RAW_OUT_PATH" | sed -E 's/.*\{([^}]+)\}.*/\1/')
    exts_str=$(echo "$RAW_OUT_PATH" | sed -E 's/.*\}.*\{([^}]+)\}.*/\1/')

    # カンマで分割して配列に格納
    IFS=',' read -r -a dirs_arr <<< "$dirs_str"
    IFS=',' read -r -a exts_arr <<< "$exts_str"

    # ファイル名（my や 0 など）の固定部分を抽出（例: /my. の部分）
    # ディレクトリブレースの直後から、拡張子ブレースの直前までの文字を切り出す
    base_name=$(echo "$RAW_OUT_PATH" | sed -E 's/.*\}\/([^\{]+)\{.*/\1/')

    # 1対1でペアを組み、正しい最終パスを配列に登録
    for i in "${!dirs_arr[@]}"; do
      d="${dirs_arr[$i]}"
      e="${exts_arr[$i]}"
      OUT_FILES+=("./${d}/${base_name}.${e}")
    done
  else
    # 通常の単一ファイル指定の場合
    OUT_FILES+=("$RAW_OUT_PATH")
  fi
fi

# 4. 音質改善共通パイプライン
apply_filters() {
  sox -t wav - -t wav -r 44100 - gain -3 rate -v 44100 lowpass $LOWPASS_FREQ $EQ_PARAM
}

# 5. FFmpegによるマルチフォーマット同時エンコード一括出力関数
# 拡張子を誤認識せず、各ファイルに正しいコーデック（libmp3lame, aac, flac等）を適用します
encode_and_output() {
  local ffmpeg_cmd="ffmpeg -y -i - -af 'loudnorm=I=-14:TP=-1.5:LRA=7' -ar 44100"
  
  for file in "${OUT_FILES[@]}"; do
    # ディレクトリを自動作成
    mkdir -p "$(dirname "$file")"
    
    # 拡張子（末尾の文字）を正しく判定して、FFmpegのエンコード引数を正確に結合
    case "${file##*.}" in
      mp3)  ffmpeg_cmd="$ffmpeg_cmd -c:a libmp3lame -q:a 2 '$file'" ;;
      ogg)  ffmpeg_cmd="$ffmpeg_cmd -c:a libvorbis -q:a 4 '$file'" ;;
      aac)  ffmpeg_cmd="$ffmpeg_cmd -c:a aac -b:a 128k '$file'" ;;
      flac) ffmpeg_cmd="$ffmpeg_cmd -c:a flac '$file'" ;;
      wav)  ffmpeg_cmd="$ffmpeg_cmd -c:a pcm_s16le -f wav '$file'" ;;
      *)    ffmpeg_cmd="$ffmpeg_cmd -f wav '$file'" ;;
    esac
  done
  
  # 構築された正しいマルチ出力コマンドを評価実行
  eval "$ffmpeg_cmd"
}

# 6. モード別の出力分岐制御
case "$MODE" in
  "stdout")
    "$AQTKPI" "${AQTKPI_ARGS[@]}" | apply_filters | ffmpeg -y -i - -af "loudnorm=I=-14:TP=-1.5:LRA=7" -ar 44100 -f wav -
    ;;

  "silent")
    if [ ${#OUT_FILES[@]} -eq 0 ]; then
      echo "エラー: silent モードには -o オプションで出力先を指定してください。" >&2
      exit 1
    fi
    "$AQTKPI" "${AQTKPI_ARGS[@]}" | apply_filters | encode_and_output
    ;;

  "play")
    if [ ${#OUT_FILES[@]} -gt 0 ]; then
      "$AQTKPI" "${AQTKPI_ARGS[@]}" | apply_filters | encode_and_output
      
      # 複数出力時は、最初の1本目を音声確認用に再生
      FIRST_FILE="${OUT_FILES[0]}"
      if [ "${FIRST_FILE##*.}" == "wav" ]; then
        aplay "$FIRST_FILE"
      else
        ffplay -nodisp -autoexit "$FIRST_FILE"
      fi
    else
      "$AQTKPI" "${AQTKPI_ARGS[@]}" | apply_filters | ffmpeg -y -i - -af "loudnorm=I=-14:TP=-1.5:LRA=7" -ar 44100 -f wav - | aplay
    fi
    ;;
esac

exit 0
