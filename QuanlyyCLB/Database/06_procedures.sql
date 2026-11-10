USE QuanLyCLBSinhVien;
GO

/* ================= QUYỀN XEM CHI TIẾT THU CHI ================= */
CREATE OR ALTER PROCEDURE sp_XinQuyenXemChiTiet
    @MaThanhVien INT, @PhamVi VARCHAR(12), @MaNhom INT = NULL, @MaHD INT = NULL,
    @LyDo NVARCHAR(500), @MaQuyenXem INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @maTK INT;
    SELECT @maCLB = MaCLB FROM ThanhVien WHERE MaThanhVien=@MaThanhVien AND TrangThai<>'DaRoi';
    SELECT @maTK = MaTK FROM TaiKhoan tk JOIN ThanhVien tv ON tv.MaSV=tk.MaSV WHERE tv.MaThanhVien=@MaThanhVien;
    IF @maCLB IS NULL OR @maTK IS NULL THROW 50400, N'Tài khoản không phải thành viên hợp lệ.', 1;
    IF @PhamVi NOT IN ('CLB','Nhom','HoatDong') THROW 50401, N'Phạm vi xin quyền không hợp lệ.', 1;
    IF @PhamVi='Nhom' AND NOT EXISTS (SELECT 1 FROM Nhom WHERE MaNhom=@MaNhom AND MaCLB=@maCLB) THROW 50402, N'Nhóm không thuộc CLB.', 1;
    IF @PhamVi='HoatDong' AND NOT EXISTS (SELECT 1 FROM HoatDong WHERE MaHD=@MaHD AND MaCLB=@maCLB) THROW 50403, N'Hoạt động không thuộc CLB.', 1;
    IF NULLIF(LTRIM(RTRIM(@LyDo)), '') IS NULL THROW 50404, N'Phải nhập lý do xin quyền.', 1;
    IF EXISTS (SELECT 1 FROM QuyenXemChiTiet WHERE MaTK=@maTK AND PhamVi=@PhamVi AND ISNULL(MaNhom,0)=ISNULL(@MaNhom,0) AND ISNULL(MaHD,0)=ISNULL(@MaHD,0) AND TrangThai IN ('ChoDuyet','DaCap'))
        THROW 50405, N'Bạn đã có yêu cầu hoặc quyền xem tương ứng.', 1;
    INSERT QuyenXemChiTiet(MaThanhVien,MaTK,PhamVi,MaNhom,MaHD,LyDoYeuCau)
    VALUES(@MaThanhVien,@maTK,@PhamVi,
           CASE WHEN @PhamVi='Nhom' THEN @MaNhom ELSE NULL END,
           CASE WHEN @PhamVi='HoatDong' THEN @MaHD ELSE NULL END,
           @LyDo);
    SET @MaQuyenXem=SCOPE_IDENTITY();

    DECLARE @dsCap VARCHAR(MAX);
    SELECT @dsCap = STRING_AGG(CAST(tk.MaTK AS VARCHAR(20)), ',')
    FROM TaiKhoan tk JOIN ThanhVien tv ON tv.MaSV=tk.MaSV
    WHERE tv.MaCLB=@maCLB AND tv.TrangThai<>'DaRoi'
      AND (tv.ChucVu IN ('ChuNhiem','NguoiPhuTrachThuChi') OR (@PhamVi='Nhom' AND tv.MaNhom=@MaNhom AND tv.ChucVu='TruongNhom'));
    EXEC sp_TaoThongBao @dsCap, N'Yêu cầu xem chi tiết thu chi', N'Có yêu cầu mới cần xem xét.';
END;
GO

CREATE OR ALTER PROCEDURE sp_QuyetDinhQuyenXem @MaQuyenXem INT, @MaTK INT, @DongY BIT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @phamVi VARCHAR(12), @maNhom INT, @maTV INT;
    SELECT @maCLB=tv.MaCLB,@phamVi=q.PhamVi,@maNhom=q.MaNhom,@maTV=q.MaThanhVien
    FROM QuyenXemChiTiet q JOIN ThanhVien tv ON tv.MaThanhVien=q.MaThanhVien
    WHERE q.MaQuyenXem=@MaQuyenXem AND q.TrangThai='ChoDuyet';
    IF @maCLB IS NULL THROW 50410, N'Yêu cầu không tồn tại hoặc đã được xử lý.', 1;
    IF dbo.fn_LaQuanLyCLB(@MaTK,@maCLB)=0 AND NOT EXISTS (
        SELECT 1 FROM ThanhVien tv JOIN TaiKhoan tk ON tk.MaSV=tv.MaSV
        WHERE tk.MaTK=@MaTK AND tv.MaCLB=@maCLB AND tv.MaNhom=@maNhom AND tv.ChucVu='TruongNhom' AND tv.TrangThai<>'DaRoi')
        THROW 50411, N'Bạn không có quyền quyết định yêu cầu này.', 1;
    UPDATE QuyenXemChiTiet SET TrangThai=CASE WHEN @DongY=1 THEN 'DaCap' ELSE 'TuChoi' END,
        MaTKQuyetDinh=@MaTK, NgayQuyetDinh=SYSDATETIME() WHERE MaQuyenXem=@MaQuyenXem;
END;
GO
SET QUOTED_IDENTIFIER ON;
GO
/* =====================================================================
   32 STORED PROCEDURE
   Quy ước: lỗi nghiệp vụ dùng THROW 50xxx (web hiển thị message cho người dùng).
            Thao tác nhiều bước dùng transaction + SET XACT_ABORT ON.
            Thao tác của người quản lý nhận @MaTK để proc tự kiểm tra quyền theo CLB.
   ===================================================================== */

/* ================= TIỆN ÍCH ================= */

-- Gửi một thông báo cho nhiều tài khoản. @DsMaTK = danh sách MaTK cách nhau dấu phẩy (NULL/rỗng thì bỏ qua)
CREATE OR ALTER PROCEDURE sp_TaoThongBao
    @DsMaTK  VARCHAR(MAX),
    @TieuDe  NVARCHAR(200),
    @NoiDung NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @DsMaTK IS NULL OR LTRIM(RTRIM(@DsMaTK)) = '' RETURN;
    INSERT ThongBao (MaTKNhan, TieuDe, NoiDung)
    SELECT DISTINCT TRY_CAST(LTRIM(RTRIM(value)) AS INT), @TieuDe, @NoiDung
    FROM STRING_SPLIT(@DsMaTK, ',')
    WHERE TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;
END;
GO

/* ================= ĐĂNG NHẬP & THÔNG BÁO ================= */

-- Trả 3 bảng: (0) tài khoản; (1) các CLB mà tài khoản là thành viên, TenVaiTro = chức vụ; (2) CLB mà giảng viên cố vấn
CREATE OR ALTER PROCEDURE sp_LayThongTinDangNhap @TenDangNhap VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT tk.MaTK, tk.TenDangNhap, tk.MatKhauHash, tk.LoaiTaiKhoan, tk.TrangThai, tk.MaSV, tk.MaGV,
           COALESCE(sv.HoTen, gv.HoTen, N'Quản trị hệ thống') AS HoTen
    FROM TaiKhoan tk
    LEFT JOIN SinhVien sv ON sv.MaSV = tk.MaSV
    LEFT JOIN GiangVien gv ON gv.MaGV = tk.MaGV
    WHERE tk.TenDangNhap = @TenDangNhap;

    SELECT tv.MaCLB, tv.MaThanhVien, tv.ChucVu AS TenVaiTro, tv.MaNhom
    FROM TaiKhoan tk
    JOIN ThanhVien tv ON tv.MaSV = tk.MaSV AND tv.TrangThai <> 'DaRoi'
    WHERE tk.TenDangNhap = @TenDangNhap
    ORDER BY CASE tv.ChucVu WHEN 'ChuNhiem' THEN 1 WHEN 'NguoiPhuTrachThuChi' THEN 2 ELSE 3 END, tv.MaCLB;

    SELECT c.MaCLB
    FROM TaiKhoan tk
    JOIN CLB c ON c.MaGVCoVan = tk.MaGV
    WHERE tk.TenDangNhap = @TenDangNhap
    ORDER BY c.MaCLB;
END;
GO

CREATE OR ALTER PROCEDURE sp_GhiNhanDangNhap @MaTK INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE TaiKhoan SET LanDangNhapCuoi = SYSDATETIME() WHERE MaTK = @MaTK;
END;
GO

CREATE OR ALTER PROCEDURE sp_DanhDauDaDoc @MaNhan INT, @MaTK INT   -- @MaNhan = MaTB
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ThongBao SET DaDoc = 1 WHERE MaTB = @MaNhan AND MaTKNhan = @MaTK;
END;
GO

/* ================= TUYỂN THÀNH VIÊN ================= */

CREATE OR ALTER PROCEDURE sp_NopDon
    @MaDot INT, @MaSV VARCHAR(20), @MaNhomNguyenVong INT = NULL, @GioiThieu NVARCHAR(1000) = NULL,
    @MaDon INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @tt VARCHAR(10), @bd DATE, @kt DATE;
    SELECT @maCLB = MaCLB, @tt = TrangThai, @bd = NgayBatDau, @kt = NgayKetThuc FROM DotTuyen WHERE MaDot = @MaDot;

    IF @maCLB IS NULL THROW 50010, N'Đợt tuyển không tồn tại.', 1;
    IF @tt <> 'DangMo' OR CAST(GETDATE() AS DATE) NOT BETWEEN @bd AND @kt THROW 50011, N'Đợt tuyển hiện không nhận đơn.', 1;
    IF NOT EXISTS (SELECT 1 FROM SinhVien WHERE MaSV = @MaSV) THROW 50012, N'Không tìm thấy sinh viên.', 1;
    IF EXISTS (SELECT 1 FROM ThanhVien WHERE MaCLB = @maCLB AND MaSV = @MaSV AND TrangThai <> 'DaRoi')
        THROW 50013, N'Bạn đã là thành viên của CLB này.', 1;
    IF EXISTS (SELECT 1 FROM DonUngTuyen WHERE MaDot = @MaDot AND MaSV = @MaSV)
        THROW 50014, N'Bạn đã nộp đơn cho đợt tuyển này.', 1;
    IF @MaNhomNguyenVong IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Nhom WHERE MaNhom = @MaNhomNguyenVong AND MaCLB = @maCLB)
        THROW 50015, N'Nhóm nguyện vọng không thuộc CLB đang tuyển.', 1;

    INSERT DonUngTuyen (MaDot, MaSV, MaNhom, GioiThieu) VALUES (@MaDot, @MaSV, @MaNhomNguyenVong, @GioiThieu);
    SET @MaDon = SCOPE_IDENTITY();

    DECLARE @ds VARCHAR(20) = CAST(dbo.fn_TaiKhoanChuNhiem(@maCLB) AS VARCHAR(20));
    EXEC sp_TaoThongBao @ds, N'Có đơn ứng tuyển mới', N'Một sinh viên vừa nộp đơn vào đợt tuyển của CLB.';
END;
GO

-- Chấm hồ sơ. @MaTK = người chấm (phải là quản lý CLB)
CREATE OR ALTER PROCEDURE sp_ChamDon
    @MaDon INT, @MaTK INT, @Diem DECIMAL(4,2), @Dat BIT, @GhiChu NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @tt VARCHAR(15), @maSV VARCHAR(20);
    SELECT @maCLB = dt.MaCLB, @tt = d.TrangThai, @maSV = d.MaSV
    FROM DonUngTuyen d JOIN DotTuyen dt ON dt.MaDot = d.MaDot WHERE d.MaDon = @MaDon;

    IF @maCLB IS NULL THROW 50020, N'Đơn không tồn tại.', 1;
    IF dbo.fn_LaQuanLyCLB(@MaTK, @maCLB) = 0 THROW 50021, N'Bạn không có quyền chấm đơn của CLB này.', 1;
    IF @tt <> 'DaNop' THROW 50022, N'Đơn này đã được chấm hồ sơ.', 1;
    IF @Diem IS NULL OR @Diem NOT BETWEEN 0 AND 10 THROW 50023, N'Điểm hồ sơ phải từ 0 đến 10.', 1;

    UPDATE DonUngTuyen
    SET DiemHoSo = @Diem, GhiChuHoSo = @GhiChu,
        TrangThai = CASE WHEN @Dat = 1 THEN 'DatHoSo' ELSE 'KhongDatHoSo' END
    WHERE MaDon = @MaDon;

    DECLARE @ds VARCHAR(20) = CAST((SELECT TOP 1 MaTK FROM TaiKhoan WHERE MaSV = @maSV) AS VARCHAR(20));
    EXEC sp_TaoThongBao @ds, N'Kết quả xét hồ sơ',
        N'Hồ sơ ứng tuyển của bạn đã được chấm. Vào mục Tuyển thành viên để xem kết quả.';
END;
GO

CREATE OR ALTER PROCEDURE sp_LenLichPhongVan
    @MaDon INT, @MaTK INT, @ThoiGian DATETIME2(0), @DiaDiem NVARCHAR(200), @MaNguoiPV INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @tt VARCHAR(15), @maSV VARCHAR(20);
    SELECT @maCLB = dt.MaCLB, @tt = d.TrangThai, @maSV = d.MaSV
    FROM DonUngTuyen d JOIN DotTuyen dt ON dt.MaDot = d.MaDot WHERE d.MaDon = @MaDon;

    IF @maCLB IS NULL THROW 50030, N'Đơn không tồn tại.', 1;
    IF dbo.fn_LaQuanLyCLB(@MaTK, @maCLB) = 0 THROW 50031, N'Bạn không có quyền lên lịch phỏng vấn của CLB này.', 1;
    IF @tt NOT IN ('DatHoSo','ChoPhongVan') THROW 50032, N'Chỉ lên lịch cho đơn đã đạt hồ sơ.', 1;
    IF @ThoiGian <= SYSDATETIME() THROW 50033, N'Thời gian phỏng vấn phải ở tương lai.', 1;
    IF NULLIF(LTRIM(RTRIM(@DiaDiem)), '') IS NULL THROW 50034, N'Chưa nhập địa điểm phỏng vấn.', 1;
    IF NOT EXISTS (SELECT 1 FROM ThanhVien WHERE MaThanhVien = @MaNguoiPV AND MaCLB = @maCLB AND TrangThai <> 'DaRoi')
        THROW 50035, N'Người phỏng vấn phải là thành viên của CLB.', 1;

    UPDATE DonUngTuyen
    SET ThoiGianPV = @ThoiGian, DiaDiemPV = @DiaDiem, MaNguoiPV = @MaNguoiPV, TrangThai = 'ChoPhongVan'
    WHERE MaDon = @MaDon;

    DECLARE @ds VARCHAR(20) = CAST((SELECT TOP 1 MaTK FROM TaiKhoan WHERE MaSV = @maSV) AS VARCHAR(20));
    EXEC sp_TaoThongBao @ds, N'Lịch phỏng vấn', N'Bạn có lịch phỏng vấn mới. Vào mục Tuyển thành viên để xem thời gian và địa điểm.';
END;
GO

-- Chốt kết quả: đạt thì tự tạo (hoặc kích hoạt lại) thành viên
CREATE OR ALTER PROCEDURE sp_ChotKetQuaPhongVan
    @MaDon INT, @Diem DECIMAL(4,2), @NhanXet NVARCHAR(500) = NULL, @KetQua VARCHAR(10), @MaTKThucHien INT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @tt VARCHAR(15), @maSV VARCHAR(20), @maNhom INT, @maDot INT, @chiTieu INT;
    SELECT @maCLB = dt.MaCLB, @tt = d.TrangThai, @maSV = d.MaSV, @maNhom = d.MaNhom, @maDot = d.MaDot, @chiTieu = dt.ChiTieu
    FROM DonUngTuyen d JOIN DotTuyen dt ON dt.MaDot = d.MaDot WHERE d.MaDon = @MaDon;

    IF @maCLB IS NULL THROW 50040, N'Đơn không tồn tại.', 1;
    IF dbo.fn_LaQuanLyCLB(@MaTKThucHien, @maCLB) = 0 THROW 50041, N'Bạn không có quyền chốt kết quả của CLB này.', 1;
    IF @tt <> 'ChoPhongVan' THROW 50042, N'Đơn chưa có lịch phỏng vấn hoặc đã được chốt.', 1;
    IF @KetQua NOT IN ('Dat','KhongDat') THROW 50043, N'Kết quả không hợp lệ.', 1;
    IF @Diem IS NULL OR @Diem NOT BETWEEN 0 AND 10 THROW 50044, N'Điểm phỏng vấn phải từ 0 đến 10.', 1;

    BEGIN TRAN;
    IF @KetQua = 'Dat'
    BEGIN
        IF @chiTieu IS NOT NULL AND (SELECT COUNT(*) FROM DonUngTuyen WHERE MaDot = @maDot AND TrangThai = 'Dat') >= @chiTieu
            THROW 50045, N'Đợt tuyển đã đủ chỉ tiêu.', 1;

        IF EXISTS (SELECT 1 FROM ThanhVien WHERE MaCLB = @maCLB AND MaSV = @maSV)
            UPDATE ThanhVien
            SET TrangThai = 'HoatDong', NgayRoi = NULL, LyDoRoi = NULL, ChucVu = 'ThanhVien',
                NgayGiaNhap = CAST(GETDATE() AS DATE), MaNhom = @maNhom
            WHERE MaCLB = @maCLB AND MaSV = @maSV;
        ELSE
            INSERT ThanhVien (MaCLB, MaSV, MaNhom, ChucVu) VALUES (@maCLB, @maSV, @maNhom, 'ThanhVien');
    END;

    UPDATE DonUngTuyen SET DiemPV = @Diem, NhanXetPV = @NhanXet, TrangThai = @KetQua WHERE MaDon = @MaDon;
    COMMIT;

    DECLARE @ds VARCHAR(20) = CAST((SELECT TOP 1 MaTK FROM TaiKhoan WHERE MaSV = @maSV) AS VARCHAR(20));
    EXEC sp_TaoThongBao @ds, N'Kết quả phỏng vấn',
        N'Kết quả phỏng vấn của bạn đã có. Vào mục Tuyển thành viên để xem chi tiết.';
END;
GO

/* ================= THÀNH VIÊN ================= */

CREATE OR ALTER PROCEDURE sp_ThanhVienRoiCLB @MaThanhVien INT, @MaTK INT, @LyDo NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @tt VARCHAR(15), @cv VARCHAR(25);
    SELECT @maCLB = MaCLB, @tt = TrangThai, @cv = ChucVu FROM ThanhVien WHERE MaThanhVien = @MaThanhVien;

    IF @maCLB IS NULL THROW 50060, N'Thành viên không tồn tại.', 1;
    IF dbo.fn_LaQuanLyCLB(@MaTK, @maCLB) = 0 THROW 50061, N'Bạn không có quyền với CLB này.', 1;
    IF @tt = 'DaRoi' THROW 50062, N'Thành viên này đã rời CLB.', 1;
    IF @cv = 'ChuNhiem' THROW 50063, N'Không thể cho Chủ nhiệm rời CLB. Hãy chuyển chức vụ trước.', 1;

    UPDATE ThanhVien
    SET TrangThai = 'DaRoi', NgayRoi = CAST(GETDATE() AS DATE), LyDoRoi = @LyDo
    WHERE MaThanhVien = @MaThanhVien;   -- trigger trg_ThanhVien_Roi dọn nhóm và đăng ký
END;
GO

-- Đánh dấu "không hoạt động" các thành viên quá @SoNgay ngày vắng mặt; trả danh sách vừa đổi
CREATE OR ALTER PROCEDURE sp_RaSoatThanhVienKhongHoatDong @MaCLB INT, @MaTK INT, @SoNgay INT = 180
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF dbo.fn_LaQuanLyCLB(@MaTK, @MaCLB) = 0 THROW 50070, N'Bạn không có quyền với CLB này.', 1;

    DECLARE @ds TABLE (MaThanhVien INT, MaSV VARCHAR(20), HoTen NVARCHAR(100), SoNgayKhongHoatDong INT);
    INSERT @ds
    SELECT MaThanhVien, MaSV, HoTen, SoNgayKhongHoatDong
    FROM vw_ThanhVienChiTiet
    WHERE MaCLB = @MaCLB AND TrangThai = 'HoatDong' AND VaiTroHienTai NOT IN ('ChuNhiem','NguoiPhuTrachThuChi') AND SoNgayKhongHoatDong > @SoNgay;

    BEGIN TRAN;
    UPDATE tv SET TrangThai = 'KhongHoatDong'
    FROM ThanhVien tv JOIN @ds d ON d.MaThanhVien = tv.MaThanhVien;

    INSERT ThongBao (MaTKNhan, TieuDe, NoiDung)
    SELECT tk.MaTK, N'Bạn bị chuyển sang không hoạt động',
           N'Bạn đã lâu không tham gia hoạt động của CLB. Hãy tham gia một hoạt động để kích hoạt lại.'
    FROM @ds d JOIN TaiKhoan tk ON tk.MaSV = d.MaSV;
    COMMIT;

    SELECT MaThanhVien, MaSV, HoTen, SoNgayKhongHoatDong FROM @ds;
END;
GO

/* ================= HOẠT ĐỘNG ================= */

-- @Nhap = 1: lưu nháp. @Nhap = 0: gửi duyệt, tự sinh các lượt duyệt:
--   cấp 1 = Chủ nhiệm (tự đồng ý nếu chính Chủ nhiệm đề xuất); cấp 2 = giảng viên cố vấn (chỉ khi có dự toán > 0).
CREATE OR ALTER PROCEDURE sp_DeXuatHoatDong
    @MaThanhVienDeXuat INT, @TenHoatDong NVARCHAR(200), @MoTa NVARCHAR(1000) = NULL,
    @ThoiGianBatDau DATETIME2(0), @ThoiGianKetThuc DATETIME2(0), @DiaDiem NVARCHAR(200) = NULL,
    @SoLuongToiDa INT = NULL, @DuToan DECIMAL(15,2) = 0, @Nhap BIT = 0,
    @MaHD INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @cv VARCHAR(25), @tt VARCHAR(15);
    SELECT @maCLB = MaCLB, @cv = ChucVu, @tt = TrangThai FROM ThanhVien WHERE MaThanhVien = @MaThanhVienDeXuat;

    IF @maCLB IS NULL OR @tt = 'DaRoi' THROW 50080, N'Người đề xuất không hợp lệ.', 1;
    IF @cv NOT IN ('ChuNhiem','NguoiPhuTrachThuChi') THROW 50081, N'Chỉ Chủ nhiệm hoặc Phụ trách mới được đề xuất hoạt động.', 1;
    IF NULLIF(LTRIM(RTRIM(@TenHoatDong)), '') IS NULL THROW 50082, N'Chưa nhập tên hoạt động.', 1;
    IF @ThoiGianKetThuc <= @ThoiGianBatDau THROW 50083, N'Thời gian kết thúc phải sau thời gian bắt đầu.', 1;
    IF @Nhap = 0 AND @ThoiGianBatDau <= SYSDATETIME() THROW 50084, N'Thời gian bắt đầu phải ở tương lai.', 1;
    SET @DuToan = ISNULL(@DuToan, 0);
    IF @DuToan < 0 THROW 50085, N'Dự toán không được âm.', 1;

    BEGIN TRAN;
    INSERT HoatDong (MaCLB, MaNguoiDeXuat, TenHoatDong, MoTa, DiaDiem, ThoiGianBatDau, ThoiGianKetThuc,
                     SoLuongToiDa, DuToan, TrangThai)
    VALUES (@maCLB, @MaThanhVienDeXuat, @TenHoatDong, @MoTa, @DiaDiem, @ThoiGianBatDau, @ThoiGianKetThuc,
            @SoLuongToiDa, @DuToan, CASE WHEN @Nhap = 1 THEN 'Nhap' ELSE 'ChoDuyet' END);
    SET @MaHD = SCOPE_IDENTITY();

    IF @Nhap = 0
    BEGIN
        DECLARE @tkCN INT = dbo.fn_TaiKhoanChuNhiem(@maCLB), @tkGV INT = dbo.fn_TaiKhoanCoVan(@maCLB);
        IF @tkCN IS NULL THROW 50086, N'CLB chưa có Chủ nhiệm để duyệt.', 1;

        INSERT DuyetHoatDong (MaHD, CapDuyet, MaTKDuyet, KetQua, NgayDuyet)
        VALUES (@MaHD, 1, @tkCN,
                CASE WHEN @cv = 'ChuNhiem' THEN 'DongY' ELSE 'ChoDuyet' END,
                CASE WHEN @cv = 'ChuNhiem' THEN SYSDATETIME() END);

        IF @DuToan > 0
        BEGIN
            IF @tkGV IS NULL THROW 50087, N'CLB chưa có giảng viên cố vấn (có tài khoản) để duyệt hoạt động có kinh phí.', 1;
            INSERT DuyetHoatDong (MaHD, CapDuyet, MaTKDuyet) VALUES (@MaHD, 2, @tkGV);
        END;

        IF NOT EXISTS (SELECT 1 FROM DuyetHoatDong WHERE MaHD = @MaHD AND KetQua = 'ChoDuyet')
            UPDATE HoatDong SET TrangThai = 'DaDuyet' WHERE MaHD = @MaHD;
        ELSE
        BEGIN
            DECLARE @ds VARCHAR(MAX) = (SELECT STRING_AGG(CAST(MaTKDuyet AS VARCHAR(20)), ',')
                                        FROM DuyetHoatDong WHERE MaHD = @MaHD AND KetQua = 'ChoDuyet');
            EXEC sp_TaoThongBao @ds, N'Hoạt động chờ duyệt', N'Có hoạt động mới đề xuất cần bạn xem xét.';
        END;
    END;
    COMMIT;
END;
GO

CREATE OR ALTER PROCEDURE sp_DuyetHoatDong
    @MaDuyet INT, @MaTK INT, @KetQua VARCHAR(10), @LyDo NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maHD INT, @tkDuyet INT, @kq VARCHAR(10), @ttHD VARCHAR(12), @ten NVARCHAR(200);
    SELECT @maHD = d.MaHD, @tkDuyet = d.MaTKDuyet, @kq = d.KetQua, @ttHD = h.TrangThai, @ten = h.TenHoatDong
    FROM DuyetHoatDong d JOIN HoatDong h ON h.MaHD = d.MaHD WHERE d.MaDuyet = @MaDuyet;

    IF @maHD IS NULL THROW 50090, N'Lượt duyệt không tồn tại.', 1;
    IF @tkDuyet <> @MaTK THROW 50091, N'Bạn không phải người được giao duyệt hoạt động này.', 1;
    IF @kq <> 'ChoDuyet' THROW 50092, N'Lượt duyệt này đã được xử lý.', 1;
    IF @ttHD <> 'ChoDuyet' THROW 50093, N'Hoạt động không còn ở trạng thái chờ duyệt.', 1;
    IF @KetQua NOT IN ('DongY','TuChoi') THROW 50094, N'Kết quả duyệt không hợp lệ.', 1;

    BEGIN TRAN;
    UPDATE DuyetHoatDong
    SET KetQua = @KetQua, NgayDuyet = SYSDATETIME(),
        LyDo = CASE WHEN @KetQua = 'TuChoi' THEN ISNULL(NULLIF(LTRIM(RTRIM(@LyDo)), ''), N'Không nêu lý do') ELSE @LyDo END
    WHERE MaDuyet = @MaDuyet;

    IF @KetQua = 'TuChoi'
        UPDATE HoatDong SET TrangThai = 'TuChoi' WHERE MaHD = @maHD;
    ELSE IF NOT EXISTS (SELECT 1 FROM DuyetHoatDong WHERE MaHD = @maHD AND KetQua = 'ChoDuyet')
        UPDATE HoatDong SET TrangThai = 'DaDuyet' WHERE MaHD = @maHD;
    COMMIT;

    DECLARE @ds VARCHAR(20) = CAST((SELECT TOP 1 tk.MaTK
                                    FROM HoatDong h
                                    JOIN ThanhVien tv ON tv.MaThanhVien = h.MaNguoiDeXuat
                                    JOIN TaiKhoan tk ON tk.MaSV = tv.MaSV
                                    WHERE h.MaHD = @maHD) AS VARCHAR(20));
    EXEC sp_TaoThongBao @ds, N'Cập nhật duyệt hoạt động', N'Hoạt động bạn đề xuất vừa có kết quả duyệt mới.';
END;
GO

CREATE OR ALTER PROCEDURE sp_DangKyHoatDong @MaThanhVien INT, @MaHD INT, @MaDangKy INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @clbHD INT, @ttHD VARCHAR(12), @max INT, @kt DATETIME2(0);
    SELECT @clbHD = MaCLB, @ttHD = TrangThai, @max = SoLuongToiDa, @kt = ThoiGianKetThuc FROM HoatDong WHERE MaHD = @MaHD;
    DECLARE @clbTV INT, @ttTV VARCHAR(15);
    SELECT @clbTV = MaCLB, @ttTV = TrangThai FROM ThanhVien WHERE MaThanhVien = @MaThanhVien;

    IF @clbHD IS NULL THROW 50100, N'Hoạt động không tồn tại.', 1;
    IF @clbTV IS NULL OR @clbTV <> @clbHD OR @ttTV = 'DaRoi' THROW 50101, N'Bạn không phải thành viên của CLB tổ chức hoạt động này.', 1;
    IF @ttHD <> 'DaDuyet' THROW 50102, N'Hoạt động chưa mở đăng ký.', 1;
    IF @kt <= SYSDATETIME() THROW 50103, N'Hoạt động đã kết thúc.', 1;

    BEGIN TRAN;
    IF @max IS NOT NULL AND (SELECT COUNT(*) FROM DangKy WITH (UPDLOCK, HOLDLOCK) WHERE MaHD = @MaHD AND TrangThai = 'DaDangKy') >= @max
        THROW 50104, N'Hoạt động đã đủ số lượng đăng ký.', 1;

    IF EXISTS (SELECT 1 FROM DangKy WHERE MaHD = @MaHD AND MaThanhVien = @MaThanhVien)
    BEGIN
        IF EXISTS (SELECT 1 FROM DangKy WHERE MaHD = @MaHD AND MaThanhVien = @MaThanhVien AND TrangThai = 'DaDangKy')
            THROW 50105, N'Bạn đã đăng ký hoạt động này rồi.', 1;
        UPDATE DangKy SET TrangThai = 'DaDangKy', NgayDangKy = SYSDATETIME()
        WHERE MaHD = @MaHD AND MaThanhVien = @MaThanhVien;
        SELECT @MaDangKy = MaDangKy FROM DangKy WHERE MaHD = @MaHD AND MaThanhVien = @MaThanhVien;
    END
    ELSE
    BEGIN
        INSERT DangKy (MaHD, MaThanhVien) VALUES (@MaHD, @MaThanhVien);
        SET @MaDangKy = SCOPE_IDENTITY();
    END;
    COMMIT;
END;
GO

CREATE OR ALTER PROCEDURE sp_HuyDangKy @MaThanhVien INT, @MaHD INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM DangKy WHERE MaHD = @MaHD AND MaThanhVien = @MaThanhVien AND TrangThai = 'DaDangKy')
        THROW 50110, N'Bạn chưa đăng ký hoạt động này.', 1;
    IF NOT EXISTS (SELECT 1 FROM HoatDong WHERE MaHD = @MaHD AND TrangThai = 'DaDuyet')
        THROW 50111, N'Hoạt động đã bắt đầu hoặc kết thúc, không thể hủy đăng ký.', 1;
    UPDATE DangKy SET TrangThai = 'DaHuy' WHERE MaHD = @MaHD AND MaThanhVien = @MaThanhVien;
END;
GO

/* ================= ĐIỂM DANH ================= */

-- Mở phiên (nếu đã có phiên mở thì dùng lại). Chuyển hoạt động sang 'Đang diễn ra' và sinh mã đầu tiên.
CREATE OR ALTER PROCEDURE sp_MoPhienDiemDanh
    @MaHD INT, @MaTK INT, @MaPhien INT OUTPUT, @GiaTriMa VARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @tt VARCHAR(12);
    SELECT @maCLB = MaCLB, @tt = TrangThai FROM HoatDong WHERE MaHD = @MaHD;

    IF @maCLB IS NULL THROW 50120, N'Hoạt động không tồn tại.', 1;
    IF dbo.fn_LaQuanLyCLB(@MaTK, @maCLB) = 0 THROW 50121, N'Bạn không có quyền mở điểm danh hoạt động này.', 1;
    IF @tt NOT IN ('DaDuyet','DangDienRa') THROW 50122, N'Chỉ mở điểm danh cho hoạt động đã duyệt hoặc đang diễn ra.', 1;

    SELECT TOP 1 @MaPhien = MaPhien FROM PhienDiemDanh WHERE MaHD = @MaHD AND TrangThai = 'Mo';
    IF @MaPhien IS NOT NULL
    BEGIN
        DECLARE @conLai INT;
        EXEC sp_LayMaDiemDanh @MaHD = @MaHD, @GiaTriMa = @GiaTriMa OUTPUT, @ConLai = @conLai OUTPUT;
        RETURN;
    END;

    BEGIN TRAN;
    SET @GiaTriMa = RIGHT('000000' + CAST(ABS(CHECKSUM(NEWID())) % 1000000 AS VARCHAR(6)), 6);
    INSERT PhienDiemDanh (MaHD, MaCode, HetHanLuc)
    VALUES (@MaHD, @GiaTriMa, DATEADD(SECOND, 120, SYSDATETIME()));
    SET @MaPhien = SCOPE_IDENTITY();
    IF @tt = 'DaDuyet' UPDATE HoatDong SET TrangThai = 'DangDienRa' WHERE MaHD = @MaHD;
    COMMIT;
END;
GO

-- Lấy mã đang hiệu lực của phiên đang mở; hết hạn thì tự sinh mã mới. Trả số giây còn lại (đồng hồ của SQL Server).
CREATE OR ALTER PROCEDURE sp_LayMaDiemDanh @MaHD INT, @GiaTriMa VARCHAR(20) OUTPUT, @ConLai INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @p INT = (SELECT TOP 1 MaPhien FROM PhienDiemDanh WHERE MaHD = @MaHD AND TrangThai = 'Mo');
    IF @p IS NULL BEGIN SET @GiaTriMa = '------'; SET @ConLai = 0; RETURN; END;

    UPDATE PhienDiemDanh
    SET MaCode = RIGHT('000000' + CAST(ABS(CHECKSUM(NEWID())) % 1000000 AS VARCHAR(6)), 6),
        HetHanLuc = DATEADD(SECOND, 120, SYSDATETIME())
    WHERE MaPhien = @p AND (HetHanLuc IS NULL OR HetHanLuc <= SYSDATETIME());

    SELECT @GiaTriMa = MaCode, @ConLai = DATEDIFF(SECOND, SYSDATETIME(), HetHanLuc)
    FROM PhienDiemDanh WHERE MaPhien = @p;
    IF @ConLai < 0 SET @ConLai = 0;
END;
GO

CREATE OR ALTER PROCEDURE sp_DongPhienDiemDanh @MaPhien INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE PhienDiemDanh SET TrangThai = 'Dong', ThoiGianDong = SYSDATETIME(), HetHanLuc = NULL
    WHERE MaPhien = @MaPhien AND TrangThai = 'Mo';
    IF @@ROWCOUNT = 0 THROW 50130, N'Không có phiên điểm danh nào đang mở.', 1;
END;
GO

CREATE OR ALTER PROCEDURE sp_DiemDanhBangMa
    @MaThanhVien INT, @MaHD INT, @GiaTriMa VARCHAR(20), @MaDiemDanh INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @p INT, @code VARCHAR(10), @het DATETIME2(0);
    SELECT TOP 1 @p = MaPhien, @code = MaCode, @het = HetHanLuc
    FROM PhienDiemDanh WHERE MaHD = @MaHD AND TrangThai = 'Mo';

    IF @p IS NULL THROW 50140, N'Hoạt động này chưa mở điểm danh.', 1;
    IF @GiaTriMa IS NULL OR @code IS NULL OR @code <> LTRIM(RTRIM(@GiaTriMa)) OR @het IS NULL OR @het <= SYSDATETIME()
        THROW 50141, N'Mã điểm danh sai hoặc đã hết hạn.', 1;
    IF NOT EXISTS (SELECT 1 FROM DangKy WHERE MaHD = @MaHD AND MaThanhVien = @MaThanhVien AND TrangThai = 'DaDangKy')
        THROW 50142, N'Bạn chưa đăng ký hoạt động này.', 1;
    IF EXISTS (SELECT 1 FROM DiemDanh WHERE MaPhien = @p AND MaThanhVien = @MaThanhVien)
        THROW 50143, N'Bạn đã điểm danh rồi.', 1;

    INSERT DiemDanh (MaPhien, MaThanhVien, HinhThuc) VALUES (@p, @MaThanhVien, 'Ma');
    SET @MaDiemDanh = SCOPE_IDENTITY();
END;
GO

-- Điểm danh bổ sung do người quản lý nhập (một bước, bắt buộc có lý do)
CREATE OR ALTER PROCEDURE sp_DiemDanhBoSung
    @MaThanhVien INT, @MaHD INT, @LyDo NVARCHAR(300), @MaTKGhi INT, @MaDiemDanh INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @tt VARCHAR(12), @p INT;
    SELECT @maCLB = MaCLB, @tt = TrangThai FROM HoatDong WHERE MaHD = @MaHD;
    SELECT TOP 1 @p = MaPhien FROM PhienDiemDanh WHERE MaHD = @MaHD ORDER BY MaPhien DESC;

    IF @maCLB IS NULL THROW 50150, N'Hoạt động không tồn tại.', 1;
    IF dbo.fn_LaQuanLyCLB(@MaTKGhi, @maCLB) = 0 THROW 50151, N'Bạn không có quyền điểm danh bổ sung cho CLB này.', 1;
    IF @tt NOT IN ('DangDienRa','DaKetThuc') THROW 50152, N'Chỉ bổ sung điểm danh cho hoạt động đã diễn ra.', 1;
    IF @p IS NULL THROW 50153, N'Hoạt động chưa từng mở phiên điểm danh.', 1;
    IF NULLIF(LTRIM(RTRIM(@LyDo)), '') IS NULL THROW 50154, N'Phải nhập lý do điểm danh bổ sung.', 1;
    IF NOT EXISTS (SELECT 1 FROM DangKy WHERE MaHD = @MaHD AND MaThanhVien = @MaThanhVien AND TrangThai = 'DaDangKy')
        THROW 50155, N'Thành viên này chưa đăng ký hoạt động.', 1;
    IF EXISTS (SELECT 1 FROM DiemDanh WHERE MaPhien = @p AND MaThanhVien = @MaThanhVien)
        THROW 50156, N'Thành viên này đã được điểm danh.', 1;

    INSERT DiemDanh (MaPhien, MaThanhVien, HinhThuc, LyDoBoSung, MaTKGhi)
    VALUES (@p, @MaThanhVien, 'BoSung', @LyDo, @MaTKGhi);
    SET @MaDiemDanh = SCOPE_IDENTITY();
END;
GO

-- Tổng kết: ghi số người tham gia thực tế, chi phí thực, đóng phiên điểm danh, chuyển sang 'Kết thúc'
CREATE OR ALTER PROCEDURE sp_TongKetHoatDong @MaHD INT, @MaTK INT, @NhanXet NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @tt VARCHAR(12);
    SELECT @maCLB = MaCLB, @tt = TrangThai FROM HoatDong WHERE MaHD = @MaHD;

    IF @maCLB IS NULL THROW 50160, N'Hoạt động không tồn tại.', 1;
    IF dbo.fn_LaQuanLyCLB(@MaTK, @maCLB) = 0 THROW 50161, N'Bạn không có quyền tổng kết hoạt động của CLB này.', 1;
    IF @tt <> 'DangDienRa' THROW 50162, N'Chỉ tổng kết hoạt động đang diễn ra.', 1;

    BEGIN TRAN;
    UPDATE PhienDiemDanh SET TrangThai = 'Dong', ThoiGianDong = SYSDATETIME(), HetHanLuc = NULL
    WHERE MaHD = @MaHD AND TrangThai = 'Mo';

    UPDATE HoatDong
    SET TrangThai = 'DaKetThuc',
        ChiPhiThuc = (SELECT ISNULL(SUM(SoTien), 0) FROM GiaoDich WHERE MaHD = @MaHD AND Loai = 'Chi'),
        SoThamGiaThucTe = (SELECT COUNT(DISTINCT dd.MaThanhVien)
                           FROM DiemDanh dd JOIN PhienDiemDanh p ON p.MaPhien = dd.MaPhien
                           WHERE p.MaHD = @MaHD AND dd.TrangThai = 'HopLe'),
        NhanXetTongKet = NULLIF(LTRIM(RTRIM(@NhanXet)), ''),
        NgayTongKet = SYSDATETIME()
    WHERE MaHD = @MaHD;
    COMMIT;
END;
GO

/* ================= NGÂN SÁCH & THU CHI ================= */

-- Lập đề nghị xin ngân sách cho một hoạt động có kinh phí (chờ Chủ nhiệm duyệt)
CREATE OR ALTER PROCEDURE sp_GuiXinNganSach
    @MaHD INT, @MaTK INT, @SoTienDeNghi DECIMAL(15,2), @MaNganSach INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @tt VARCHAR(12), @duToan DECIMAL(15,2);
    SELECT @maCLB = MaCLB, @tt = TrangThai, @duToan = DuToan FROM HoatDong WHERE MaHD = @MaHD;

    IF @maCLB IS NULL THROW 50170, N'Hoạt động không tồn tại.', 1;
    IF dbo.fn_LaQuanLyCLB(@MaTK, @maCLB) = 0 THROW 50171, N'Bạn không có quyền với CLB này.', 1;
    IF @tt NOT IN ('DaDuyet','DangDienRa') THROW 50172, N'Chỉ xin ngân sách cho hoạt động đã được duyệt.', 1;
    IF @duToan <= 0 THROW 50173, N'Hoạt động này không có kinh phí.', 1;
    IF @SoTienDeNghi IS NULL OR @SoTienDeNghi <= 0 THROW 50174, N'Số tiền đề nghị phải lớn hơn 0.', 1;
    IF EXISTS (SELECT 1 FROM NganSach WHERE MaHD = @MaHD AND TrangThai IN ('ChoDuyet','ChoKetQua','DuocCap'))
        THROW 50175, N'Hoạt động này đã có đề nghị ngân sách đang xử lý hoặc đã được cấp.', 1;

    INSERT NganSach (MaCLB, MaHD, SoTienDeNghi) VALUES (@maCLB, @MaHD, @SoTienDeNghi);
    SET @MaNganSach = SCOPE_IDENTITY();

    DECLARE @ds VARCHAR(20) = CAST(dbo.fn_TaiKhoanChuNhiem(@maCLB) AS VARCHAR(20));
    EXEC sp_TaoThongBao @ds, N'Đề nghị ngân sách chờ duyệt', N'Có đề nghị xin ngân sách mới cần Chủ nhiệm duyệt.';
END;
GO

-- Chủ nhiệm duyệt nội bộ: đồng ý thì chuyển sang chờ kết quả của nhà trường
CREATE OR ALTER PROCEDURE sp_DuyetNganSach @MaNganSach INT, @MaTK INT, @DongY BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @maCLB INT, @tt VARCHAR(10);
    SELECT @maCLB = MaCLB, @tt = TrangThai FROM NganSach WHERE MaNganSach = @MaNganSach;

    IF @maCLB IS NULL THROW 50180, N'Đề nghị ngân sách không tồn tại.', 1;
    IF @MaTK <> ISNULL(dbo.fn_TaiKhoanChuNhiem(@maCLB), -1) THROW 50181, N'Chỉ Chủ nhiệm mới được duyệt đề nghị ngân sách.', 1;
    IF @tt <> 'ChoDuyet' THROW 50182, N'Đề nghị này đã được xử lý.', 1;

    UPDATE NganSach
    SET TrangThai = CASE WHEN @DongY = 1 THEN 'ChoKetQua' ELSE 'TuChoi' END,
        NgayKetQua = CASE WHEN @DongY = 1 THEN NULL ELSE SYSDATETIME() END
    WHERE MaNganSach = @MaNganSach;
END;
GO

-- Ghi kết quả xét của nhà trường. Được cấp thì tự ghi một khoản Thu vào quỹ.
CREATE OR ALTER PROCEDURE sp_GhiNhanKetQuaNganSach
    @MaNganSach INT, @MaTK INT, @KetQua VARCHAR(10), @SoTienDuocCap DECIMAL(15,2) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @maHD INT, @tt VARCHAR(10), @ten NVARCHAR(200);
    SELECT @maCLB = ns.MaCLB, @maHD = ns.MaHD, @tt = ns.TrangThai, @ten = h.TenHoatDong
    FROM NganSach ns LEFT JOIN HoatDong h ON h.MaHD = ns.MaHD WHERE ns.MaNganSach = @MaNganSach;

    IF @maCLB IS NULL THROW 50190, N'Đề nghị ngân sách không tồn tại.', 1;
    IF dbo.fn_LaQuanLyCLB(@MaTK, @maCLB) = 0 THROW 50191, N'Bạn không có quyền với CLB này.', 1;
    IF @tt <> 'ChoKetQua' THROW 50192, N'Đề nghị chưa được Chủ nhiệm duyệt hoặc đã có kết quả.', 1;
    IF @KetQua NOT IN ('DuocCap','TuChoi') THROW 50193, N'Kết quả không hợp lệ.', 1;
    IF @KetQua = 'DuocCap' AND (@SoTienDuocCap IS NULL OR @SoTienDuocCap <= 0)
        THROW 50194, N'Phải nhập số tiền được cấp lớn hơn 0.', 1;

    BEGIN TRAN;
    UPDATE NganSach
    SET TrangThai = @KetQua,
        SoTienDuocCap = CASE WHEN @KetQua = 'DuocCap' THEN @SoTienDuocCap END,
        NgayKetQua = SYSDATETIME()
    WHERE MaNganSach = @MaNganSach;

    IF @KetQua = 'DuocCap'
        INSERT GiaoDich (MaCLB, MaHD, MaTKGhi, Loai, SoTien, NoiDung)
        VALUES (@maCLB, @maHD, @MaTK, 'Thu', @SoTienDuocCap, N'Nhà trường cấp kinh phí: ' + ISNULL(@ten, N'hoạt động'));
    COMMIT;
END;
GO

CREATE OR ALTER PROCEDURE sp_GhiGiaoDich
    @MaCLB INT, @MaTKGhi INT, @Loai VARCHAR(3), @SoTien DECIMAL(15,2), @NoiDung NVARCHAR(300),
    @MaHD INT = NULL, @MaGiaoDich INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    IF dbo.fn_LaQuanLyCLB(@MaTKGhi, @MaCLB) = 0 THROW 50200, N'Bạn không có quyền ghi thu chi của CLB này.', 1;
    IF @Loai NOT IN ('Thu','Chi') THROW 50201, N'Loại giao dịch phải là Thu hoặc Chi.', 1;
    IF @SoTien IS NULL OR @SoTien <= 0 THROW 50202, N'Số tiền phải lớn hơn 0.', 1;
    IF NULLIF(LTRIM(RTRIM(@NoiDung)), '') IS NULL THROW 50203, N'Chưa nhập nội dung giao dịch.', 1;
    IF @MaHD IS NOT NULL AND NOT EXISTS (SELECT 1 FROM HoatDong WHERE MaHD = @MaHD AND MaCLB = @MaCLB)
        THROW 50204, N'Hoạt động không thuộc CLB này.', 1;

    BEGIN TRAN;
    IF @Loai = 'Chi'
    BEGIN
        DECLARE @soDu DECIMAL(15,2);
        SELECT @soDu = ISNULL(SUM(CASE Loai WHEN 'Thu' THEN SoTien ELSE -SoTien END), 0)
        FROM GiaoDich WITH (UPDLOCK, HOLDLOCK) WHERE MaCLB = @MaCLB;
        IF @SoTien > @soDu THROW 50205, N'Số dư quỹ không đủ để chi khoản này.', 1;
    END;
    INSERT GiaoDich (MaCLB, MaHD, MaTKGhi, Loai, SoTien, NoiDung)
    VALUES (@MaCLB, @MaHD, @MaTKGhi, @Loai, @SoTien, @NoiDung);
    SET @MaGiaoDich = SCOPE_IDENTITY();
    COMMIT;
END;
GO

/* ================= TÀI SẢN & MƯỢN TRẢ ================= */

CREATE OR ALTER PROCEDURE sp_DangKyMuon
    @MaThanhVien INT, @MaTaiSan INT, @NgayMuon DATE, @HanTra DATE,
    @MucDich NVARCHAR(200) = NULL, @MucDoCanGap VARCHAR(10) = 'Thuong', @MaPhieu INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @clbTV INT, @ttTV VARCHAR(15), @clbTS INT, @tinhTrang VARCHAR(10);
    SELECT @clbTV = MaCLB, @ttTV = TrangThai FROM ThanhVien WHERE MaThanhVien = @MaThanhVien;
    SELECT @clbTS = MaCLB, @tinhTrang = TinhTrang FROM TaiSan WHERE MaTaiSan = @MaTaiSan;

    IF @clbTV IS NULL OR @ttTV = 'DaRoi' THROW 50210, N'Người mượn không hợp lệ.', 1;
    IF @clbTS IS NULL THROW 50211, N'Tài sản không tồn tại.', 1;
    IF @clbTS <> @clbTV THROW 50212, N'Tài sản không thuộc CLB của bạn.', 1;
    IF @tinhTrang = 'HuHong' THROW 50213, N'Tài sản đang hỏng, không thể mượn.', 1;
    IF @NgayMuon < CAST(GETDATE() AS DATE) THROW 50214, N'Ngày mượn không được ở quá khứ.', 1;
    IF @HanTra < @NgayMuon THROW 50215, N'Hạn trả phải sau ngày mượn.', 1;
    IF @MucDoCanGap NOT IN ('Thuong','Gap') THROW 50216, N'Mức độ cần gấp không hợp lệ.', 1;
    IF EXISTS (SELECT 1 FROM PhieuMuon WHERE MaTaiSan = @MaTaiSan AND TrangThai IN ('DaDuyet','DangMuon'))
        THROW 50217, N'Tài sản đang được mượn hoặc đã có phiếu được duyệt.', 1;
    IF EXISTS (SELECT 1 FROM PhieuMuon WHERE MaTaiSan = @MaTaiSan AND MaThanhVien = @MaThanhVien AND TrangThai = 'ChoDuyet')
        THROW 50218, N'Bạn đã có phiếu mượn tài sản này đang chờ duyệt.', 1;

    INSERT PhieuMuon (MaTaiSan, MaThanhVien, NgayMuon, HanTra, MucDich, MucDoCanGap)
    VALUES (@MaTaiSan, @MaThanhVien, @NgayMuon, @HanTra, @MucDich, @MucDoCanGap);
    SET @MaPhieu = SCOPE_IDENTITY();

    DECLARE @ds VARCHAR(MAX) = (SELECT STRING_AGG(CAST(tk.MaTK AS VARCHAR(20)), ',')
                                FROM ThanhVien tv JOIN TaiKhoan tk ON tk.MaSV = tv.MaSV
                                WHERE tv.MaCLB = @clbTV AND tv.TrangThai <> 'DaRoi'
                                  AND tv.ChucVu IN ('ChuNhiem','NguoiPhuTrachThuChi'));
    EXEC sp_TaoThongBao @ds, N'Phiếu mượn tài sản chờ duyệt', N'Có phiếu mượn tài sản mới cần xử lý.';
END;
GO

CREATE OR ALTER PROCEDURE sp_DuyetPhieuMuon @MaPhieu INT, @MaTK INT, @DongY BIT, @LyDo NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @tt VARCHAR(10), @maTS INT, @maTV INT;
    SELECT @maCLB = ts.MaCLB, @tt = pm.TrangThai, @maTS = pm.MaTaiSan, @maTV = pm.MaThanhVien
    FROM PhieuMuon pm JOIN TaiSan ts ON ts.MaTaiSan = pm.MaTaiSan WHERE pm.MaPhieu = @MaPhieu;

    IF @maCLB IS NULL THROW 50220, N'Phiếu mượn không tồn tại.', 1;
    IF dbo.fn_LaQuanLyCLB(@MaTK, @maCLB) = 0 THROW 50221, N'Bạn không có quyền duyệt phiếu của CLB này.', 1;
    IF @tt <> 'ChoDuyet' THROW 50222, N'Phiếu này đã được xử lý.', 1;
    IF @DongY = 1 AND EXISTS (SELECT 1 FROM PhieuMuon WHERE MaTaiSan = @maTS AND TrangThai IN ('DaDuyet','DangMuon'))
        THROW 50223, N'Tài sản đang được mượn hoặc đã có phiếu khác được duyệt.', 1;

    UPDATE PhieuMuon
    SET TrangThai = CASE WHEN @DongY = 1 THEN 'DaDuyet' ELSE 'TuChoi' END,
        MaTKDuyet = @MaTK,
        LyDoTuChoi = CASE WHEN @DongY = 1 THEN NULL ELSE ISNULL(NULLIF(LTRIM(RTRIM(@LyDo)), ''), N'Không nêu lý do') END
    WHERE MaPhieu = @MaPhieu;

    DECLARE @ds VARCHAR(20) = CAST((SELECT TOP 1 tk.MaTK FROM ThanhVien tv JOIN TaiKhoan tk ON tk.MaSV = tv.MaSV
                                    WHERE tv.MaThanhVien = @maTV) AS VARCHAR(20));
    EXEC sp_TaoThongBao @ds, N'Kết quả phiếu mượn tài sản', N'Phiếu mượn tài sản của bạn đã được xử lý.';
END;
GO

CREATE OR ALTER PROCEDURE sp_GiaoTaiSan @MaPhieu INT, @MaTK INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @maCLB INT, @tt VARCHAR(10);
    SELECT @maCLB = ts.MaCLB, @tt = pm.TrangThai
    FROM PhieuMuon pm JOIN TaiSan ts ON ts.MaTaiSan = pm.MaTaiSan WHERE pm.MaPhieu = @MaPhieu;

    IF @maCLB IS NULL THROW 50230, N'Phiếu mượn không tồn tại.', 1;
    IF dbo.fn_LaQuanLyCLB(@MaTK, @maCLB) = 0 THROW 50231, N'Bạn không có quyền giao tài sản của CLB này.', 1;
    IF @tt <> 'DaDuyet' THROW 50232, N'Chỉ giao tài sản cho phiếu đã được duyệt.', 1;

    UPDATE PhieuMuon SET TrangThai = 'DangMuon', NgayGiao = SYSDATETIME() WHERE MaPhieu = @MaPhieu;
END;
GO

-- Nhận trả: quá hạn thì ghi 'Trả trễ'; cập nhật tình trạng tài sản theo lúc trả
CREATE OR ALTER PROCEDURE sp_TraTaiSan
    @MaPhieu INT, @MaTK INT, @TinhTrangKhiTra VARCHAR(10), @GhiChu NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @maCLB INT, @tt VARCHAR(10), @maTS INT, @han DATE;
    SELECT @maCLB = ts.MaCLB, @tt = pm.TrangThai, @maTS = pm.MaTaiSan, @han = pm.HanTra
    FROM PhieuMuon pm JOIN TaiSan ts ON ts.MaTaiSan = pm.MaTaiSan WHERE pm.MaPhieu = @MaPhieu;

    IF @maCLB IS NULL THROW 50240, N'Phiếu mượn không tồn tại.', 1;
    IF dbo.fn_LaQuanLyCLB(@MaTK, @maCLB) = 0 THROW 50241, N'Bạn không có quyền nhận trả tài sản của CLB này.', 1;
    IF @tt <> 'DangMuon' THROW 50242, N'Phiếu này không ở trạng thái đang mượn.', 1;
    IF @TinhTrangKhiTra NOT IN ('Tot','Cu','HuNhe','HuHong') THROW 50243, N'Tình trạng khi trả không hợp lệ.', 1;

    BEGIN TRAN;
    UPDATE PhieuMuon
    SET NgayTra = SYSDATETIME(), TinhTrangKhiTra = @TinhTrangKhiTra, GhiChuTra = @GhiChu,
        TrangThai = CASE WHEN CAST(GETDATE() AS DATE) > @han THEN 'TraTre' ELSE 'DaTra' END
    WHERE MaPhieu = @MaPhieu;
    UPDATE TaiSan SET TinhTrang = @TinhTrangKhiTra WHERE MaTaiSan = @maTS;
    COMMIT;
END;
GO

-- Nhắc người mượn các phiếu quá hạn (mỗi phiếu tối đa một lần mỗi ngày, gọi lại không sao)
CREATE OR ALTER PROCEDURE sp_DanhDauMuonTreHan
AS
BEGIN
    SET NOCOUNT ON;
    INSERT ThongBao (MaTKNhan, TieuDe, NoiDung)
    SELECT tk.MaTK, N'Nhắc trả tài sản',
           N'Phiếu mượn #' + CAST(pm.MaPhieu AS NVARCHAR(10)) + N' đã quá hạn '
           + CAST(DATEDIFF(DAY, pm.HanTra, CAST(GETDATE() AS DATE)) AS NVARCHAR(10)) + N' ngày. Vui lòng trả tài sản.'
    FROM PhieuMuon pm
    JOIN ThanhVien tv ON tv.MaThanhVien = pm.MaThanhVien
    JOIN TaiKhoan tk ON tk.MaSV = tv.MaSV
    WHERE pm.TrangThai = 'DangMuon' AND pm.HanTra < CAST(GETDATE() AS DATE)
      AND NOT EXISTS (SELECT 1 FROM ThongBao t
                      WHERE t.MaTKNhan = tk.MaTK AND t.TieuDe = N'Nhắc trả tài sản'
                        AND t.NoiDung LIKE N'Phiếu mượn #' + CAST(pm.MaPhieu AS NVARCHAR(10)) + N' %'
                        AND CAST(t.NgayTao AS DATE) = CAST(GETDATE() AS DATE));
END;
GO

/* ================= BÁO CÁO ================= */

-- Trả 6 bảng: 1 thành viên; 2 hoạt động theo trạng thái; 3 tham gia từng hoạt động; 4 tổng thu chi;
--             5 chi theo hoạt động (TenKhoan = tên hoạt động, HanMuc = dự toán); 6 mượn tài sản
CREATE OR ALTER PROCEDURE sp_BaoCaoCuoiKy @MaCLB INT, @TuNgay DATE, @DenNgay DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(*) AS TongThanhVien,
           ISNULL(SUM(CASE WHEN TrangThai = 'HoatDong' THEN 1 ELSE 0 END), 0) AS DangHoatDong,
           ISNULL(SUM(CASE WHEN TrangThai = 'KhongHoatDong' THEN 1 ELSE 0 END), 0) AS KhongHoatDong,
           ISNULL(SUM(CASE WHEN NgayGiaNhap BETWEEN @TuNgay AND @DenNgay THEN 1 ELSE 0 END), 0) AS MoiGiaNhapTrongKy,
           ISNULL(SUM(CASE WHEN NgayRoi BETWEEN @TuNgay AND @DenNgay THEN 1 ELSE 0 END), 0) AS RoiTrongKy
     FROM ThanhVien WHERE MaCLB = @MaCLB;

    SELECT TrangThai, COUNT(*) AS SoHoatDong
    FROM HoatDong
    WHERE MaCLB = @MaCLB AND CAST(ThoiGianBatDau AS DATE) BETWEEN @TuNgay AND @DenNgay
    GROUP BY TrangThai;

    SELECT * FROM vw_ThongKeDiemDanhHoatDong
    WHERE MaCLB = @MaCLB AND CAST(ThoiGianBatDau AS DATE) BETWEEN @TuNgay AND @DenNgay
    ORDER BY ThoiGianBatDau;

    SELECT * FROM dbo.fn_TongHopThuChi(@MaCLB, @TuNgay, @DenNgay);

    SELECT h.TenHoatDong AS TenKhoan, h.DuToan AS HanMuc, ISNULL(SUM(g.SoTien), 0) AS DaChi
    FROM HoatDong h
    LEFT JOIN GiaoDich g ON g.MaHD = h.MaHD AND g.Loai = 'Chi' AND g.NgayGiaoDich BETWEEN @TuNgay AND @DenNgay
    WHERE h.MaCLB = @MaCLB AND h.DuToan > 0 AND h.TrangThai NOT IN ('Nhap','TuChoi','DaHuy')
      AND CAST(h.ThoiGianBatDau AS DATE) BETWEEN @TuNgay AND @DenNgay
    GROUP BY h.MaHD, h.TenHoatDong, h.DuToan;

    SELECT COUNT(*) AS SoPhieu,
           ISNULL(SUM(CASE WHEN pm.TrangThai = 'TraTre' THEN 1 ELSE 0 END), 0) AS SoPhieuTraTre
    FROM PhieuMuon pm JOIN ThanhVien tv ON tv.MaThanhVien = pm.MaThanhVien
    WHERE tv.MaCLB = @MaCLB AND pm.NgayMuon BETWEEN @TuNgay AND @DenNgay;
END;
GO

PRINT N'Đã tạo stored procedure.';
GO
