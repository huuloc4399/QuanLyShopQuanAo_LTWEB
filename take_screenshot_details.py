import subprocess
import time
import urllib.request
import os
from PIL import Image

PORT = 5005
URL = f"http://localhost:{PORT}"
BROWSER = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
OUTPUT_DIR = r"C:\Users\pc\.gemini\antigravity\brain\9caee821-2f47-4be4-8f61-163a8956f752"

print(f"Starting web server on {URL}...")
proc = subprocess.Popen(
    ["dotnet", "run", f"--urls={URL}"],
    cwd="d:/LT_Web/QuanLyQuanAoWeb",
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True
)

ready = False
for _ in range(25):
    try:
        time.sleep(1)
        res = urllib.request.urlopen(f"{URL}/Home/Details/3", timeout=2)
        if res.status == 200:
            ready = True
            break
    except:
        pass

if not ready:
    print("Server failed to start.")
    proc.terminate()
    exit(1)

print("Server ready. Capturing Product Details page screenshot...")

full_out = os.path.join(OUTPUT_DIR, "demo_details_full_3200.png")
cmd = [
    BROWSER,
    "--headless=new",
    "--disable-gpu",
    "--window-size=1366,3200",
    f"--screenshot={full_out}",
    f"{URL}/Home/Details/3"
]
subprocess.run(cmd, check=True)
print("Captured full product details page.")

im = Image.open(full_out)
w, h = im.size
print(f"Image dimensions: {w}x{h}")

# 1. Product Top Showcase: Header, Breadcrumb, Gallery, Price, Specs, Add to Cart
im.crop((0, 0, w, 950)).save(os.path.join(OUTPUT_DIR, "demo_page2_details_top.png"))

# 2. Product Bottom: Tabs Specs, Size Chart Table, Related Products & CTA
im.crop((0, 930, w, 2400)).save(os.path.join(OUTPUT_DIR, "demo_page2_details_sizechart_related.png"))

print("Cropped Page 2 presentation slides successfully!")

proc.terminate()
try:
    proc.wait(timeout=3)
except:
    proc.kill()
