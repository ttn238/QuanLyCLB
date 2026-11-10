USE QuanLyCLBSinhVien;
GO
SET NOCOUNT ON;
GO
/* =====================================================================
   KHÓA NGOẠI + CHECK
   ===================================================================== */

/* ---------- TaiKhoan ---------- */
ALTER TABLE TaiKhoan ADD
    CONSTRAINT FK_TaiKhoan_SinhVien  FOREIGN KEY (MaSV) REFERENCES SinhVien(MaSV),
    CONSTRAINT FK_TaiKhoan_GiangVien FOREIGN KEY (MaGV) REFERENCES GiangVien(MaGV),
    CONSTRAINT CK_TaiKhoan_Loai      CHECK (LoaiTaiKhoan IN ('SinhVien','GiangVien','QuanTri')),
    CONSTRAINT CK_TaiKhoan_TrangThai CHECK (TrangThai IN ('HoatDong','Khoa')),
    -- Mỗi loại tài khoản chỉ liên kết đúng một loại hồ sơ
    CONSTRAINT CK_TaiKhoan_LienKet CHECK (
        (LoaiTaiKhoan = 'SinhVien'  AND MaSV IS NOT NULL AND MaGV IS NULL) OR
        (LoaiTaiKhoan = 'GiangVien' AND MaGV IS NOT NULL AND MaSV IS NULL) OR
        (LoaiTaiKhoan = 'QuanTri'   AND MaSV IS NULL     AND MaGV IS NULL));

/* ---------- CLB, Nhom, ThanhVien ---------- */
ALTER TABLE CLB ADD
    CONSTRAINT FK_CLB_GVCoVan FOREIGN KEY (MaGVCoVan) REFERENCES GiangVien(MaGV);

ALTER TABLE Nhom ADD
    CONSTRAINT FK_Nhom_CLB FOREIGN KEY (MaCLB) REFERENCES CLB(MaCLB);

ALTER TABLE ThanhVien ADD
    CONSTRAINT FK_ThanhVien_CLB      FOREIGN KEY (MaCLB) REFERENCES CLB(MaCLB),
    CONSTRAINT FK_ThanhVien_SinhVien FOREIGN KEY (MaSV)  REFERENCES SinhVien(MaSV),
    -- Khóa ngoại kép: nhóm của thành viên bắt buộc thuộc đúng CLB của thành viên (MaNhom NULL thì không kiểm tra)
    CONSTRAINT FK_ThanhVien_Nhom_CLB FOREIGN KEY (MaNhom, MaCLB) REFERENCES Nhom(MaNhom, MaCLB),
    CONSTRAINT CK_ThanhVien_ChucVu   CHECK (ChucVu IN ('ChuNhiem','PhoChuNhiem','TruongNhom','NguoiPhuTrachThuChi','ThanhVien')),
    CONSTRAINT CK_ThanhVien_TrangThai CHECK (TrangThai IN ('HoatDong','KhongHoatDong','DaRoi')),
    CONSTRAINT CK_ThanhVien_NgayRoi  CHECK (NgayRoi IS NULL OR NgayRoi >= NgayGiaNhap);

/* ---------- Tuyển thành viên ---------- */
ALTER TABLE DotTuyen ADD
    CONSTRAINT FK_DotTuyen_CLB       FOREIGN KEY (MaCLB) REFERENCES CLB(MaCLB),
    CONSTRAINT CK_DotTuyen_TrangThai CHECK (TrangThai IN ('SapMo','DangMo','DaDong')),
    CONSTRAINT CK_DotTuyen_Ngay      CHECK (NgayKetThuc >= NgayBatDau),
    CONSTRAINT CK_DotTuyen_ChiTieu   CHECK (ChiTieu IS NULL OR ChiTieu > 0);

ALTER TABLE DonUngTuyen ADD
    CONSTRAINT FK_Don_Dot       FOREIGN KEY (MaDot)     REFERENCES DotTuyen(MaDot),
    CONSTRAINT FK_Don_SinhVien  FOREIGN KEY (MaSV)      REFERENCES SinhVien(MaSV),
    CONSTRAINT FK_Don_Nhom      FOREIGN KEY (MaNhom)    REFERENCES Nhom(MaNhom),
    CONSTRAINT FK_Don_NguoiPV   FOREIGN KEY (MaNguoiPV) REFERENCES ThanhVien(MaThanhVien),
    CONSTRAINT CK_Don_TrangThai CHECK (TrangThai IN ('DaNop','DatHoSo','KhongDatHoSo','ChoPhongVan','Dat','KhongDat','DaRut')),
    CONSTRAINT CK_Don_DiemHoSo  CHECK (DiemHoSo IS NULL OR DiemHoSo BETWEEN 0 AND 10),
    CONSTRAINT CK_Don_DiemPV    CHECK (DiemPV   IS NULL OR DiemPV   BETWEEN 0 AND 10);

/* ---------- Hoạt động ---------- */
ALTER TABLE HoatDong ADD
    CONSTRAINT FK_HoatDong_CLB FOREIGN KEY (MaCLB) REFERENCES CLB(MaCLB),
    -- Khóa ngoại kép: người đề xuất phải là thành viên của chính CLB tổ chức hoạt động
    CONSTRAINT FK_HoatDong_NguoiDeXuat_CLB FOREIGN KEY (MaNguoiDeXuat, MaCLB) REFERENCES ThanhVien(MaThanhVien, MaCLB),
    CONSTRAINT CK_HoatDong_TrangThai CHECK (TrangThai IN ('Nhap','ChoDuyet','DaDuyet','TuChoi','DangDienRa','DaKetThuc','DaHuy')),
    CONSTRAINT CK_HoatDong_ThoiGian  CHECK (ThoiGianKetThuc > ThoiGianBatDau),
    CONSTRAINT CK_HoatDong_DuToan    CHECK (DuToan >= 0),
    CONSTRAINT CK_HoatDong_SoLuong   CHECK (SoLuongToiDa IS NULL OR SoLuongToiDa > 0);

ALTER TABLE DuyetHoatDong ADD
    CONSTRAINT FK_DuyetHD_HD     FOREIGN KEY (MaHD)      REFERENCES HoatDong(MaHD),
    CONSTRAINT FK_DuyetHD_TK     FOREIGN KEY (MaTKDuyet) REFERENCES TaiKhoan(MaTK),
    CONSTRAINT CK_DuyetHD_Cap    CHECK (CapDuyet IN (1,2)),
    CONSTRAINT CK_DuyetHD_KetQua CHECK (KetQua IN ('ChoDuyet','DongY','TuChoi'));

ALTER TABLE DangKy ADD
    CONSTRAINT FK_DangKy_HD        FOREIGN KEY (MaHD)        REFERENCES HoatDong(MaHD),
    CONSTRAINT FK_DangKy_ThanhVien FOREIGN KEY (MaThanhVien) REFERENCES ThanhVien(MaThanhVien),
    CONSTRAINT CK_DangKy_TrangThai CHECK (TrangThai IN ('DaDangKy','DaHuy'));

/* ---------- Điểm danh ---------- */
ALTER TABLE PhienDiemDanh ADD
    CONSTRAINT FK_Phien_HD        FOREIGN KEY (MaHD) REFERENCES HoatDong(MaHD),
    CONSTRAINT CK_Phien_TrangThai CHECK (TrangThai IN ('Mo','Dong'));

ALTER TABLE DiemDanh ADD
    CONSTRAINT FK_DiemDanh_Phien     FOREIGN KEY (MaPhien)     REFERENCES PhienDiemDanh(MaPhien),
    CONSTRAINT FK_DiemDanh_ThanhVien FOREIGN KEY (MaThanhVien) REFERENCES ThanhVien(MaThanhVien),
    CONSTRAINT FK_DiemDanh_TKGhi     FOREIGN KEY (MaTKGhi)     REFERENCES TaiKhoan(MaTK),
    CONSTRAINT CK_DiemDanh_HinhThuc  CHECK (HinhThuc IN ('Ma','BoSung')),
    CONSTRAINT CK_DiemDanh_TrangThai CHECK (TrangThai IN ('HopLe','HuyBo')),
    -- Điểm danh bổ sung bắt buộc có lý do và người ghi
    CONSTRAINT CK_DiemDanh_BoSung CHECK (HinhThuc = 'Ma' OR (LyDoBoSung IS NOT NULL AND MaTKGhi IS NOT NULL));

/* ---------- Ngân sách & thu chi ---------- */
ALTER TABLE NganSach ADD
    CONSTRAINT FK_NganSach_CLB FOREIGN KEY (MaCLB) REFERENCES CLB(MaCLB),
    -- Khóa ngoại kép: hoạt động được xin ngân sách phải thuộc cùng CLB
    CONSTRAINT FK_NganSach_HD_CLB FOREIGN KEY (MaHD, MaCLB) REFERENCES HoatDong(MaHD, MaCLB),
    CONSTRAINT CK_NganSach_TrangThai CHECK (TrangThai IN ('ChoDuyet','ChoKetQua','DuocCap','TuChoi')),
    CONSTRAINT CK_NganSach_SoTien    CHECK (SoTienDeNghi > 0 AND (SoTienDuocCap IS NULL OR SoTienDuocCap >= 0)),
    CONSTRAINT CK_NganSach_DuocCap   CHECK (TrangThai <> 'DuocCap' OR SoTienDuocCap IS NOT NULL);

ALTER TABLE GiaoDich ADD
    CONSTRAINT FK_GiaoDich_CLB FOREIGN KEY (MaCLB)    REFERENCES CLB(MaCLB),
    CONSTRAINT FK_GiaoDich_HD_CLB FOREIGN KEY (MaHD, MaCLB) REFERENCES HoatDong(MaHD, MaCLB),
    CONSTRAINT FK_GiaoDich_TKGhi FOREIGN KEY (MaTKGhi) REFERENCES TaiKhoan(MaTK),
    CONSTRAINT CK_GiaoDich_Loai  CHECK (Loai IN ('Thu','Chi')),
    CONSTRAINT CK_GiaoDich_SoTien CHECK (SoTien > 0);

/* ---------- Tài sản ---------- */
ALTER TABLE TaiSan ADD
    CONSTRAINT FK_TaiSan_CLB       FOREIGN KEY (MaCLB) REFERENCES CLB(MaCLB),
    CONSTRAINT CK_TaiSan_TinhTrang CHECK (TinhTrang IN ('Tot','Cu','HuNhe','HuHong'));

ALTER TABLE PhieuMuon ADD
    CONSTRAINT FK_PhieuMuon_TaiSan    FOREIGN KEY (MaTaiSan)    REFERENCES TaiSan(MaTaiSan),
    CONSTRAINT FK_PhieuMuon_ThanhVien FOREIGN KEY (MaThanhVien) REFERENCES ThanhVien(MaThanhVien),
    CONSTRAINT FK_PhieuMuon_TKDuyet   FOREIGN KEY (MaTKDuyet)   REFERENCES TaiKhoan(MaTK),
    CONSTRAINT CK_PhieuMuon_TrangThai CHECK (TrangThai IN ('ChoDuyet','DaDuyet','TuChoi','DangMuon','DaTra','TraTre','Huy')),
    CONSTRAINT CK_PhieuMuon_Gap       CHECK (MucDoCanGap IN ('Thuong','Gap')),
    CONSTRAINT CK_PhieuMuon_Ngay      CHECK (HanTra >= NgayMuon),
    CONSTRAINT CK_PhieuMuon_TinhTrangTra CHECK (TinhTrangKhiTra IS NULL OR TinhTrangKhiTra IN ('Tot','Cu','HuNhe','HuHong'));

/* ---------- Thông báo ---------- */
ALTER TABLE ThongBao ADD
    CONSTRAINT FK_ThongBao_TKNhan FOREIGN KEY (MaTKNhan) REFERENCES TaiKhoan(MaTK);
GO

/* ---------- Quyền xem chi tiết thu chi ---------- */
ALTER TABLE QuyenXemChiTiet ADD
    CONSTRAINT FK_QuyenXem_ThanhVien FOREIGN KEY (MaThanhVien) REFERENCES ThanhVien(MaThanhVien),
    CONSTRAINT FK_QuyenXem_TK FOREIGN KEY (MaTK) REFERENCES TaiKhoan(MaTK),
    CONSTRAINT FK_QuyenXem_TKQuyetDinh FOREIGN KEY (MaTKQuyetDinh) REFERENCES TaiKhoan(MaTK),
    CONSTRAINT FK_QuyenXem_Nhom FOREIGN KEY (MaNhom) REFERENCES Nhom(MaNhom),
    CONSTRAINT FK_QuyenXem_HD FOREIGN KEY (MaHD) REFERENCES HoatDong(MaHD),
    CONSTRAINT CK_QuyenXem_PhamVi CHECK (
        (PhamVi = 'CLB' AND MaNhom IS NULL AND MaHD IS NULL) OR
        (PhamVi = 'Nhom' AND MaNhom IS NOT NULL AND MaHD IS NULL) OR
        (PhamVi = 'HoatDong' AND MaNhom IS NULL AND MaHD IS NOT NULL)
    ),
    CONSTRAINT CK_QuyenXem_TrangThai CHECK (TrangThai IN ('ChoDuyet','DaCap','TuChoi'));

PRINT N'Đã thêm khóa ngoại và CHECK.';
GO
