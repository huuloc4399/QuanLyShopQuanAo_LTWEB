USE [WebQuanLyQuanAoDb];
GO

UPDATE Colors SET ColorName = N'Đen Classic' WHERE ColorId = 1;
UPDATE Colors SET ColorName = N'Trắng Tinh Khôi' WHERE ColorId = 2;
UPDATE Colors SET ColorName = N'Xanh Navy Trầm' WHERE ColorId = 3;
UPDATE Colors SET ColorName = N'Xám Khói Hiện Đại' WHERE ColorId = 4;
UPDATE Colors SET ColorName = N'Màu Be Thanh Lịch' WHERE ColorId = 5;

UPDATE Sizes SET SizeName = 'S', Description = N'Size Nhỏ' WHERE SizeId = 1;
UPDATE Sizes SET SizeName = 'M', Description = N'Size Vừa' WHERE SizeId = 2;
UPDATE Sizes SET SizeName = 'L', Description = N'Size Lớn' WHERE SizeId = 3;
UPDATE Sizes SET SizeName = 'XL', Description = N'Size Rất Lớn' WHERE SizeId = 4;
UPDATE Sizes SET SizeName = 'XXL', Description = N'Size Ngoại Cỡ' WHERE SizeId = 5;
GO
