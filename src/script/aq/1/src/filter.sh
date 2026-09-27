#!/bin/bash
# SoXによる音質改善、FFmpegによるラウドネス統一と各形式変換を担当するモジュール

apply_sox_filters() {
  sox -t wav - -t wav -r 44100 - gain -3 rate -v 44100 lowpass $LOWPASS_FREQ $EQ_PARAM
}

# 動的にラウドネス用オーディオフィルターの文字列を組み立てる関数
build_af_param() {
  if [ $USE_LOUDNORM -eq 1 ]; then
    echo "loudnorm=I=${LOUD_I}:TP=${LOUD_TP}:LRA=${LOUD_LRA}"
  else
    echo "anull" # ラウドネスOFFの時は、何もしないヌルフィルターを適用
  fi
}

encode_and_output() {
  local af_string=$(build_af_param)
  local ffmpeg_cmd="ffmpeg -y -i - -af '$af_string' -ar 44100"
  
  for file in "${OUT_FILES[@]}"; do
    mkdir -p "$(dirname "$file")"
    case "${file##*.}" in
      mp3)  ffmpeg_cmd="$ffmpeg_cmd -c:a libmp3lame -q:a 2 '$file'" ;;
      ogg)  ffmpeg_cmd="$ffmpeg_cmd -c:a libvorbis -q:a 4 '$file'" ;;
      aac)  ffmpeg_cmd="$ffmpeg_cmd -c:a aac -b:a 128k '$file'" ;;
      flac) ffmpeg_cmd="$ffmpeg_cmd -c:a flac '$file'" ;;
      wav)  ffmpeg_cmd="$ffmpeg_cmd -c:a pcm_s16le -f wav '$file'" ;;
      *)    ffmpeg_cmd="$ffmpeg_cmd -f wav '$file'" ;;
    esac
  done

  if [ $ENABLE_LOG -eq 1 ]; then
    eval "$ffmpeg_cmd"
  else
    eval "$ffmpeg_cmd" >/dev/null 2>&1
  fi
}

stdout_stream() {
  local af_string=$(build_af_param)
  if [ $ENABLE_LOG -eq 1 ]; then
    ffmpeg -y -i - -af "$af_string" -ar 44100 -f wav -
  else
    ffmpeg -y -i - -af "$af_string" -ar 44100 -f wav - 2>/dev/null
  fi
}

play_stream() {
  local af_string=$(build_af_param)
  if [ $ENABLE_LOG -eq 1 ]; then
    ffmpeg -y -i - -af "$af_string" -ar 44100 -f wav - | aplay
  else
    ffmpeg -y -i - -af "$af_string" -ar 44100 -f wav - 2>/dev/null | aplay
  fi
}
