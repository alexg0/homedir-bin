#! /bin/bash

# Convert markdown to PDF via pandoc + xelatex
#
# Dependencies (macOS):
#   brew install pandoc
#   brew install --cask basictex && eval "$(/usr/libexec/path_helper)"

set -euo pipefail

usage() {
  echo "Usage: $0 [options] input.md [output.pdf]"
  echo
  echo "Options:"
  echo "  -t TITLE    PDF title (default: first # H1 from file, or filename)"
  echo "  -a AUTHOR   Author line (default: none)"
  echo "  -m MARGIN   Page margin (default: 1in)"
  echo "  -s SIZE     Font size (default: 11pt)"
  echo "  --no-toc    Omit table of contents"
  echo "  -h          Show this help"
  exit "${1:-0}"
}

title=""
author=""
margin="1in"
fontsize="11pt"
toc="--toc"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t) title="$2"; shift 2 ;;
    -a) author="$2"; shift 2 ;;
    -m) margin="$2"; shift 2 ;;
    -s) fontsize="$2"; shift 2 ;;
    --no-toc) toc=""; shift ;;
    -h|--help) usage 0 ;;
    -*) echo "Unknown option: $1" >&2; usage 1 ;;
    *) break ;;
  esac
done

input_file="${1:-}"
if [[ -z "$input_file" ]]; then
  usage 1
fi
shift

if [[ ! -f "$input_file" ]]; then
  echo "File not found: $input_file" >&2
  exit 1
fi

if [[ $# -gt 0 ]]; then
  output_file="$1"
else
  output_file="$(dirname "$input_file")/$(basename "$input_file" .md).pdf"
fi

# Auto-extract title from first H1 if not provided
if [[ -z "$title" ]]; then
  title=$(grep -m1 '^# ' "$input_file" | sed 's/^# //' || true)
  if [[ -z "$title" ]]; then
    title=$(basename "$input_file" .md)
  fi
fi

# Build pandoc title block as a temp file
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

tmp_md="$tmpdir/combined.md"
{
  echo "% $title"
  [[ -n "$author" ]] && echo "% $author" || echo "%"
  echo "% $(date -r "$input_file" '+%B %d, %Y')"
  echo
  cat "$input_file"
} > "$tmp_md"

# Keep compatibility replacements narrow: preserve Unicode text via mainfont,
# but normalize symbols that still tend to warn in the PDF pipeline.
python3 - "$tmp_md" <<'PY2'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text()
text = text.replace("✅", "[OK]")
text = text.replace("⚠️", "[!]")
text = text.replace("✓", "[x]")
text = text.replace("≥", ">=")
text = text.replace("→", "->")
p.write_text(text)
PY2

resource_path="$(dirname "$input_file"):."

pandoc "$tmp_md" \
  ${toc:+"$toc"} \
  --number-sections \
  --resource-path="$resource_path" \
  --pdf-engine=xelatex \
  -V "geometry:margin=$margin" \
  -V "fontsize:$fontsize" \
  -V "mainfont:STIX Two Text" \
  -V linkcolor:blue \
  -V urlcolor:blue \
  -o "$output_file"

echo "$output_file"
