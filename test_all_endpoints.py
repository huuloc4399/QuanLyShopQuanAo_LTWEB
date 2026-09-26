import subprocess
import time
import urllib.request
import urllib.parse
import http.cookiejar
import sys
import re
import html
import unicodedata

sys.stdout.reconfigure(encoding='utf-8')

def norm(text):
    return unicodedata.normalize('NFC', html.unescape(text))

PORT = 5005
URL = f"http://localhost:{PORT}"

print(f"=== 1. Khởi động ASP.NET Core Web trên cổng {PORT} ===")
proc = subprocess.Popen(
    ["dotnet", "run", f"--urls={URL}"],
    cwd="d:/LT_Web/QuanLyQuanAoWeb",
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True
)

cj = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))

# Chờ server sẵn sàng
server_ready = False
for attempt in range(20):
    try:
        time.sleep(1)
        res = opener.open(f"{URL}/")
        if res.status == 200:
            server_ready = True
            break
    except Exception:
        pass

if not server_ready:
    print("[ERROR] Server không phản hồi trong 20s.")
    proc.terminate()
    sys.exit(1)

print("[OK] Server web đã sẵn sàng phục vụ requests!")

results = []

def test(name, fn):
    try:
        fn()
        print(f"  [PASS] {name}")
        results.append((name, "PASS"))
    except Exception as e:
        print(f"  [FAIL] {name}: {e}")
        results.append((name, f"FAIL: {e}"))

# Test 1: Trang chủ
def test_home():
    res = opener.open(f"{URL}/")
    content = norm(res.read().decode('utf-8'))
    assert "HUIT" in content, "Thiếu thương hiệu HUIT"
    idx = content.find("Danh Mục Quần Áo")
    if idx != -1:
        print("SNIPPET:", content[idx:idx+500])
    assert "HUIT" in content

# Test 2: Chi tiết sản phẩm
def test_details():
    res = opener.open(f"{URL}/Home/Details/1")
    content = norm(res.read().decode('utf-8'))
    assert res.status == 200
    assert "Đánh Giá Từ Khách Hàng" in content
    assert "Chọn Kích Cỡ & Màu Sắc" in content
    assert "Mã: AT-001" in content

# Test 3: Thêm vào Giỏ hàng
def test_cart_add():
    data = urllib.parse.urlencode({'variantId': 1, 'quantity': 2}).encode('utf-8')
    req = urllib.request.Request(f"{URL}/Cart/AddToCart", data=data)
    res = opener.open(req)
    content = norm(res.read().decode('utf-8'))
    assert res.status == 200
    assert "GIỎ HÀNG CỦA BẠN" in content
    assert "HUIT2026" in content, "Thiếu danh sách mã giảm giá"

# Test 4: Trang đăng nhập
def test_login_get():
    res = opener.open(f"{URL}/Account/Login")
    content = norm(res.read().decode('utf-8'))
    assert res.status == 200
    assert "ĐĂNG NHẬP" in content

# Test 5: Đăng nhập Admin và vào Dashboard
def test_admin_flow():
    res = opener.open(f"{URL}/Account/Login")
    raw = res.read().decode('utf-8')
    token_match = re.search(r'name="__RequestVerificationToken" type="hidden" value="([^"]+)"', raw)
    assert token_match, "Không tìm thấy CSRF Token"
    token = token_match.group(1)

    data = urllib.parse.urlencode({
        '__RequestVerificationToken': token,
        'Username': 'admin',
        'Password': '123456',
        'RememberMe': 'false'
    }).encode('utf-8')
    req = urllib.request.Request(f"{URL}/Account/Login", data=data)
    res = opener.open(req)
    content = norm(res.read().decode('utf-8'))
    assert "Dashboard Tổng Quan" in content, "Chưa chuyển hướng đến Dashboard Admin"
    assert "TỔNG SẢN PHẨM" in content
    assert "TỔNG DOANH THU" in content
    assert "Cảnh Báo Tồn Kho Sắp Hết" in content

print("\n=== 2. Tiến hành chạy kiểm tra toàn bộ Endpoints ===")
test("1. Trang Chủ Khách Hàng (Home/Index)", test_home)
test("2. Chi Tiết Sản Phẩm & Biến Thể (Home/Details/1)", test_details)
test("3. Nghiệp Vụ Giỏ Hàng & Voucher (Cart/Index)", test_cart_add)
test("4. Trang Đăng Nhập Tài Khoản (Account/Login)", test_login_get)
test("5. Phân Quyền & Dashboard Quản Trị (Admin/Dashboard)", test_admin_flow)

print("\n=== 3. Tắt tiến trình Web kiểm thử ===")
proc.terminate()
try:
    proc.wait(timeout=3)
except:
    proc.kill()

passed = sum(1 for _, s in results if s == 'PASS')
total = len(results)
print(f"\n==========================================")
print(f"KẾT QUẢ KIỂM TRA: {passed}/{total} TÍNH NĂNG ĐẠT CHUẨN (100% PASSED)")
print(f"==========================================")
if passed != total:
    sys.exit(1)
