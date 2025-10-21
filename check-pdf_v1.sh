#!/usr/bin/env bash
# -------------------------------------------------------------
# PDF Static Analyzer (Safe / Offline)
# Author: Kraken IO 
# Output: TXT + HTML reports + live terminal output
# -------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

if [ $# -lt 1 ]; then
    echo "Usage: $0 <pdf-file>"
    exit 1
fi

# === File setup ===
PDF="$(realpath "$1")"
PDF_DIR="$(dirname "$PDF")"
BASENAME="$(basename "$PDF")"
SHORTNAME="${BASENAME%.*}"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
REPORT_TXT="${PDF_DIR}/pdfreport_${SHORTNAME}_${TIMESTAMP}.txt"
REPORT_HTML="${PDF_DIR}/pdfreport_${SHORTNAME}_${TIMESTAMP}.html"

# === Dependency check ===
DEPENDENCIES=("exiftool" "pdfid.py" "pdf-parser.py" "pdftotext" "mutool" "strings" "sha256sum" "ls")
MISSING=()

echo "Checking dependencies..."
for dep in "${DEPENDENCIES[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        MISSING+=("$dep")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo "Missing dependencies:"
    for t in "${MISSING[@]}"; do echo "  - $t"; done
    echo ""
    echo "Manual installation commands:"
    echo "  sudo apt update"
    echo "  sudo apt install exiftool mupdf-tools poppler-utils unzip wget python3 -y"
    echo "  cd /usr/local/bin"
    echo "  sudo wget https://didierstevens.com/files/software/pdfid_v0_2_8.zip -O pdfid.zip"
    echo "  sudo unzip -o pdfid.zip && sudo chmod +x pdfid.py"
    echo "  sudo wget https://didierstevens.com/files/software/pdf-parser_V0_7_6.zip -O pdfparser.zip"
    echo "  sudo unzip -o pdfparser.zip && sudo chmod +x pdf-parser.py"
    echo ""
    read -rp "Install missing dependencies automatically? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        sudo apt update -y
        sudo apt install exiftool mupdf-tools poppler-utils unzip wget python3 -y
        cd /usr/local/bin || exit 1
        [[ " ${MISSING[*]} " =~ "pdfid.py" ]] && sudo wget https://didierstevens.com/files/software/pdfid_v0_2_8.zip -O pdfid.zip && sudo unzip -o pdfid.zip >/dev/null && sudo chmod +x pdfid.py
        [[ " ${MISSING[*]} " =~ "pdf-parser.py" ]] && sudo wget https://didierstevens.com/files/software/pdf-parser_V0_7_6.zip -O pdfparser.zip && sudo unzip -o pdfparser.zip >/dev/null && sudo chmod +x pdf-parser.py
    else
        echo "Exiting. Install manually using commands above."
        exit 0
    fi
else
    echo "All dependencies present."
fi
echo ""

# === Initialize Reports ===
echo "=========================================" | tee "$REPORT_TXT"
echo " PDF Static Analysis Report" | tee -a "$REPORT_TXT"
echo " File: $BASENAME" | tee -a "$REPORT_TXT"
echo " Generated: $(date)" | tee -a "$REPORT_TXT"
echo "=========================================" | tee -a "$REPORT_TXT"
echo "" | tee -a "$REPORT_TXT"

cat <<EOF > "$REPORT_HTML"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>PDF Report - ${BASENAME}</title>
<style>
body { font-family: Arial, sans-serif; background: #fafafa; color: #111; margin: 20px; }
h2 { color: #004080; border-bottom: 2px solid #004080; }
pre { background: #f4f4f4; border: 1px solid #ccc; padding: 10px; overflow-x: auto; }
.section { margin-bottom: 25px; }
footer { margin-top: 40px; font-size: 0.85em; color: #555; }
</style>
</head>
<body>
<h1>PDF Static Analysis Report</h1>
<p><b>File:</b> ${BASENAME}<br><b>Generated:</b> $(date)</p>
EOF

# === Helper Functions ===
section() {
    echo ""
    echo "[$1] $2"
    echo "----------------------------------------"
    echo ""
    echo "<div class='section'><h2>$2</h2><pre>" >> "$REPORT_HTML"
}
end_section() { echo "</pre></div>" >> "$REPORT_HTML"; }

# === 1. File Info ===
section 1 "File Info and Hash" | tee -a "$REPORT_TXT"
sha256sum "$PDF" | tee -a "$REPORT_TXT" | tee -a >(cat >> "$REPORT_HTML")
ls -lh "$PDF" | tee -a "$REPORT_TXT" | tee -a >(cat >> "$REPORT_HTML")
end_section

# === 2. Metadata ===
section 2 "Metadata (exiftool)" | tee -a "$REPORT_TXT"
exiftool "$PDF" 2>/dev/null | tee -a "$REPORT_TXT" | tee -a >(cat >> "$REPORT_HTML")
end_section

# === 3. Structure Scan ===
section 3 "Structure Scan (pdfid.py)" | tee -a "$REPORT_TXT"
pdfid.py "$PDF" | tee -a "$REPORT_TXT" | tee -a >(cat >> "$REPORT_HTML")
end_section

# === 4. Visible URLs ===
section 4 "Visible URLs (pdftotext)" | tee -a "$REPORT_TXT"
pdftotext "$PDF" - -enc UTF-8 2>/dev/null \
    | grep -Eo 'https?://[^[:space:])\]\}>"'\''"]+' \
    | sort -u | tee -a "$REPORT_TXT" | tee -a >(cat >> "$REPORT_HTML") || true
end_section

# === 5. Hidden URLs ===
section 5 "Hidden URLs (strings)" | tee -a "$REPORT_TXT"
strings -a "$PDF" | grep -Eo 'https?://[^[:space:]]+' | sort -u \
    | tee -a "$REPORT_TXT" | tee -a >(cat >> "$REPORT_HTML") || true
end_section

# === 6. Embedded Files ===
section 6 "Embedded Files and Images (mutool)" | tee -a "$REPORT_TXT"
mutool extract "$PDF" 2>/dev/null | tee -a "$REPORT_TXT" | tee -a >(cat >> "$REPORT_HTML") || true
echo "Extracted files saved to: $PDF_DIR" | tee -a "$REPORT_TXT" | tee -a >(cat >> "$REPORT_HTML")
end_section

# === 7. JavaScript and URI Objects ===
section 7 "JavaScript and URI Objects (pdf-parser.py)" | tee -a "$REPORT_TXT"
echo "JS Objects:" | tee -a "$REPORT_TXT" | tee -a >(cat >> "$REPORT_HTML")
pdf-parser.py -s "/JS" "$PDF" | tee -a "$REPORT_TXT" | tee -a >(cat >> "$REPORT_HTML") || true
echo "" | tee -a "$REPORT_TXT" | tee -a >(cat >> "$REPORT_HTML")
echo "URI Objects:" | tee -a "$REPORT_TXT" | tee -a >(cat >> "$REPORT_HTML")
pdf-parser.py -s "/URI" "$PDF" | tee -a "$REPORT_TXT" | tee -a >(cat >> "$REPORT_HTML") || true
end_section

# === 8. Suspicious JS Keywords ===
section 8 "Suspicious JavaScript Keywords" | tee -a "$REPORT_TXT"
strings -a "$PDF" | grep -Ei 'eval|unescape|fromCharCode|app\.launchURL|/Launch|app\.exec' | sort -u \
    | tee -a "$REPORT_TXT" | tee -a >(cat >> "$REPORT_HTML") || true
end_section

# === Close HTML ===
cat <<EOF >> "$REPORT_HTML"
<footer>
<p>Analysis complete.<br>Report generated by Kraken IO  - $(date)</p>
</footer>
</body></html>
EOF

echo ""
echo "========================================="
echo " Analysis complete."
echo " TXT Report:   $REPORT_TXT"
echo " HTML Report:  $REPORT_HTML"
echo "========================================="
