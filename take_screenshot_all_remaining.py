import subprocess
import time
import urllib.request
import os
import sys
from PIL import Image

sys.stdout.reconfigure(encoding='utf-8')

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
        res = urllib.request.urlopen(f"{URL}/Home/Products", timeout=2)
        if res.status == 200:
            ready = True
            break
    except:
        pass

if not ready:
    print("Server failed to start.")
    proc.terminate()
    exit(1)

print("Server ready. Starting screenshots...")

# ----------------- SCREEN 3: CATEGORY / PRODUCTS -----------------
print("Capturing Page 3: Danh Mục Sản Phẩm...")
full_p3 = os.path.join(OUTPUT_DIR, "demo_page3_category_full.png")
subprocess.run([
    BROWSER, "--headless=new", "--disable-gpu", "--window-size=1366,2600",
    f"--screenshot={full_p3}", f"{URL}/Home/Products"
], check=True)

im_p3 = Image.open(full_p3)
w3, h3 = im_p3.size
im_p3.crop((0, 0, w3, 1400)).save(os.path.join(OUTPUT_DIR, "demo_page3_category_top.png"))
im_p3.crop((0, 1380, w3, min(h3, 2550))).save(os.path.join(OUTPUT_DIR, "demo_page3_category_safety_cta.png"))
print("Done Page 3.")

# ----------------- SCREEN 4: NEWS / CẨM NANG -----------------
print("Capturing Page 4: Cẩm Nang & Tin Tức...")
full_p4 = os.path.join(OUTPUT_DIR, "demo_page4_news_full.png")
subprocess.run([
    BROWSER, "--headless=new", "--disable-gpu", "--window-size=1366,2700",
    f"--screenshot={full_p4}", f"{URL}/Home/News"
], check=True)

im_p4 = Image.open(full_p4)
w4, h4 = im_p4.size
im_p4.crop((0, 0, w4, 1550)).save(os.path.join(OUTPUT_DIR, "demo_page4_news_grid.png"))
im_p4.crop((0, 1530, w4, min(h4, 2680))).save(os.path.join(OUTPUT_DIR, "demo_page4_news_newsletter_footer.png"))
print("Done Page 4.")

# ----------------- SCREEN 5: CONTACT / LIÊN HỆ & BÁO GIÁ -----------------
print("Capturing Page 5: Liên Hệ & Báo Giá...")
full_p5 = os.path.join(OUTPUT_DIR, "demo_page5_contact_full.png")
subprocess.run([
    BROWSER, "--headless=new", "--disable-gpu", "--window-size=1366,1900",
    f"--screenshot={full_p5}", f"{URL}/Home/Contact"
], check=True)

im_p5 = Image.open(full_p5)
w5, h5 = im_p5.size
im_p5.crop((0, 0, w5, 1100)).save(os.path.join(OUTPUT_DIR, "demo_page5_contact_cards_form.png"))
im_p5.crop((0, 1050, w5, min(h5, 1850))).save(os.path.join(OUTPUT_DIR, "demo_page5_contact_map_footer.png"))
print("Done Page 5.")

print("\nAll remaining pages captured successfully!")

proc.terminate()
try:
    proc.wait(timeout=3)
except:
    proc.kill()
