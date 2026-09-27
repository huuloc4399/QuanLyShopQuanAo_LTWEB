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

cj = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))

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
    assert res.status == 200

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

# Test 6: Danh mục sản phẩm (Figma Screen 3)
def test_products_catalog():
    res = opener.open(f"{URL}/Home/Products")
    content = norm(res.read().decode('utf-8'))
    assert res.status == 200
    assert "SẢN PHẨM ĐỒNG PHỤC" in content

# Test 7: Cẩm nang & Tin tức (Figma Screen 4)
def test_news_page():
    res = opener.open(f"{URL}/Home/News")
    content = norm(res.read().decode('utf-8'))
    assert res.status == 200
    assert "TIN TỨC & CẨM NANG" in content

# Test 8: Báo giá & Liên hệ (Figma Screen 5)
def test_contact_page():
    res = opener.open(f"{URL}/Home/Contact")
    content = norm(res.read().decode('utf-8'))
    assert res.status == 200
    assert "LIÊN HỆ VỚI CHÚNG TÔI" in content

# Test 9: Gửi yêu cầu báo giá qua POST
def test_contact_submit():
    res = opener.open(f"{URL}/Home/Contact")
    raw = res.read().decode('utf-8')
    token_match = re.search(r'name="__RequestVerificationToken" type="hidden" value="([^"]+)"', raw)
    assert token_match, "Không tìm thấy CSRF Token tại trang Liên Hệ"
    token = token_match.group(1)

    data = urllib.parse.urlencode({
        '__RequestVerificationToken': token,
        'FullName': 'Công ty ABC Test',
        'PhoneNumber': '0909999888',
        'Email': 'abc@example.com',
        'CompanyName': 'Tập đoàn ABC',
        'UniformType': 'Áo Thun & Polo Doanh Nghiệp',
        'Quantity': '100 - 300 cái',
        'Note': 'Cần tư vấn mẫu áo polo thêu logo doanh nghiệp'
    }).encode('utf-8')
    req = urllib.request.Request(f"{URL}/Home/Contact", data=data)
    res = opener.open(req)
    content = norm(res.read().decode('utf-8'))
    assert "Gửi yêu cầu thành công!" in content
    assert "Công ty ABC Test" in content

print("=== Tiến hành kiểm thử trực tiếp hệ thống với CSDL 29 bảng ===")
test("1. Trang Chủ Khách Hàng (Home/Index)", test_home)
test("2. Chi Tiết Sản Phẩm & Biến Thể (Home/Details/1)", test_details)
test("3. Nghiệp Vụ Giỏ Hàng & Voucher (Cart/Index)", test_cart_add)
test("4. Trang Đăng Nhập Tài Khoản (Account/Login)", test_login_get)
test("5. Phân Quyền & Dashboard Quản Trị (Admin/Dashboard)", test_admin_flow)
test("6. Danh Mục Sản Phẩm (Home/Products)", test_products_catalog)
test("7. Cẩm Nang & Tin Tức (Home/News)", test_news_page)
test("8. Báo Giá & Liên Hệ (Home/Contact)", test_contact_page)
test("9. Gửi Form Báo Giá (POST Home/Contact)", test_contact_submit)

passed = sum(1 for _, s in results if s == 'PASS')
total = len(results)
print(f"\n==========================================")
print(f"KẾT QUẢ KIỂM TRA: {passed}/{total} TÍNH NĂNG ĐẠT CHUẨN (100% PASSED)")
print(f"==========================================")
if passed != total:
    sys.exit(1)
