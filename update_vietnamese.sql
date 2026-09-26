USE [WebQuanLyQuanAoDb];
GO

UPDATE Categories SET CategoryName = N'Áo Thun & Polo Doanh Nghiệp', Slug = 'ao-thun-polo' WHERE CategoryId = 1;
UPDATE Categories SET CategoryName = N'Áo Sơ Mi & Vest Công Sở', Slug = 'ao-so-mi-cong-so' WHERE CategoryId = 2;
UPDATE Categories SET CategoryName = N'Đồ Bảo Hộ & Áo Phản Quang', Slug = 'do-bao-ho-lao-dong' WHERE CategoryId = 3;
UPDATE Categories SET CategoryName = N'Đồng Phục Nhà Hàng & Cafe', Slug = 'dong-phuc-nha-hang-cafe' WHERE CategoryId = 4;
UPDATE Categories SET CategoryName = N'Áo Khoác Gió & Mũ Nón', Slug = 'ao-khoac-gio-mu-non' WHERE CategoryId = 5;

UPDATE Products SET 
    ProductName = N'Áo Polo Cổ Bẻ Dệt Phối Bo Doanh Nghiệp', 
    Description = N'Vải cá sấu poly thái hoặc CVC cao cấp, giữ form dáng chuẩn, thêu logo ngực độ nét cao, thoáng mát suốt ngày làm việc.',
    MainImage = 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=500&auto=format&fit=crop&q=80'
WHERE ProductId = 1;

UPDATE Products SET 
    ProductName = N'Áo Thun Cổ Tròn Sự Kiện Team Building', 
    Description = N'Vải cotton 100% mềm mịn, co giãn 4 chiều, thấm hút mồ hôi tối đa, chuyên may áo thun sự kiện công ty.',
    MainImage = 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500&auto=format&fit=crop&q=80'
WHERE ProductId = 2;

UPDATE Products SET 
    ProductName = N'Áo Sơ Mi Trắng Kháng Nhăn Dài Tay Oxford', 
    Description = N'Vải Kate Ý cao cấp, bề mặt sáng mịn, chống nhăn tự nhiên, phom dáng Slimfit & Regular chuẩn công sở hiện đại.',
    MainImage = 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=500&auto=format&fit=crop&q=80'
WHERE ProductId = 3;

UPDATE Products SET 
    ProductName = N'Áo Sơ Mi Denim Dáng Rộng Vintage Cho Quán Cafe', 
    Description = N'Vải denim cotton mềm mát, phong cách năng động hiện đại cho nhân viên phục vụ, pha chế quán cafe.',
    MainImage = 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=500&auto=format&fit=crop&q=80'
WHERE ProductId = 4;

UPDATE Products SET 
    ProductName = N'Quần Kaki Kỹ Thuật Túi Hộp Bảo Hộ Lao Động', 
    Description = N'Vải Kaki Pangrim Hàn Quốc dày dặn chống rách, thiết kế nhiều túi hộp tiện dụng cho kỹ sư công trường.',
    CategoryId = 3,
    MainImage = 'https://images.unsplash.com/photo-1517445312882-bc9910d016b7?w=500&auto=format&fit=crop&q=80'
WHERE ProductId = 5;

UPDATE Products SET 
    ProductName = N'Quần Tây Âu 2 Ly Xếp Dáng Hàn Quốc Sang Trọng', 
    Description = N'Vải tuyết mưa co giãn nhẹ, bề mặt không bám bụi, giữ nếp ly phẳng phiu suốt cả ngày làm việc tại văn phòng.',
    CategoryId = 2,
    MainImage = 'https://images.unsplash.com/photo-1479064555552-3ef4979f8908?w=500&auto=format&fit=crop&q=80'
WHERE ProductId = 6;

UPDATE Products SET 
    ProductName = N'Áo Gile Phản Quang 3M Kỹ Sư Công Trình TCVN', 
    Description = N'Dải phản quang 3M siêu sáng ban đêm, may kèm túi đựng bộ đàm và bút, đạt chuẩn kiểm định an toàn lao động.',
    CategoryId = 3,
    IsFeatured = 1,
    MainImage = 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=500&auto=format&fit=crop&q=80'
WHERE ProductId = 7;

UPDATE Products SET 
    ProductName = N'Áo Khoác Gió Bomber 2 Lớp Chống Thấm & Cản Gió', 
    Description = N'Vải dù miro 2 lớp chống gió, trượt nước hiệu quả, bo thun cổ tay và gấu áo cản gió lạnh cho nhân viên giao hàng.',
    CategoryId = 5,
    MainImage = 'https://images.unsplash.com/photo-1544441893-675973e31985?w=500&auto=format&fit=crop&q=80'
WHERE ProductId = 8;
GO
