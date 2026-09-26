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
        res = urllib.request.urlopen(f"{URL}/", timeout=2)
        if res.status == 200:
            ready = True
            break
    except:
        pass

if not ready:
    print("Server failed to start.")
    proc.terminate()
    exit(1)

print("Server ready. Capturing full page screenshot...")

full_out = os.path.join(OUTPUT_DIR, "demo_home_full_10000.png")
cmd = [
    BROWSER,
    "--headless=new",
    "--disable-gpu",
    "--window-size=1366,9500",
    f"--screenshot={full_out}",
    f"{URL}/"
]
subprocess.run(cmd, check=True)
print("Captured full page.")

im = Image.open(full_out)
w, h = im.size
print(f"Image dimensions: {w}x{h}")

# 1. Hero & Brands
im.crop((0, 0, w, 820)).save(os.path.join(OUTPUT_DIR, "demo_page1_hero_header.png"))

# 2. Quy trình & Đồng phục theo nghề
im.crop((0, 800, w, 2200)).save(os.path.join(OUTPUT_DIR, "demo_page1_products_categories.png"))

# 3. Đồ bảo hộ, 5 bước đặt may & Gói báo giá
im.crop((0, 2180, w, 3950)).save(os.path.join(OUTPUT_DIR, "demo_page1_process_pricing.png"))

# 4. Khách hàng thực tế, Số liệu & Đánh giá
im.crop((0, 3930, w, 5200)).save(os.path.join(OUTPUT_DIR, "demo_page1_clients_testimonials.png"))

# 5. Cẩm nang vải, Form báo giá & Chân trang Footer
im.crop((0, 5180, w, h)).save(os.path.join(OUTPUT_DIR, "demo_page1_contact_footer.png"))

# 6. Chân trang Footer riêng biệt
im.crop((0, h - 800, w, h)).save(os.path.join(OUTPUT_DIR, "demo_page1_footer_exact.png"))

print("Cropped slides successfully!")

proc.terminate()
try:
    proc.wait(timeout=3)
except:
    proc.kill()
