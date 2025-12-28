#!/bin/bash
#
# crumple-pdf.sh
#
# Make a PDF look like it was scanned on a medium-quality scanner by:
#   1) rasterizing it (Ghostscript)
#   2) adding mild rotation/noise/shading (ImageMagick)
#   3) reassembling to a JPEG-compressed PDF (ImageMagick)
#
# Dependencies (Homebrew):
#   brew install ghostscript imagemagick qpdf

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  crumple-pdf.sh [options] INPUT.pdf

Options:
  -o, --output PATH       Output PDF path (default: INPUT.scanned.pdf)
  -r, --dpi N             Rasterization DPI (default: 200)
  -q, --quality N         JPEG quality 1-100 (default: 60)
  --color                 Keep color (default: grayscale)
  --seed N                Seed for randomization (default: based on time)
  --no-linearize          Don't run qpdf --linearize on output
  -h, --help              Show this help

Examples:
  crumple-pdf.sh input.pdf
  crumple-pdf.sh -r 180 -q 55 -o out.pdf input.pdf
  crumple-pdf.sh --color --seed 1234 input.pdf
EOF
}

err() {
  echo "crumple-pdf.sh: $*" >&2
}

die() {
  err "$*"
  exit 1
}

need_cmd() {
  local c="$1"
  command -v "$c" >/dev/null 2>&1 || die "missing dependency: $c"
}

OUTPUT=""
DPI=200
QUALITY=60
COLOR=0
SEED=""
LINEARIZE=1

INPUT=""

while [ $# -gt 0 ]; do
  case "$1" in
    -o|--output)
      [ $# -ge 2 ] || die "--output requires a value"
      OUTPUT="$2"
      shift 2
      ;;
    -r|--dpi)
      [ $# -ge 2 ] || die "--dpi requires a value"
      DPI="$2"
      shift 2
      ;;
    -q|--quality)
      [ $# -ge 2 ] || die "--quality requires a value"
      QUALITY="$2"
      shift 2
      ;;
    --color)
      COLOR=1
      shift
      ;;
    --seed)
      [ $# -ge 2 ] || die "--seed requires a value"
      SEED="$2"
      shift 2
      ;;
    --no-linearize)
      LINEARIZE=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      INPUT="$1"
      shift
      ;;
  esac
done

[ -n "$INPUT" ] || { usage; exit 2; }
[ -f "$INPUT" ] || die "input not found: $INPUT"

if [ -z "$OUTPUT" ]; then
  base="${INPUT%.*}"
  OUTPUT="${base}.scanned.pdf"
fi

# Basic validation
case "$DPI" in
  ''|*[!0-9]*) die "dpi must be an integer";;
  *) :;;
esac
case "$QUALITY" in
  ''|*[!0-9]*) die "quality must be an integer 1-100";;
  *) :;;
esac
[ "$QUALITY" -ge 1 ] && [ "$QUALITY" -le 100 ] || die "quality must be 1-100"

need_cmd gs
need_cmd magick

if [ -z "$SEED" ]; then
  # Seconds since epoch is fine here; only used for mild randomization.
  SEED="$(date +%s)"
fi

TMPDIR="$(mktemp -d -t crumple-pdf.XXXXXX)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

# Rasterize
GS_DEVICE="pnggray"
if [ "$COLOR" -eq 1 ]; then
  GS_DEVICE="png16m"
fi

# gs output pattern uses %d, not printf-style.
# Use CropBox to avoid scanning extra bleed if present.
err "Rasterizing at ${DPI} dpi (${GS_DEVICE})..."

gs \
  -dSAFER -dBATCH -dNOPAUSE -dNOOUTERSAVE \
  -dUseCropBox \
  -dTextAlphaBits=2 -dGraphicsAlphaBits=2 \
  -sDEVICE="${GS_DEVICE}" \
  -r"${DPI}" \
  -o "${TMPDIR}/page-%04d.png" \
  "$INPUT" \
  >/dev/null

shopt -s nullglob
PAGES=("${TMPDIR}"/page-*.png)
[ ${#PAGES[@]} -gt 0 ] || die "no pages rendered (is the PDF empty or protected?)"

# Helper: deterministic-ish random float in [-range, +range]
rand_sym() {
  local range="$1"
  # $RANDOM is 0..32767
  awk -v r="$RANDOM" -v range="$range" -v seed="$SEED" 'BEGIN{ srand(seed + r); printf "%.4f", (rand()*2.0-1.0)*range }'
}

err "Adding scanner artifacts to ${#PAGES[@]} page(s)..."

idx=0
for src in "${PAGES[@]}"; do
  idx=$((idx+1))

  # Mild skew/rotation
  rot="$(rand_sym 0.7)"  # degrees

  # A near-white shading layer (uneven illumination).
  # Make it mostly white so Multiply only slightly darkens.
  # Size matched to the source page.
  dim="$(magick identify -format '%wx%h' "$src")"

  dst="${TMPDIR}/out-$(printf '%04d' "$idx").jpg"

  if [ "$COLOR" -eq 1 ]; then
    magick "$src" \
      -alpha off \
      \( -size "$dim" xc:white +noise Gaussian -blur 0x60 -level 88%,100% \) \
      -compose Multiply -composite \
      -resize 98% -resize 102.040816% \
      -blur 0x0.6 \
      -attenuate 0.30 +noise Gaussian \
      -attenuate 0.03 +noise Impulse \
      -brightness-contrast 4x12 \
      -rotate "$rot" -background white -alpha remove -alpha off \
      -quality "$QUALITY" \
      "$dst"
  else
    magick "$src" \
      -colorspace Gray -type Grayscale -alpha off \
      \( -size "$dim" xc:white +noise Gaussian -blur 0x60 -level 88%,100% \) \
      -compose Multiply -composite \
      -resize 98% -resize 102.040816% \
      -blur 0x0.6 \
      -attenuate 0.35 +noise Gaussian \
      -attenuate 0.04 +noise Impulse \
      -brightness-contrast 6x18 \
      -rotate "$rot" -background white -alpha remove -alpha off \
      -quality "$QUALITY" \
      "$dst"
  fi

done

# Assemble back into a PDF.
# Set density so page size is correct (pixels / DPI).
err "Writing PDF..."

OUT_TMP_PDF="${TMPDIR}/scanned.pdf"
magick "${TMPDIR}"/out-*.jpg \
  -units PixelsPerInch -density "${DPI}" \
  -compress JPEG -quality "${QUALITY}" \
  "$OUT_TMP_PDF"

if [ "$LINEARIZE" -eq 1 ] && command -v qpdf >/dev/null 2>&1; then
  err "Linearizing with qpdf..."
  qpdf --linearize "$OUT_TMP_PDF" "${TMPDIR}/linearized.pdf" 2>/dev/null || cp "$OUT_TMP_PDF" "${TMPDIR}/linearized.pdf"
  mv -f "${TMPDIR}/linearized.pdf" "$OUTPUT"
else
  mv -f "$OUT_TMP_PDF" "$OUTPUT"
fi

err "Wrote: $OUTPUT"
