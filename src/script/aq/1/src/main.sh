#!/bin/bash
# AquesTalkPiの実行と、全体の制御フローを統括するメインスクリプト

# シンボリックリンクの実体を確実に解決
REAL_PATH=$(readlink -f "${BASH_SOURCE}")
SCRIPT_DIR="$(cd "$(dirname "$REAL_PATH")" && pwd)"
TXT_DIR="$(cd "$SCRIPT_DIR/../txt" && pwd)"

source "$SCRIPT_DIR/env.sh"
source "$SCRIPT_DIR/parser.sh"
source "$SCRIPT_DIR/filter.sh"

# 引数解析
parse_arguments "$@"

# 出力制御分岐
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
      
      FIRST_FILE="${OUT_FILES}"
      if [ "${FIRST_FILE##*.}" == "wav" ]; then
        aplay "$FIRST_FILE"
      else
        ffplay -nodisp -autoexit "$FIRST_FILE" >/dev/null 2>&1
      fi
    else
      "$AQTKPI" "${AQTKPI_ARGS[@]}" | apply_sox_filters | play_stream
    fi
    ;;
esac

exit 0
