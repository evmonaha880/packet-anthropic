#!/bin/bash
# Regenerate files/resume.pdf from resume.html.
# The print rules live in the @media print block of style.css; the résumé is
# tuned to land on exactly one page. Re-run this after any résumé edit.
#
# Added 2026-08-26: the served PDF had drifted from the HTML since 2026-07-21,
# still carrying "Shira Goodman" and "November 2025" after both were fixed in
# the HTML on 8/25. Deriving the PDF from the page is the fix.
set -euo pipefail
cd "$(dirname "$0")"

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="files/resume.pdf" "file://$PWD/resume.html" >/dev/null 2>&1

PAGES=$(~/DataLake/.venv/bin/python -c "import fitz;print(fitz.open('files/resume.pdf').page_count)")
echo "files/resume.pdf regenerated: ${PAGES} page(s)"
[ "$PAGES" = "1" ] || { echo "FAIL: résumé must be one page"; exit 1; }

# Lock guard: these strings must never reach the served PDF.
~/DataLake/.venv/bin/python - <<'PY'
import fitz, sys
t = "".join(p.get_text() for p in fitz.open("files/resume.pdf"))
banned = ["Shira Goodman", "November 2025", "Nov 2025", "run by HUD", "hackathon run by"]
hits = [b for b in banned if b in t]
required = ["Oct 2025", "Y Combinator"]
missing = [r for r in required if r not in t]
if hits or missing:
    if hits:    print("FAIL: banned string(s) in PDF:", hits)
    if missing: print("FAIL: required string(s) missing from PDF:", missing)
    sys.exit(1)
print("lock guard: PASS")
PY
