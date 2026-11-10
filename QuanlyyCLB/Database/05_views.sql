USE QuanLyCLBSinhVien;
GO
SET QUOTED_IDENTIFIER ON;
GO
/* =====================================================================
   10 VIEW (mỗi view gắn với một màn hình)
   ===================================================================== */

-- Màn hình Thành viên
CREATE OR ALTER VIEW vw_ThanhVienChiTiet
AS
SELECT tv.MaThanhVien, tv.MaCLB, tv.MaSV, sv.HoTen, sv.Email,
       n.TenNhom AS NhomHienTai,
       tv.ChucVu AS VaiTroHienTai,
       tv.NgayGiaNhap, tv.TrangThai, tv.NgayRoi,
       DATEDIFF(DAY, dbo.fn_NgayHoatDongCuoi(tv.MaThanhVien), CAST(GETDATE() AS DATE)) AS SoNgayKhongHoatDong
FROM ThanhVien tv
JOIN SinhVien sv ON sv.MaSV = tv.MaSV
LEFT JOIN Nhom n ON n.MaNhom = tv.MaNhom;
GO

-- Dashboard: quỹ của CLB
CREATE OR ALTER VIEW vw_TongThuChiCLB
AS
SELECT c.MaCLB, c.TenCLB,
       ISNULL(SUM(CASE WHEN g.Loai = 'Thu' THEN g.SoTien END), 0) AS TongThu,
       ISNULL(SUM(CASE WHEN g.Loai = 'Chi' THEN g.SoTien END), 0) AS TongChi,
       ISNULL(SUM(CASE WHEN g.Loai = 'Thu' THEN g.SoTien ELSE -g.SoTien END), 0) AS ConLai
FROM CLB c
LEFT JOIN GiaoDich g ON g.MaCLB = c.MaCLB
GROUP BY c.MaCLB, c.TenCLB;
GO

-- Màn hình Thu chi
CREATE OR ALTER VIEW vw_ThuChiChiTiet
AS
SELECT g.MaGiaoDich, g.MaCLB, g.MaHD, g.NgayGiaoDich, g.NoiDung, g.Loai, g.SoTien,
       COALESCE(sv.HoTen, gv.HoTen, tk.TenDangNhap) AS NguoiGhi
FROM GiaoDich g
JOIN TaiKhoan tk ON tk.MaTK = g.MaTKGhi
LEFT JOIN SinhVien sv ON sv.MaSV = tk.MaSV
LEFT JOIN GiangVien gv ON gv.MaGV = tk.MaGV;
GO

-- Màn hình Duyệt hoạt động / Dashboard: các lượt duyệt đang chờ
CREATE OR ALTER VIEW vw_HoatDongChoDuyet
AS
SELECT h.MaHD, h.MaCLB, c.TenCLB, h.TenHoatDong, sv.HoTen AS NguoiDeXuat,
       h.DuToan, h.ThoiGianBatDau, d.MaDuyet, d.CapDuyet, d.MaTKDuyet
FROM DuyetHoatDong d
JOIN HoatDong h ON h.MaHD = d.MaHD
JOIN CLB c ON c.MaCLB = h.MaCLB
JOIN ThanhVien tv ON tv.MaThanhVien = h.MaNguoiDeXuat
JOIN SinhVien sv ON sv.MaSV = tv.MaSV
WHERE d.KetQua = 'ChoDuyet' AND h.TrangThai = 'ChoDuyet';
GO

-- Màn hình Tài sản
CREATE OR ALTER VIEW vw_TaiSanHienTrang
AS
SELECT ts.MaTaiSan, ts.MaCLB, ts.TenTaiSan, ts.LoaiTaiSan, ts.TinhTrang,
       CASE WHEN pm.MaPhieu IS NOT NULL THEN 'DangMuon'
            WHEN ts.TinhTrang = 'HuHong' THEN 'KhongSanSang'
            ELSE 'SanSang' END AS TrangThaiMuon,
       pm.MaPhieu AS MaPhieuHienTai, pm.HanTra
FROM TaiSan ts
OUTER APPLY (SELECT TOP 1 p.MaPhieu, p.HanTra
             FROM PhieuMuon p
             WHERE p.MaTaiSan = ts.MaTaiSan AND p.TrangThai IN ('DaDuyet','DangMuon')
             ORDER BY p.MaPhieu DESC) pm;
GO

-- Màn hình Tài sản: phiếu đang mượn quá hạn
CREATE OR ALTER VIEW vw_PhieuMuonTreHan
AS
SELECT pm.MaPhieu, ts.MaCLB, sv.HoTen, pm.HanTra,
       DATEDIFF(DAY, pm.HanTra, CAST(GETDATE() AS DATE)) AS SoNgayTre,
       ts.TenTaiSan AS TaiSanChuaTra
FROM PhieuMuon pm
JOIN TaiSan ts ON ts.MaTaiSan = pm.MaTaiSan
JOIN ThanhVien tv ON tv.MaThanhVien = pm.MaThanhVien
JOIN SinhVien sv ON sv.MaSV = tv.MaSV
WHERE pm.TrangThai = 'DangMuon' AND pm.HanTra < CAST(GETDATE() AS DATE);
GO

-- Báo cáo: tham gia từng hoạt động
CREATE OR ALTER VIEW vw_ThongKeDiemDanhHoatDong
AS
SELECT h.MaHD, h.MaCLB, h.TenHoatDong, h.ThoiGianBatDau, h.TrangThai,
       (SELECT COUNT(*) FROM DangKy k WHERE k.MaHD = h.MaHD AND k.TrangThai = 'DaDangKy') AS SoDangKy,
       (SELECT COUNT(DISTINCT dd.MaThanhVien)
        FROM DiemDanh dd JOIN PhienDiemDanh p ON p.MaPhien = dd.MaPhien
        WHERE p.MaHD = h.MaHD AND dd.TrangThai = 'HopLe') AS SoDiemDanhHopLe
FROM HoatDong h;
GO

-- Lịch sử tham gia của một thành viên (lọc theo MaThanhVien)
CREATE OR ALTER VIEW vw_LichSuThamGia
AS
SELECT dd.MaThanhVien, h.MaHD, h.TenHoatDong, h.ThoiGianBatDau, dd.HinhThuc, dd.ThoiGian
FROM DiemDanh dd
JOIN PhienDiemDanh p ON p.MaPhien = dd.MaPhien
JOIN HoatDong h ON h.MaHD = p.MaHD
WHERE dd.TrangThai = 'HopLe';
GO

-- Chuông thông báo
CREATE OR ALTER VIEW vw_ThongBaoChuaDoc
AS
SELECT MaTKNhan AS MaTK, MaTB, TieuDe, NoiDung, NgayTao
FROM ThongBao
WHERE DaDoc = 0;
GO

-- Màn hình Ngân sách: tình hình sử dụng kinh phí theo hoạt động
CREATE OR ALTER VIEW vw_NganSachSuDung
AS
SELECT ns.MaNganSach, ns.MaCLB, ns.MaHD, h.TenHoatDong, ns.TrangThai,
       ns.SoTienDeNghi, ns.SoTienDuocCap,
       ISNULL((SELECT SUM(g.SoTien) FROM GiaoDich g WHERE g.MaHD = ns.MaHD AND g.Loai = 'Chi'), 0) AS DaChi,
       ISNULL(ns.SoTienDuocCap, 0)
         - ISNULL((SELECT SUM(g.SoTien) FROM GiaoDich g WHERE g.MaHD = ns.MaHD AND g.Loai = 'Chi'), 0) AS ConLai
FROM NganSach ns
LEFT JOIN HoatDong h ON h.MaHD = ns.MaHD;
GO

PRINT N'Đã tạo view.';
GO
