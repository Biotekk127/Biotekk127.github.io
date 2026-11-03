#!/usr/bin/env bash
# Turn a storefront video into a scroll-scrubbed image sequence.
# Usage: bash scripts/extract-frames.sh path/to/video.mp4 [frames=160]
# Writes public/frames/{d,m}/0001.webp … and public/frames/manifest.json.
# The site switches to the cinematic scroll hero automatically on the next build.
set -euo pipefail

VIDEO="${1:?usage: extract-frames.sh video.mp4 [frames]}"
FRAMES="${2:-160}"
OUT="public/frames"

DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VIDEO")
FPS=$(python3 -c "print(round($FRAMES / $DUR, 4))")

rm -rf "$OUT" && mkdir -p "$OUT/d" "$OUT/m"
ffmpeg -loglevel error -i "$VIDEO" -vf "fps=$FPS,scale=1920:-2" -frames:v "$FRAMES" -c:v libwebp -quality 62 "$OUT/d/%04d.webp"
ffmpeg -loglevel error -i "$VIDEO" -vf "fps=$FPS,scale=900:-2" -frames:v "$FRAMES" -c:v libwebp -quality 58 "$OUT/m/%04d.webp"

COUNT=$(ls "$OUT/d" | wc -l)
read -r W H < <(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$OUT/d/0001.webp" | tr x ' ')
cat > "$OUT/manifest.json" <<EOF
{ "count": $COUNT, "pattern": "/frames/d/%04d.webp", "mobilePattern": "/frames/m/%04d.webp", "width": $W, "height": $H }
EOF
echo "Wrote $COUNT frames ($(du -sh "$OUT" | cut -f1)) to $OUT"
