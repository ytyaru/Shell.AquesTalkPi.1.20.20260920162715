# ラウドネス正規化。Youtube標準-14.0 TP=-1.0は音割れ防止
ffmpeg -i input.wav -af loudnorm=I=-14:TP=-1.0:LRA=11 normalized.wav
