USE QuanLyCLBSinhVien;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
/* =====================================================================
   CHỈ MỤC
   ===================================================================== */

/* ---- UNIQUE có điều kiện: cho phép nhiều dòng NULL ---- */
CREATE UNIQUE INDEX UX_SinhVien_Email  ON SinhVien(Email)  WHERE Email IS NOT NULL;
CREATE UNIQUE INDEX UX_GiangVien_Email ON GiangVien(Email) WHERE Email IS NOT NULL;
CREATE UNIQUE INDEX UX_TaiKhoan_MaSV   ON TaiKhoan(MaSV)   WHERE MaSV IS NOT NULL;   -- mỗi sinh viên tối đa 1 tài khoản
CREATE UNIQUE INDEX UX_TaiKhoan_MaGV   ON TaiKhoan(MaGV)   WHERE MaGV IS NOT NULL;   -- mỗi giảng viên tối đa 1 tài khoản

/* ---- Quy tắc nghiệp vụ ép bằng chỉ mục ---- */
-- Mỗi hoạt động chỉ có tối đa một phiên điểm danh đang mở
CREATE UNIQUE INDEX UX_Phien_MotPhienMo ON PhienDiemDanh(MaHD) WHERE TrangThai = 'Mo';

-- Mỗi tài sản chỉ có tối đa một phiếu đang được giữ (đã duyệt hoặc đang mượn).
-- Phiếu đang giữ dùng MaTaiSan làm khóa; phiếu lịch sử dùng -MaPhieu để luôn có khóa riêng.
-- Không dùng computed column trong FILTER predicate để tránh giới hạn của filtered index trên SQL Server.
ALTER TABLE PhieuMuon ADD MaTaiSanKhoaDuyNhat AS
    (CASE WHEN TrangThai IN ('DaDuyet','DangMuon') THEN MaTaiSan ELSE -MaPhieu END) PERSISTED;
CREATE UNIQUE INDEX UX_PhieuMuon_MotPhieuDangGiu
    ON PhieuMuon(MaTaiSanKhoaDuyNhat);

/* ---- Chỉ mục tra cứu ---- */
CREATE INDEX IX_ThanhVien_CLB_TrangThai ON ThanhVien(MaCLB, TrangThai) INCLUDE (MaSV, MaNhom, ChucVu);
CREATE INDEX IX_ThanhVien_MaSV          ON ThanhVien(MaSV);
CREATE INDEX IX_DotTuyen_CLB            ON DotTuyen(MaCLB, TrangThai);
CREATE INDEX IX_Don_Dot                 ON DonUngTuyen(MaDot, TrangThai);
CREATE INDEX IX_Don_SV                  ON DonUngTuyen(MaSV);
CREATE INDEX IX_HoatDong_CLB_TrangThai  ON HoatDong(MaCLB, TrangThai, ThoiGianBatDau);
CREATE INDEX IX_DuyetHD_TK              ON DuyetHoatDong(MaTKDuyet, KetQua);
CREATE INDEX IX_DangKy_ThanhVien        ON DangKy(MaThanhVien);
CREATE INDEX IX_Phien_HD                ON PhienDiemDanh(MaHD, TrangThai);
CREATE INDEX IX_DiemDanh_ThanhVien      ON DiemDanh(MaThanhVien, ThoiGian);
CREATE INDEX IX_NganSach_CLB            ON NganSach(MaCLB, TrangThai);
CREATE INDEX IX_GiaoDich_CLB_Ngay       ON GiaoDich(MaCLB, NgayGiaoDich) INCLUDE (Loai, SoTien, MaHD);
CREATE INDEX IX_TaiSan_CLB              ON TaiSan(MaCLB);
CREATE INDEX IX_PhieuMuon_ThanhVien     ON PhieuMuon(MaThanhVien, TrangThai);
CREATE INDEX IX_PhieuMuon_TaiSan        ON PhieuMuon(MaTaiSan, TrangThai);
CREATE INDEX IX_ThongBao_TK             ON ThongBao(MaTKNhan, DaDoc, NgayTao);
GO

PRINT N'Đã tạo chỉ mục.';
GO
