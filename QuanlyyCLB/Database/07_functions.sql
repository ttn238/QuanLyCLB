USE QuanLyCLBSinhVien;
GO
/* =====================================================================
   7 FUNCTION (chạy trước views và procedures)
   ===================================================================== */

-- Tài khoản của Chủ nhiệm đang giữ chức trong CLB (NULL nếu chưa có)
CREATE OR ALTER FUNCTION fn_TaiKhoanChuNhiem (@MaCLB INT)
RETURNS INT
AS
BEGIN
    RETURN (SELECT TOP 1 tk.MaTK
            FROM ThanhVien tv
            JOIN TaiKhoan tk ON tk.MaSV = tv.MaSV
            WHERE tv.MaCLB = @MaCLB AND tv.ChucVu = 'ChuNhiem' AND tv.TrangThai <> 'DaRoi'
            ORDER BY tv.MaThanhVien);
END;
GO

-- Tài khoản giảng viên cố vấn của CLB (NULL nếu giảng viên chưa có tài khoản)
CREATE OR ALTER FUNCTION fn_TaiKhoanCoVan (@MaCLB INT)
RETURNS INT
AS
BEGIN
    RETURN (SELECT TOP 1 tk.MaTK
            FROM CLB c
            JOIN TaiKhoan tk ON tk.MaGV = c.MaGVCoVan
            WHERE c.MaCLB = @MaCLB);
END;
GO

-- Tài khoản có phải người quản lý (Chủ nhiệm hoặc Phụ trách thu chi) của CLB không
CREATE OR ALTER FUNCTION fn_LaQuanLyCLB (@MaTK INT, @MaCLB INT)
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN EXISTS (
                SELECT 1
                FROM ThanhVien tv
                JOIN TaiKhoan tk ON tk.MaSV = tv.MaSV
                WHERE tk.MaTK = @MaTK AND tv.MaCLB = @MaCLB AND tv.TrangThai <> 'DaRoi'
                  AND tv.ChucVu IN ('ChuNhiem','NguoiPhuTrachThuChi'))
            THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END;
END;
GO

-- Số dư quỹ hiện tại của CLB = tổng thu - tổng chi
CREATE OR ALTER FUNCTION fn_SoDuQuy (@MaCLB INT)
RETURNS DECIMAL(15,2)
AS
BEGIN
    RETURN (SELECT ISNULL(SUM(CASE Loai WHEN 'Thu' THEN SoTien ELSE -SoTien END), 0)
            FROM GiaoDich WHERE MaCLB = @MaCLB);
END;
GO

-- Số thành viên chưa rời CLB
CREATE OR ALTER FUNCTION fn_SoThanhVienHoatDong (@MaCLB INT)
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM ThanhVien WHERE MaCLB = @MaCLB AND TrangThai = 'HoatDong');
END;
GO

-- Ngày hoạt động gần nhất của thành viên: lần điểm danh hợp lệ cuối, hoặc ngày gia nhập nếu muộn hơn
CREATE OR ALTER FUNCTION fn_NgayHoatDongCuoi (@MaThanhVien INT)
RETURNS DATE
AS
BEGIN
    DECLARE @gn DATE = (SELECT NgayGiaNhap FROM ThanhVien WHERE MaThanhVien = @MaThanhVien);
    DECLARE @dd DATE = (SELECT MAX(CAST(ThoiGian AS DATE)) FROM DiemDanh
                        WHERE MaThanhVien = @MaThanhVien AND TrangThai = 'HopLe');
    RETURN CASE WHEN @dd IS NOT NULL AND @dd > @gn THEN @dd ELSE @gn END;
END;
GO

-- Tổng thu, tổng chi, chênh lệch của CLB trong một khoảng ngày (dùng cho báo cáo)
CREATE OR ALTER FUNCTION fn_TongHopThuChi (@MaCLB INT, @TuNgay DATE, @DenNgay DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT COALESCE(SUM(CASE WHEN Loai = 'Thu' THEN SoTien END), 0) AS TongThu,
           COALESCE(SUM(CASE WHEN Loai = 'Chi' THEN SoTien END), 0) AS TongChi,
           COALESCE(SUM(CASE WHEN Loai = 'Thu' THEN SoTien END), 0)
         - COALESCE(SUM(CASE WHEN Loai = 'Chi' THEN SoTien END), 0) AS ChenhLech
    FROM GiaoDich
    WHERE MaCLB = @MaCLB AND NgayGiaoDich BETWEEN @TuNgay AND @DenNgay
);
GO

PRINT N'Đã tạo function.';
GO
