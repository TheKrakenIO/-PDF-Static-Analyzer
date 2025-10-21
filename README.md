# PDF Static Analyzer (Safe Offline Tool)

This tool performs a **static and secure analysis of PDF files** without opening or executing them.  
It collects metadata, detects hidden links, extracts embedded files, and identifies potential malicious code such as JavaScript or suspicious keywords.

The analysis is done entirely offline using trusted command-line utilities.  
Results are saved in both a **TXT report** and an **HTML report** for easy review.

---

## Purpose

The goal of this script is to help security researchers and analysts examine PDF documents safely by reading their internal structure and content without triggering any active components.  
It identifies possible signs of malicious behavior while keeping the environment isolated and risk-free.

---

## Features

- Generates a detailed **TXT report** and a well-formatted **HTML report**.  
- Displays live analysis results in the terminal.  
- Automatically checks for required tools.  
- Option to install missing tools automatically or manually.  
- Extracts embedded objects (files, images) from the PDF for inspection.  
- Detects hidden links, metadata, JavaScript, and suspicious keywords.  
- Reports are saved in the same directory as the analyzed PDF.

---

## Dependencies

The following packages are required:

- `exiftool` – reads PDF metadata.  
- `pdfid.py` – scans the file structure for suspicious keywords.  
- `pdf-parser.py` – parses and extracts PDF objects.  
- `pdftotext` – extracts visible text from PDFs.  
- `mutool` – extracts embedded images and attachments.  
- `strings` – finds readable text inside binary sections.  
- `sha256sum`, `ls`, `grep`, `sort`, `tee` – basic command-line utilities.

These packages are available in most Linux distributions and are installed automatically if you approve the prompt when running the script.

---

## How the Script Works

### **Dependency Check**  
The script verifies the presence of all required tools before starting.  
If any are missing, it displays the exact installation commands and asks whether to install them automatically or exit for manual setup.

### **File Preparation**  
The script resolves the full path of the PDF file.  
All reports are written to the same directory as the PDF.

### **Static Analysis Steps**  
- Calculates file hash and size.  
- Reads and records metadata using `exiftool`.  
- Scans structure with `pdfid.py` for tags such as `/JS`, `/URI`, `/Launch`.  
- Extracts visible URLs from text.  
- Searches binary content for hidden URLs.  
- Uses `mutool` to extract embedded files or images.  
- Parses JavaScript and URI objects with `pdf-parser.py`.  
- Searches for suspicious terms such as `eval`, `unescape`, `fromCharCode`, or `app.launchURL`.

### **Report Generation**  
All results are written to a plain text file.  
Simultaneously, a styled HTML report is generated for visual review.  
Both reports include timestamps and section headers for traceability.

### **Safe Execution**  
The script does not open or render the PDF.  
It reads content only, making it safe for forensic and offline environments.

---

## Installation and Usage

### 1. Download

Save the script as `check-pdf.sh`:

```bash
wget -O check-pdf.sh https://your-server-or-storage-path/check-pdf.sh
chmod +x check-pdf.sh
```

*(Replace the URL above with the actual download location you use to host the script.)*

### 2. Run the Analyzer

```bash
./check-pdf.sh "Sample Document.pdf"
```

or, if your filename contains spaces:

```bash
./check-pdf.sh 'Sample Document.pdf'
```

### 3. Output

After analysis you will find:

```
pdfreport_Sample_Document_<timestamp>.txt
pdfreport_Sample_Document_<timestamp>.html
```

Both are saved in the same directory as the original PDF.

The terminal displays live progress while the files are being analyzed.

---

## Troubleshooting

### Permission Denied When Writing Report

- **Cause:** The script was executed in a directory without write permissions.
- **Fix:** Move to a writable folder (for example, your home or Desktop directory) before running:

```bash
cd ~/Desktop
./check-pdf.sh file.pdf
```

### "No such file or directory"

- **Cause:** The filename was quoted and escaped at the same time.
- **Fix:** Use either single quotes or backslashes, not both:

```bash
./check-pdf.sh 'file with spaces.pdf'
```

or

```bash
./check-pdf.sh file\ with\ spaces.pdf
```

### "pdf-parser.py not installed" or "pdfid.py not installed"

- **Fix:** Run the script again and select automatic installation when prompted.
- Alternatively, install manually:

```bash
sudo apt update
sudo apt install exiftool mupdf-tools poppler-utils unzip wget python3 -y
cd /usr/local/bin
sudo wget https://didierstevens.com/files/software/pdfid_v0_2_8.zip -O pdfid.zip
sudo unzip -o pdfid.zip && sudo chmod +x pdfid.py
sudo wget https://didierstevens.com/files/software/pdf-parser_V0_7_6.zip -O pdfparser.zip
sudo unzip -o pdfparser.zip && sudo chmod +x pdf-parser.py
```

### No Output in Terminal

- **Cause:** Output redirection issue from older script versions.
- **Fix:** Use this latest script version; it shows live results while generating reports.

### Non-ASCII or Unicode Filenames

- The script supports Unicode through `realpath`.
- If analysis fails, rename the file using only basic Latin characters.

---

## Notes

- This script performs only **static analysis**.
- It does **not** open, execute, or detonate the file content.
- It should be run on a secure offline system for maximum safety.
- Reports are plain text and HTML; no active code or external resources are used.

---

## Example Output (Terminal View)

```
=========================================
 PDF Static Analysis Report
 File: document.pdf
 Generated: Mon Oct 20 22:12:00 2025
=========================================

[1] File Info and Hash
----------------------------------------
1d3f2e7c4b5...  document.pdf
-rw-r--r-- 1 user 220K document.pdf

[2] Metadata (exiftool)
----------------------------------------
Author: John Doe
Producer: Word 2019

[3] Structure Scan (pdfid.py)
----------------------------------------
/JS: 0
/URI: 2
/Launch: 0

[4] Visible URLs (pdftotext)
----------------------------------------
http://malicious-site.example

[5] Suspicious JavaScript Keywords
----------------------------------------
app.launchURL
```

---

## License

This script is distributed for educational and research purposes.  
All included utilities maintain their own licenses from their respective authors.
