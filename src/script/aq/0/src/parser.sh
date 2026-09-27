#!/bin/bash
# 引数の解析、声種自動判別、1対1パスの並列展開を担当するモジュール

parse_arguments() {
  MODE="play"
  if [ "$1" == "silent" ] || [ "$1" == "stdout" ]; then
    MODE="$1"
    shift
  fi

  # --log フラグの検知
  AQTKPI_ARGS=()
  RAW_OUT_PATH=""
  
  for arg in "$@"; do
    if [ "$arg" == "--log" ]; then
      ENABLE_LOG=1
    fi
  done

  # 引数の分離パース
  while [ $# -gt 0 ]; do
    if [ "$1" == "--log" ]; then
      shift
    elif [ "$1" == "-o" ]; then
      RAW_OUT_PATH="$2"
      shift 2
    else
      AQTKPI_ARGS+=("$1")
      shift
    fi
  done

  # 声種の判別
  LOWPASS_FREQ="3500"
  EQ_PARAM="equalizer 2000 0.5h 5"
  for arg in "${AQTKPI_ARGS[@]}"; do
    if [ "$arg" == "f2" ]; then
      LOWPASS_FREQ="3200"
      EQ_PARAM="equalizer 1700 0.5h 3"
      break
    fi
  done

  # 1対1（並列展開）のパース処理とドット重複バグの修正
  OUT_FILES=()
  if [ -n "$RAW_OUT_PATH" ]; then
    if [[ "$RAW_OUT_PATH" == *"{"* ]]; then
      dirs_str=$(echo "$RAW_OUT_PATH" | sed -E 's/.*\{([^}]+)\}.*/\1/')
      exts_str=$(echo "$RAW_OUT_PATH" | sed -E 's/.*\}.*\{([^}]+)\}.*/\1/')

      IFS=',' read -r -a dirs_arr <<< "$dirs_str"
      IFS=',' read -r -a exts_arr <<< "$exts_str"

      # ファイル名の固定部分を抽出（末尾のドットをsedできれいに除去して重複を防ぐ）
      base_name=$(echo "$RAW_OUT_PATH" | sed -E 's/.*\}\/([^\{]+)\{.*/\1/' | sed 's/\.$//')

      for i in "${!dirs_arr[@]}"; do
        d="${dirs_arr[$i]}"
        e="${exts_arr[$i]}"
        OUT_FILES+=("./${d}/${base_name}.${e}")
      done
    else
      OUT_FILES+=("$RAW_OUT_PATH")
    fi
  fi
}

