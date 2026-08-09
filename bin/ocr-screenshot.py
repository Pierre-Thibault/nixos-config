#!/home/pierre/.local/share/ocr-screenshot/venv/bin/python
# OCR: grim + slurp for the capture, Tesseract and EasyOCR (GPU) both run,
# the longer result wins (ties go to Tesseract). Spawned directly by niri
# (Shift+Mod+T) via this shebang, using the persistent venv — see
# ../modules/ai/ocr.nix for the CUDA-adjacent library setup this needs.
import os
import subprocess
import sys
import time
from pathlib import Path

# torch's compiled extensions need libstdc++.so.6 and friends, absent from
# NixOS's default library search path — re-exec once with it added.
if os.environ.get("OCR_LD_FIXED") != "1":
    os.environ["LD_LIBRARY_PATH"] = "/etc/ocr-screenshot-libs:" + os.environ.get("LD_LIBRARY_PATH", "")
    os.environ["OCR_LD_FIXED"] = "1"
    os.execv(sys.executable, [sys.executable] + sys.argv)

HOME = Path.home()
CAPTURE_DIR = HOME / ".local/share/ocr-screenshot/captures"
LOG_FILE = HOME / ".local/share/ocr-screenshot/ocr-screenshot.log"
CAPTURE_DIR.mkdir(parents=True, exist_ok=True)


def notify(body, urgency=None):
    cmd = ["notify-send", "OCR", body]
    if urgency:
        cmd += ["--urgency", urgency]
    subprocess.run(cmd)


selection = subprocess.run(["slurp"], capture_output=True, text=True)
if selection.returncode != 0:
    sys.exit(1)
selection_geom = selection.stdout.strip()

temp_img = Path(f"/tmp/ocr-screenshot-{os.getpid()}.png")
if subprocess.run(["grim", "-g", selection_geom, str(temp_img)]).returncode != 0:
    sys.exit(1)

tess = subprocess.run(
    ["tesseract", str(temp_img), "-", "-l", "fra+eng+spa"],
    capture_output=True,
    text=True,
)
tess_text = tess.stdout.strip()

easy_text = ""
easy_err = ""
try:
    import easyocr

    reader = easyocr.Reader(["en", "fr", "es"], gpu=True, verbose=False)
    easy_text = "\n".join(reader.readtext(str(temp_img), detail=0)).strip()
except Exception as e:
    easy_err = repr(e)

if len(easy_text) > len(tess_text):
    text, engine = easy_text, "easyocr"
else:
    text, engine = tess_text, "tesseract"

timestamp = time.strftime("%Y%m%d-%H%M%S")
saved_img = CAPTURE_DIR / f"ocr-{timestamp}.png"
temp_img.replace(saved_img)

with open(LOG_FILE, "a") as f:
    f.write(f"=== {timestamp} ===\n")
    f.write(f"Image: {saved_img}\n")
    f.write(f"Selection: {selection_geom}\n")
    f.write(f"Winner: {engine}\n")
    f.write(f"Tesseract ({len(tess_text)} chars): {tess_text}\n")
    f.write(f"EasyOCR ({len(easy_text)} chars): {easy_text}\n")
    if tess.stderr.strip():
        f.write(f"Tesseract stderr:\n{tess.stderr}\n")
    if easy_err:
        f.write(f"EasyOCR error:\n{easy_err}\n")
    f.write("\n")

if text:
    subprocess.run(["wl-copy"], input=text, text=True)
    subprocess.Popen(["pw-play", str(Path(__file__).resolve().parent / "camera-shutter.oga")])
    notify(f"Texte copié dans le presse-papiers ({engine})")
else:
    notify(f"Aucun texte détecté (image conservée : {saved_img})", urgency="critical")
