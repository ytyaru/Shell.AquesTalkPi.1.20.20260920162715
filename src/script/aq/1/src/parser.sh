#!/bin/bash

parse_arguments() {
  # ヘルプ表示の即時判定
  if [[ "$*" == *"-h"* || "$*" == *"--help"* ]]; then
    cat "$TXT_DIR/help.txt"
    "$AQTKPI" -h
    exit 0
  fi

  MODE="play"
  if [ "$1" == "silent" ] || [ "$1" == "stdout" ]; then
    MODE="$1"
    shift
  fi

  # デフォルトのラウドネスパラメータ定義
  LOUD_I="-14"
  LOUD_TP="-1.5"
  LOUD_LRA="7"
  USE_LOUDNORM=1

  AQTKPI_ARGS=()
  RAW_OUT_PATH=""

  # --log の先行検知
  for arg in "$@"; do
    if [ "$arg" == "--log" ]; then
      ENABLE_LOG=1
    fi
  done

  # 引数の厳密なパースループ
  while [ $# -gt 0 ]; do
    if [ "$1" == "--log" ]; then
      shift
    elif [ "$1" == "-o" ]; then
      RAW_OUT_PATH="$2"
      shift 2
    elif [ "$1" == "-l" ]; then
      LOUD_ARG="$2"
      shift 2
      
      if [ "$LOUD_ARG" == "off" ]; then
        USE_LOUDNORM=0
      else
        # コロン区切りをパースして個別上書き・デフォルト補完
        IFS=':' read -r p_i p_tp p_lra <<< "$LOUD_ARG"
        [ -n "$p_i" ] && LOUD_I="$p_i"
        
        if [ -n "$p_tp" ]; then
          LOUD_TP=${p_tp#TP=} # "TP=" の文字を除去
        fi
        if [ -n "$p_lra" ]; then
          LOUD_LRA=${p_lra#LRA=} # "LRA=" の文字を除去
        fi
      fi
    else
      AQTKPI_ARGS+=("$1")
      shift
    fi
  done

  # 声種の判別（AquesTalkPiへの引数から厳密に確認）
  LOWPASS_FREQ="3500"
  EQ_PARAM="equalizer 2000 0.5h 5"
  for arg in "${AQTKPI_ARGS[@]}"; do
    if [ "$arg" == "f2" ]; then
      LOWPASS_FREQ="3200"
      EQ_PARAM="equalizer 1700 0.5h 3"
      break
    fi
  done

  # 1対1 並列パスの解析とファイル名ドット重複の修正
  OUT_FILES=()
  if [ -n "$RAW_OUT_PATH" ]; then
    if [[ "$RAW_OUT_PATH" == *"{"* ]]; then
      dirs_str=$(echo "$RAW_OUT_PATH" | sed -E 's/.*\{([^}]+)\}.*/\1/')
      exts_str=$(echo "$RAW_OUT_PATH" | sed -E 's/.*\}.*\{([^}]+)\}.*/\1/')

      IFS=',' read -r -a dirs_arr <<< "$dirs_str"
      IFS=',' read -r -a exts_arr <<< "$exts_str"

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

