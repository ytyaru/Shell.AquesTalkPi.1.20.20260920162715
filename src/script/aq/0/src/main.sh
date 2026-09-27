#!/bin/bash
# AquesTalkPiの実行と、全体の制御フローを統括するメインスクリプト


# シンボリックリンクの実体を追いかけて、正しい実パスを取得する
REAL_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(cd "$(dirname "$REAL_PATH")" && pwd)"
# 同一ディレクトリにあるモジュールを読み込み
#SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"
source "$SCRIPT_DIR/parser.sh"
source "$SCRIPT_DIR/filter.sh"

# 引数の解析を実行
parse_arguments "$@"

# モード別の出力分岐制御
case "$MODE" in
  "stdout")
    "$AQTKPI" "${AQTKPI_ARGS[@]}" | apply_sox_filters | stdout_stream
    ;;

  "silent")
    if [ ${#OUT_FILES[@]} -eq 0 ]; then
      echo "エラー: silent モードには -o オプションで出力先を指定してください。" >&2
      exit 1
    fi
    "$AQTKPI" "${AQTKPI_ARGS[@]}" | apply_sox_filters | encode_and_output
    ;;

  "play")
    if [ ${#OUT_FILES[@]} -gt 0 ]; then
      "$AQTKPI" "${AQTKPI_ARGS[@]}" | apply_sox_filters | encode_and_output
      
      FIRST_FILE="${OUT_FILES[0]}"
      if [ "${FIRST_FILE##*.}" == "wav" ]; then
        aplay "$FIRST_FILE"
      else
        ffplay -nodisp -autoexit "$FIRST_FILE" >/dev/null 2>&1
      fi
    else
      # 通常再生時のログ非表示
      if [ $ENABLE_LOG -eq 1 ]; then
        "$AQTKPI" "${AQTKPI_ARGS[@]}" | apply_sox_filters | ffmpeg -y -i - -af "loudnorm=I=-14:TP=-1.5:LRA=7" -ar 44100 -f wav - | aplay
      else
        "$AQTKPI" "${AQTKPI_ARGS[@]}" | apply_sox_filters | ffmpeg -y -i - -af "loudnorm=I=-14:TP=-1.5:LRA=7" -ar 44100 -f wav - 2>/dev/null | aplay
      fi
    fi
    ;;
esac

exit 0

