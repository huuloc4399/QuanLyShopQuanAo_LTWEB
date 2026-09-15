import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def create_report():
    doc = docx.Document()

    # 1. Page Margins: Left 3cm, Top 3cm, Bottom 3cm, Right 2cm
    # 1 cm = 0.393701 inches
    for section in doc.sections:
        section.top_margin = Inches(3.0 * 0.393701)
        section.bottom_margin = Inches(3.0 * 0.393701)
        section.left_margin = Inches(3.0 * 0.393701)
        section.right_margin = Inches(2.0 * 0.393701)

    # Base style: Times New Roman 13pt, 1.5 line spacing
    style = doc.styles['Normal']
    font = style.font
    font.name = 'Times New Roman'
    font.size = Pt(13)
    font.color.rgb = RGBColor(0, 0, 0)
    p_format = style.paragraph_format
    p_format.space_before = Pt(0)
    p_format.space_after = Pt(0)
    p_format.line_spacing = 1.5

    def add_heading_1(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(12)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(text)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(14)
        run.font.bold = True
        run.font.color.rgb = RGBColor(0, 51, 102)
        return p

    def add_heading_2(text):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(8)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(text)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(13)
        run.font.bold = True
        run.font.color.rgb = RGBColor(0, 0, 0)
        return p

    def add_p(text, bold_prefix=None, italic=False):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.line_spacing = 1.5
        if bold_prefix:
            r_bold = p.add_run(bold_prefix)
            r_bold.font.name = 'Times New Roman'
            r_bold.font.size = Pt(13)
            r_bold.font.bold = True
        run = p.add_run(text)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(13)
        run.font.italic = italic
        return p

    def add_table_data(headers, rows):
        table = doc.add_table(rows=1, cols=len(headers))
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        table.autofit = False

        # Format header
        hdr_cells = table.rows[0].cells
        for i, header in enumerate(headers):
            hdr_cells[i].text = header
            # background color for header #1e293b
            shading = parse_xml(r'<w:shd {} w:fill="1F4E79"/>'.format(nsdecls('w')))
            hdr_cells[i]._tc.get_or_add_tcPr().append(shading)
            for p in hdr_cells[i].paragraphs:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                p.paragraph_format.space_before = Pt(2)
                p.paragraph_format.space_after = Pt(2)
                p.paragraph_format.line_spacing = 1.15
                for run in p.runs:
                    run.font.name = 'Times New Roman'
                    run.font.size = Pt(11)
                    run.font.bold = True
                    run.font.color.rgb = RGBColor(255, 255, 255)

        # Add rows
        for r_idx, row in enumerate(rows):
            row_cells = table.add_row().cells
            bg_color = "F2F2F2" if r_idx % 2 == 1 else "FFFFFF"
            for c_idx, val in enumerate(row):
                row_cells[c_idx].text = str(val)
                shd = parse_xml(r'<w:shd {} w:fill="{}"/>'.format(nsdecls('w'), bg_color))
                row_cells[c_idx]._tc.get_or_add_tcPr().append(shd)
                for p in row_cells[c_idx].paragraphs:
                    p.paragraph_format.space_before = Pt(2)
                    p.paragraph_format.space_after = Pt(2)
                    p.paragraph_format.line_spacing = 1.15
                    if c_idx in [0, 1, 2]:
                        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                    for run in p.runs:
                        run.font.name = 'Times New Roman'
                        run.font.size = Pt(11)

        # Set borders for table
        tblPr = table._tbl.tblPr
        borders = parse_xml(
            r'<w:tblBorders {} >'
            r'<w:top w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>'
            r'<w:left w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>'
            r'<w:bottom w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>'
            r'<w:right w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>'
            r'<w:insideH w:val="single" w:sz="4" w:space="0" w:color="E0E0E0"/>'
            r'<w:insideV w:val="single" w:sz="4" w:space="0" w:color="E0E0E0"/>'
            r'</w:tblBorders>'.format(nsdecls('w'))
        )
        tblPr.append(borders)

        doc.add_paragraph().paragraph_format.space_after = Pt(6)

    # CONTENT GENERATION
    add_heading_1("CHƯƠNG 2: PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG")

    add_heading_2("2.1. Sơ đồ Use Case (UML Use Case)")
    add_p("Hệ thống Website Quản lý & Kinh doanh Mặt hàng Quần áo được xây dựng phục vụ ba đối tượng tác nhân (Actors) chính với các quyền hạn và vai trò rõ ràng:")
    add_p("Toàn quyền quản trị hệ thống, bao gồm quản lý người dùng và phân quyền, quản lý danh mục và toàn bộ sản phẩm, duyệt và xử lý đơn đặt hàng, quản lý kho hàng và nhập xuất hàng, xem bảng điều khiển (Dashboard) và báo cáo thống kê doanh thu đa chiều.", bold_prefix="1. Quản trị viên (Admin): ")
    add_p("Thực hiện các nghiệp vụ quản lý kho (kiểm tra lượng tồn kho theo kích thước, màu sắc; tạo phiếu nhập hàng từ xưởng/nhà cung cấp), theo dõi và cập nhật trạng thái đơn hàng (Chờ xác nhận -> Đang giao -> Đã hoàn thành).", bold_prefix="2. Nhân viên (Staff / Quản lý kho): ")
    add_p("Khách hàng vãng lai hoặc đã đăng ký tài khoản có thể xem danh mục, tìm kiếm và lọc mặt hàng quần áo theo giá, xem chi tiết sản phẩm kèm kích cỡ và màu sắc tương ứng, thêm vào giỏ hàng (lưu Session), thực hiện đặt hàng trực tuyến và tra cứu đơn mua.", bold_prefix="3. Khách hàng (Customer): ")
    add_p("[Hình 2.1: Sơ đồ Use Case tổng quát của Hệ thống Quản lý Quần áo]", italic=True)

    add_heading_2("2.2. Thiết kế Cơ sở dữ liệu (ERD)")
    add_p("Cơ sở dữ liệu của hệ thống được đặt tên là WebQuanLyQuanAoDb, được thiết kế và chuẩn hóa đạt chuẩn 3NF trên hệ quản trị Microsoft SQL Server 2019 / 2022. Thiết kế chú trọng giải quyết bài toán đặc thù của ngành kinh doanh thời trang: một mẫu quần áo có nhiều Kích thước (Size S, M, L, XL...) và Màu sắc (Đen, Trắng, Xanh Navy...). Do đó, bảng ProductVariants được dùng làm thực thể liên kết chính để quản lý tồn kho chính xác cho từng biến thể.")
    add_p("Mối quan hệ chính giữa các thực thể:")
    add_p("Một vai trò có thể cấp cho nhiều người dùng (Quan hệ 1 - N).", bold_prefix="- Roles - Users: ")
    add_p("Một danh mục (Category) chứa nhiều sản phẩm (Products) (Quan hệ 1 - N).", bold_prefix="- Categories - Products: ")
    add_p("Một sản phẩm có nhiều biến thể theo bảng Sizes và Colors (Quan hệ 1 - N giữa Products/Sizes/Colors với ProductVariants).", bold_prefix="- Products, Sizes, Colors - ProductVariants: ")
    add_p("Một khách hàng có thể đặt nhiều đơn hàng (Quan hệ 1 - N).", bold_prefix="- Users - Orders: ")
    add_p("Một đơn hàng bao gồm nhiều chi tiết sản phẩm biến thể (Quan hệ 1 - N giữa Orders/ProductVariants với OrderDetails).", bold_prefix="- Orders, ProductVariants - OrderDetails: ")
    add_p("Một nhà cung cấp cung cấp hàng thông qua nhiều phiếu nhập kho (Quan hệ 1 - N giữa Suppliers/Users với ImportReceipts và ImportReceiptDetails).", bold_prefix="- Suppliers, Users - ImportReceipts: ")
    add_p("[Hình 2.2: Sơ đồ thực thể liên kết (ERD) Cơ sở dữ liệu WebQuanLyQuanAoDb]", italic=True)

    add_heading_2("2.3. Mô tả chi tiết các bảng dữ liệu")
    add_p("Dưới đây là cấu trúc chi tiết của các bảng trong cơ sở dữ liệu đã được triển khai thành công:")

    # Table 1: Roles
    add_p("Bảng 2.1. Cấu trúc bảng Roles (Phân quyền người dùng)", bold_prefix="")
    add_table_data(
        ["Tên trường (Column)", "Kiểu dữ liệu (Type)", "Khóa (Key)", "Cho phép NULL", "Mô tả (Description)"],
        [
            ["RoleId", "INT IDENTITY(1,1)", "PK", "NO", "Mã vai trò (Khóa chính, tự tăng)"],
            ["RoleName", "NVARCHAR(50)", "UNIQUE", "NO", "Tên vai trò (Admin, Staff, Customer)"],
            ["Description", "NVARCHAR(255)", "", "YES", "Mô tả chi tiết phạm vi quyền hạn"]
        ]
    )

    # Table 2: Users
    add_p("Bảng 2.2. Cấu trúc bảng Users (Tài khoản người dùng)", bold_prefix="")
    add_table_data(
        ["Tên trường (Column)", "Kiểu dữ liệu (Type)", "Khóa (Key)", "Cho phép NULL", "Mô tả (Description)"],
        [
            ["UserId", "INT IDENTITY(1,1)", "PK", "NO", "Mã người dùng (Khóa chính, tự tăng)"],
            ["Username", "VARCHAR(50)", "UNIQUE", "NO", "Tên đăng nhập duy nhất vào hệ thống"],
            ["PasswordHash", "VARCHAR(255)", "", "NO", "Mật khẩu tài khoản"],
            ["FullName", "NVARCHAR(100)", "", "NO", "Họ và tên đầy đủ của người dùng"],
            ["Email", "VARCHAR(100)", "", "YES", "Địa chỉ thư điện tử"],
            ["PhoneNumber", "VARCHAR(20)", "", "YES", "Số điện thoại liên lạc"],
            ["Address", "NVARCHAR(255)", "", "YES", "Địa chỉ giao nhận hàng mặc định"],
            ["Avatar", "VARCHAR(255)", "", "YES", "Đường dẫn ảnh đại diện cá nhân"],
            ["RoleId", "INT", "FK", "NO", "Khóa ngoại liên kết tới Roles(RoleId)"],
            ["IsActive", "BIT", "", "NO", "Trạng thái hoạt động (1: Hoạt động, 0: Khóa)"],
            ["CreatedAt", "DATETIME", "", "NO", "Thời điểm khởi tạo tài khoản (GETDATE())"]
        ]
    )

    # Table 3: Categories
    add_p("Bảng 2.3. Cấu trúc bảng Categories (Danh mục sản phẩm quần áo)", bold_prefix="")
    add_table_data(
        ["Tên trường (Column)", "Kiểu dữ liệu (Type)", "Khóa (Key)", "Cho phép NULL", "Mô tả (Description)"],
        [
            ["CategoryId", "INT IDENTITY(1,1)", "PK", "NO", "Mã danh mục (Khóa chính, tự tăng)"],
            ["CategoryName", "NVARCHAR(100)", "", "NO", "Tên phân loại (Áo thun, Sơ mi, Quần Jean...)"],
            ["Slug", "VARCHAR(100)", "", "YES", "Chuỗi định danh thân thiện URL phục vụ SEO"],
            ["Description", "NVARCHAR(500)", "", "YES", "Mô tả ngắn về nhóm trang phục"],
            ["ImageUrl", "VARCHAR(255)", "", "YES", "Hình ảnh minh họa cho danh mục"],
            ["DisplayOrder", "INT", "", "NO", "Thứ tự sắp xếp hiển thị trên Menu website"],
            ["IsActive", "BIT", "", "NO", "Trạng thái hiển thị danh mục (1: Hiện, 0: Ẩn)"]
        ]
    )

    # Table 4: Products
    add_p("Bảng 2.4. Cấu trúc bảng Products (Mặt hàng quần áo)", bold_prefix="")
    add_table_data(
        ["Tên trường (Column)", "Kiểu dữ liệu (Type)", "Khóa (Key)", "Cho phép NULL", "Mô tả (Description)"],
        [
            ["ProductId", "INT IDENTITY(1,1)", "PK", "NO", "Mã sản phẩm (Khóa chính, tự tăng)"],
            ["CategoryId", "INT", "FK", "NO", "Khóa ngoại liên kết tới Categories(CategoryId)"],
            ["ProductName", "NVARCHAR(200)", "", "NO", "Tên mặt hàng quần áo"],
            ["ProductCode", "VARCHAR(50)", "UNIQUE", "YES", "Mã kiểu dáng sản phẩm (VD: AT-001)"],
            ["Description", "NVARCHAR(MAX)", "", "YES", "Mô tả chi tiết chất liệu, form dáng, cách bảo quản"],
            ["OriginalPrice", "DECIMAL(18,2)", "", "NO", "Giá vốn / Giá nhập hàng"],
            ["Price", "DECIMAL(18,2)", "", "NO", "Giá bán niêm yết chính thức"],
            ["DiscountPercent", "INT", "", "YES", "Phần trăm giảm giá khuyến mãi (%)"],
            ["MainImage", "VARCHAR(255)", "", "YES", "Đường dẫn hình ảnh đại diện sản phẩm"],
            ["IsFeatured", "BIT", "", "NO", "Đánh dấu sản phẩm nổi bật trên Trang chủ (1: Có)"],
            ["IsActive", "BIT", "", "NO", "Trạng thái kinh doanh (1: Đang bán, 0: Ngừng bán)"],
            ["CreatedAt", "DATETIME", "", "NO", "Thời điểm thêm sản phẩm vào hệ thống"]
        ]
    )

    # Table 5: Sizes
    add_p("Bảng 2.5. Cấu trúc bảng Sizes (Kích cỡ quần áo)", bold_prefix="")
    add_table_data(
        ["Tên trường (Column)", "Kiểu dữ liệu (Type)", "Khóa (Key)", "Cho phép NULL", "Mô tả (Description)"],
        [
            ["SizeId", "INT IDENTITY(1,1)", "PK", "NO", "Mã kích cỡ (Khóa chính, tự tăng)"],
            ["SizeName", "VARCHAR(20)", "UNIQUE", "NO", "Tên size (XS, S, M, L, XL, XXL, 29, 30...)"],
            ["Description", "NVARCHAR(100)", "", "YES", "Mô tả gợi ý chiều cao, cân nặng tương ứng"]
        ]
    )

    # Table 6: Colors
    add_p("Bảng 2.6. Cấu trúc bảng Colors (Màu sắc)", bold_prefix="")
    add_table_data(
        ["Tên trường (Column)", "Kiểu dữ liệu (Type)", "Khóa (Key)", "Cho phép NULL", "Mô tả (Description)"],
        [
            ["ColorId", "INT IDENTITY(1,1)", "PK", "NO", "Mã màu (Khóa chính, tự tăng)"],
            ["ColorName", "NVARCHAR(50)", "UNIQUE", "NO", "Tên màu sắc (Đen, Trắng, Xanh Navy,...)"],
            ["ColorHex", "VARCHAR(10)", "", "YES", "Mã màu HEX dùng hiển thị trực quan (#000000)"]
        ]
    )

    # Table 7: ProductVariants
    add_p("Bảng 2.7. Cấu trúc bảng ProductVariants (Biến thể sản phẩm & Tồn kho)", bold_prefix="")
    add_table_data(
        ["Tên trường (Column)", "Kiểu dữ liệu (Type)", "Khóa (Key)", "Cho phép NULL", "Mô tả (Description)"],
        [
            ["VariantId", "INT IDENTITY(1,1)", "PK", "NO", "Mã biến thể (Khóa chính, tự tăng)"],
            ["ProductId", "INT", "FK", "NO", "Khóa ngoại liên kết tới Products(ProductId)"],
            ["SizeId", "INT", "FK", "NO", "Khóa ngoại liên kết tới Sizes(SizeId)"],
            ["ColorId", "INT", "FK", "NO", "Khóa ngoại liên kết tới Colors(ColorId)"],
            ["SKU", "VARCHAR(50)", "UNIQUE", "YES", "Mã định danh quản lý kho (Stock Keeping Unit)"],
            ["StockQuantity", "INT", "", "NO", "Số lượng sản phẩm còn tồn trong kho"],
            ["VariantImage", "VARCHAR(255)", "", "YES", "Đường dẫn hình ảnh theo biến thể màu sắc"]
        ]
    )

    # Table 8: Orders
    add_p("Bảng 2.8. Cấu trúc bảng Orders (Đơn đặt hàng)", bold_prefix="")
    add_table_data(
        ["Tên trường (Column)", "Kiểu dữ liệu (Type)", "Khóa (Key)", "Cho phép NULL", "Mô tả (Description)"],
        [
            ["OrderId", "INT IDENTITY(1,1)", "PK", "NO", "Mã đơn hàng (Khóa chính, tự tăng)"],
            ["UserId", "INT", "FK", "YES", "Khóa ngoại tham chiếu Users(UserId)"],
            ["OrderDate", "DATETIME", "", "NO", "Thời điểm đặt hàng (GETDATE())"],
            ["ReceiverName", "NVARCHAR(100)", "", "NO", "Họ tên người nhận bưu kiện"],
            ["ReceiverPhone", "VARCHAR(20)", "", "NO", "Số điện thoại người nhận"],
            ["ShippingAddress", "NVARCHAR(255)", "", "NO", "Địa chỉ giao hàng"],
            ["OrderNotes", "NVARCHAR(500)", "", "YES", "Ghi chú của khách hàng khi đặt đơn"],
            ["TotalAmount", "DECIMAL(18,2)", "", "NO", "Tổng số tiền thanh toán của đơn hàng"],
            ["PaymentMethod", "NVARCHAR(50)", "", "NO", "Hình thức thanh toán (COD, Chuyển khoản, VNPay)"],
            ["PaymentStatus", "NVARCHAR(50)", "", "NO", "Trạng thái thanh toán (Chưa / Đã thanh toán)"],
            ["OrderStatus", "NVARCHAR(50)", "", "NO", "Trạng thái đơn (Chờ xác nhận, Đang giao, Đã giao, Hủy)"]
        ]
    )

    # Table 9: OrderDetails
    add_p("Bảng 2.9. Cấu trúc bảng OrderDetails (Chi tiết đơn hàng)", bold_prefix="")
    add_table_data(
        ["Tên trường (Column)", "Kiểu dữ liệu (Type)", "Khóa (Key)", "Cho phép NULL", "Mô tả (Description)"],
        [
            ["OrderDetailId", "INT IDENTITY(1,1)", "PK", "NO", "Mã chi tiết đơn hàng (Khóa chính, tự tăng)"],
            ["OrderId", "INT", "FK", "NO", "Khóa ngoại liên kết tới Orders(OrderId)"],
            ["VariantId", "INT", "FK", "NO", "Khóa ngoại liên kết tới ProductVariants(VariantId)"],
            ["Quantity", "INT", "", "NO", "Số lượng mặt hàng mua (CHECK > 0)"],
            ["UnitPrice", "DECIMAL(18,2)", "", "NO", "Đơn giá sản phẩm tại thời điểm mua"],
            ["TotalPrice", "DECIMAL(18,2)", "", "NO", "Thành tiền tự động tính (Quantity * UnitPrice)"]
        ]
    )

    # Table 10: Suppliers
    add_p("Bảng 2.10. Cấu trúc bảng Suppliers (Nhà cung cấp / Xưởng may)", bold_prefix="")
    add_table_data(
        ["Tên trường (Column)", "Kiểu dữ liệu (Type)", "Khóa (Key)", "Cho phép NULL", "Mô tả (Description)"],
        [
            ["SupplierId", "INT IDENTITY(1,1)", "PK", "NO", "Mã nhà cung cấp (Khóa chính, tự tăng)"],
            ["SupplierName", "NVARCHAR(150)", "", "NO", "Tên nhà cung cấp hoặc xưởng may gia công"],
            ["Phone", "VARCHAR(20)", "", "YES", "Số điện thoại liên hệ"],
            ["Email", "VARCHAR(100)", "", "YES", "Hòm thư điện tử liên hệ"],
            ["Address", "NVARCHAR(255)", "", "YES", "Địa chỉ xưởng may / trụ sở nhà cung cấp"]
        ]
    )

    # Table 11 & 12: ImportReceipts & Details
    add_p("Bảng 2.11. Cấu trúc bảng ImportReceipts (Phiếu nhập kho)", bold_prefix="")
    add_table_data(
        ["Tên trường (Column)", "Kiểu dữ liệu (Type)", "Khóa (Key)", "Cho phép NULL", "Mô tả (Description)"],
        [
            ["ImportId", "INT IDENTITY(1,1)", "PK", "NO", "Mã phiếu nhập kho (Khóa chính, tự tăng)"],
            ["SupplierId", "INT", "FK", "NO", "Khóa ngoại liên kết tới Suppliers(SupplierId)"],
            ["UserId", "INT", "FK", "NO", "Mã nhân viên lập phiếu (Users)"],
            ["ImportDate", "DATETIME", "", "NO", "Ngày giờ nhập kho"],
            ["TotalAmount", "DECIMAL(18,2)", "", "NO", "Tổng giá trị tiền hàng nhập kho"],
            ["Notes", "NVARCHAR(500)", "", "YES", "Ghi chú kiểm tra số lượng, hóa đơn đi kèm"]
        ]
    )

    add_p("Bảng 2.12. Cấu trúc bảng ImportReceiptDetails (Chi tiết phiếu nhập kho)", bold_prefix="")
    add_table_data(
        ["Tên trường (Column)", "Kiểu dữ liệu (Type)", "Khóa (Key)", "Cho phép NULL", "Mô tả (Description)"],
        [
            ["ImportDetailId", "INT IDENTITY(1,1)", "PK", "NO", "Mã chi tiết phiếu nhập (Khóa chính, tự tăng)"],
            ["ImportId", "INT", "FK", "NO", "Khóa ngoại liên kết tới ImportReceipts(ImportId)"],
            ["VariantId", "INT", "FK", "NO", "Khóa ngoại liên kết tới ProductVariants(VariantId)"],
            ["Quantity", "INT", "", "NO", "Số lượng mặt hàng nhập về kho (CHECK > 0)"],
            ["ImportPrice", "DECIMAL(18,2)", "", "NO", "Đơn giá nhập hàng từ nhà cung cấp"],
            ["TotalPrice", "DECIMAL(18,2)", "", "NO", "Thành tiền tự động tính (Quantity * ImportPrice)"]
        ]
    )

    doc.save("BaoCao_Chuong2_ThietKeCSDL.docx")
    print("Successfully generated BaoCao_Chuong2_ThietKeCSDL.docx")

if __name__ == "__main__":
    create_report()
