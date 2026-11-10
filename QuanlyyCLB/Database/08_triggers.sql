USE QuanLyCLBSinhVien;
GO
SET QUOTED_IDENTIFIER ON;
GO
/* =====================================================================
   5 TRIGGER (lưới an toàn ở mức CSDL, kể cả khi ai đó ghi trực tiếp vào bảng)
   ===================================================================== */

-- 1. Không cho số người đăng ký vượt SoLuongToiDa của hoạt động
CREATE OR ALTER TRIGGER trg_DangKy_GioiHan ON DangKy
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1
               FROM HoatDong h
               WHERE h.MaHD IN (SELECT MaHD FROM inserted)
                 AND h.SoLuongToiDa IS NOT NULL
                 AND (SELECT COUNT(*) FROM DangKy k WHERE k.MaHD = h.MaHD AND k.TrangThai = 'DaDangKy') > h.SoLuongToiDa)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50301, N'Hoạt động đã đủ số lượng đăng ký.', 1;
    END;
END;
GO

-- 2. Giao dịch thu chi đã ghi thì không được xóa, không được sửa số tiền/loại/CLB
CREATE OR ALTER TRIGGER trg_GiaoDich_BaoVe ON GiaoDich
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM deleted) RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted) OR UPDATE(SoTien) OR UPDATE(Loai) OR UPDATE(MaCLB)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50302, N'Không được sửa hoặc xóa giao dịch đã ghi.', 1;
    END;
END;
GO

-- 3. Khi thành viên chuyển sang 'Đã rời': bỏ khỏi nhóm, hủy các đăng ký hoạt động chưa diễn ra
CREATE OR ALTER TRIGGER trg_ThanhVien_Roi ON ThanhVien
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(TrangThai) RETURN;

    UPDATE tv
    SET NgayRoi = ISNULL(tv.NgayRoi, CAST(GETDATE() AS DATE)), MaNhom = NULL
    FROM ThanhVien tv
    JOIN inserted i ON i.MaThanhVien = tv.MaThanhVien
    JOIN deleted  d ON d.MaThanhVien = i.MaThanhVien
    WHERE i.TrangThai = 'DaRoi' AND d.TrangThai <> 'DaRoi';

    UPDATE dk SET TrangThai = 'DaHuy'
    FROM DangKy dk
    JOIN inserted i ON i.MaThanhVien = dk.MaThanhVien
    JOIN deleted  d ON d.MaThanhVien = i.MaThanhVien
    JOIN HoatDong h ON h.MaHD = dk.MaHD
    WHERE i.TrangThai = 'DaRoi' AND d.TrangThai <> 'DaRoi'
      AND dk.TrangThai = 'DaDangKy' AND h.TrangThai IN ('ChoDuyet','DaDuyet');
END;
GO

-- 4. Điểm danh thành công thì thành viên "không hoạt động" được kích hoạt lại
CREATE OR ALTER TRIGGER trg_DiemDanh_KichHoat ON DiemDanh
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tv SET TrangThai = 'HoatDong'
    FROM ThanhVien tv
    WHERE tv.TrangThai = 'KhongHoatDong'
      AND tv.MaThanhVien IN (SELECT MaThanhVien FROM inserted WHERE TrangThai = 'HopLe');
END;
GO

-- 5. Phiếu mượn: người mượn phải cùng CLB với tài sản; không cho mượn tài sản đang hỏng
CREATE OR ALTER TRIGGER trg_PhieuMuon_KiemTra ON PhieuMuon
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i
               JOIN TaiSan ts ON ts.MaTaiSan = i.MaTaiSan
               JOIN ThanhVien tv ON tv.MaThanhVien = i.MaThanhVien
               WHERE ts.MaCLB <> tv.MaCLB)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50305, N'Tài sản không thuộc CLB của người mượn.', 1;
    END;
    IF EXISTS (SELECT 1 FROM inserted i JOIN TaiSan ts ON ts.MaTaiSan = i.MaTaiSan WHERE ts.TinhTrang = 'HuHong')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50306, N'Tài sản đang hỏng, không thể mượn.', 1;
    END;
END;
GO

PRINT N'Đã tạo trigger.';
GO
