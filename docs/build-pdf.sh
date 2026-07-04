#!/bin/bash
# Regenerate PDF copies of the docs from the Markdown sources.
# Needs: pandoc (any 3.x) and Google Chrome. Math renders via MathML (native in Chrome).
set -e
cd "$(dirname "$0")"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

for f in TECHNICAL USER_GUIDE; do
  [ "$f" = TECHNICAL ] && title="ChoiceForge — Technical Documentation" || title="ChoiceForge — User Guide"
  pandoc "$f.md" -f gfm+tex_math_dollars --mathml --embed-resources --standalone \
    -c pdf.css --metadata pagetitle="$title" -o "$f.html"
  "$CHROME" --headless=new --disable-gpu --no-pdf-header-footer \
    --run-all-compositor-stages-before-draw --virtual-time-budget=15000 \
    --print-to-pdf="$f.pdf" "file://$PWD/$f.html"
  rm -f "$f.html"
  echo "built $f.pdf"
done
