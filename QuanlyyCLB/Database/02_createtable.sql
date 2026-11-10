USE QuanLyCLBSinhVien;
GO
SET NOCOUNT ON;
GO
/* =====================================================================
   19 BẢNG. File này chỉ tạo cột, khóa chính, UNIQUE và DEFAULT.
   Khóa ngoại và CHECK nằm ở 03_constraints.sql.
   ===================================================================== */

/* ---------- Nhóm 1: Con người & tài khoản ---------- */
CREATE TABLE SinhVien (
    MaSV   VARCHAR(20)   NOT NULL CONSTRAINT PK_SinhVien PRIMARY KEY,
    HoTen  NVARCHAR(100) NOT NULL,
    Email  VARCHAR(120)  NULL,           -- unique có điều kiện (04_indexes.sql) để cho phép nhiều dòng NULL
    SDT    VARCHAR(15)   NULL,
    Khoa   NVARCHAR(100) NULL,
    Lop    NVARCHAR(50)  NULL
);

CREATE TABLE GiangVien (
    MaGV   VARCHAR(20)   NOT NULL CONSTRAINT PK_GiangVien PRIMARY KEY,
    HoTen  NVARCHAR(100) NOT NULL,
    Email  VARCHAR(120)  NULL,
    Khoa   NVARCHAR(100) NULL
);

CREATE TABLE TaiKhoan (
    MaTK            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TaiKhoan PRIMARY KEY,
    TenDangNhap     VARCHAR(50)  NOT NULL CONSTRAINT UQ_TaiKhoan_TenDangNhap UNIQUE,
    MatKhauHash     VARCHAR(300) NOT NULL,   -- dạng PBKDF2$<số vòng>$<salt base64>$<hash base64>
    LoaiTaiKhoan    VARCHAR(10)  NOT NULL,   -- SinhVien / GiangVien / QuanTri
    TrangThai       VARCHAR(10)  NOT NULL CONSTRAINT DF_TaiKhoan_TrangThai DEFAULT 'HoatDong',
    MaSV            VARCHAR(20)  NULL,
    MaGV            VARCHAR(20)  NULL,
    LanDangNhapCuoi DATETIME2(0) NULL
);

/* ---------- Nhóm 2: CLB & thành viên ---------- */
CREATE TABLE CLB (
    MaCLB        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CLB PRIMARY KEY,
    TenCLB       NVARCHAR(150) NOT NULL CONSTRAINT UQ_CLB_TenCLB UNIQUE,
    LinhVuc      NVARCHAR(100) NULL,
    MoTa         NVARCHAR(500) NULL,
    NgayThanhLap DATE          NULL,
    MaGVCoVan    VARCHAR(20)   NOT NULL      -- giảng viên cố vấn (thay cho bảng CoVan)
);

CREATE TABLE Nhom (
    MaNhom  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Nhom PRIMARY KEY,
    MaCLB   INT           NOT NULL,
    TenNhom NVARCHAR(100) NOT NULL,
    CONSTRAINT UQ_Nhom_CLB_Ten UNIQUE (MaCLB, TenNhom),
    CONSTRAINT UQ_Nhom_Nhom_CLB UNIQUE (MaNhom, MaCLB)      -- làm đích cho khóa ngoại kép của ThanhVien
);

CREATE TABLE ThanhVien (
    MaThanhVien INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ThanhVien PRIMARY KEY,
    MaCLB       INT          NOT NULL,
    MaSV        VARCHAR(20)  NOT NULL,
    MaNhom      INT          NULL,
    ChucVu      VARCHAR(25)  NOT NULL CONSTRAINT DF_ThanhVien_ChucVu DEFAULT 'ThanhVien',
    NgayGiaNhap DATE         NOT NULL CONSTRAINT DF_ThanhVien_NgayGiaNhap DEFAULT (CONVERT(DATE, GETDATE())),
    TrangThai   VARCHAR(15)  NOT NULL CONSTRAINT DF_ThanhVien_TrangThai DEFAULT 'HoatDong',
    NgayRoi     DATE         NULL,
    LyDoRoi     NVARCHAR(300) NULL,
    CONSTRAINT UQ_ThanhVien_CLB_SV UNIQUE (MaCLB, MaSV),
    CONSTRAINT UQ_ThanhVien_TV_CLB UNIQUE (MaThanhVien, MaCLB)   -- làm đích cho khóa ngoại kép của HoatDong
);

/* ---------- Nhóm 3: Tuyển thành viên ---------- */
CREATE TABLE DotTuyen (
    MaDot       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DotTuyen PRIMARY KEY,
    MaCLB       INT           NOT NULL,
    TenDot      NVARCHAR(150) NOT NULL,
    NgayBatDau  DATE          NOT NULL,
    NgayKetThuc DATE          NOT NULL,
    ChiTieu     INT           NULL,
    TrangThai   VARCHAR(10)   NOT NULL CONSTRAINT DF_DotTuyen_TrangThai DEFAULT 'SapMo'
);

-- Đơn ứng tuyển + hồ sơ + phỏng vấn gộp một bảng (thay cho DonGiaNhap, PhongVan, PhongVanNguoiPV)
CREATE TABLE DonUngTuyen (
    MaDon       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DonUngTuyen PRIMARY KEY,
    MaDot       INT           NOT NULL,
    MaSV        VARCHAR(20)   NOT NULL,
    MaNhom      INT           NULL,                  -- nhóm nguyện vọng
    GioiThieu   NVARCHAR(1000) NULL,
    NgayNop     DATETIME2(0)  NOT NULL CONSTRAINT DF_DonUngTuyen_NgayNop DEFAULT SYSDATETIME(),
    TrangThai   VARCHAR(15)   NOT NULL CONSTRAINT DF_DonUngTuyen_TrangThai DEFAULT 'DaNop',
    DiemHoSo    DECIMAL(4,2)  NULL,
    GhiChuHoSo  NVARCHAR(500) NULL,
    ThoiGianPV  DATETIME2(0)  NULL,
    DiaDiemPV   NVARCHAR(200) NULL,
    MaNguoiPV   INT           NULL,                  -- một thành viên phỏng vấn
    DiemPV      DECIMAL(4,2)  NULL,
    NhanXetPV   NVARCHAR(500) NULL,
    CONSTRAINT UQ_DonUngTuyen_Dot_SV UNIQUE (MaDot, MaSV)
);

/* ---------- Nhóm 4: Hoạt động ---------- */
CREATE TABLE HoatDong (
    MaHD            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_HoatDong PRIMARY KEY,
    MaCLB           INT           NOT NULL,
    MaNguoiDeXuat   INT           NOT NULL,
    TenHoatDong     NVARCHAR(200) NOT NULL,
    MoTa            NVARCHAR(1000) NULL,
    DiaDiem         NVARCHAR(200) NULL,
    ThoiGianBatDau  DATETIME2(0)  NOT NULL,
    ThoiGianKetThuc DATETIME2(0)  NOT NULL,
    SoLuongToiDa    INT           NULL,
    DuToan          DECIMAL(15,2) NOT NULL CONSTRAINT DF_HoatDong_DuToan DEFAULT 0,
    TrangThai       VARCHAR(12)   NOT NULL CONSTRAINT DF_HoatDong_TrangThai DEFAULT 'Nhap',
    -- tổng kết (thay cho bảng TongKetHoatDong)
    ChiPhiThuc      DECIMAL(15,2) NULL,
    SoThamGiaThucTe INT           NULL,
    NhanXetTongKet  NVARCHAR(1000) NULL,
    NgayTongKet     DATETIME2(0)  NULL,
    NgayTao         DATETIME2(0)  NOT NULL CONSTRAINT DF_HoatDong_NgayTao DEFAULT SYSDATETIME(),
    CONSTRAINT UQ_HoatDong_HD_CLB UNIQUE (MaHD, MaCLB)
);

CREATE TABLE DuyetHoatDong (
    MaDuyet    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DuyetHoatDong PRIMARY KEY,
    MaHD       INT           NOT NULL,
    CapDuyet   TINYINT       NOT NULL,                -- 1 = Chủ nhiệm, 2 = Giảng viên cố vấn
    MaTKDuyet  INT           NOT NULL,
    KetQua     VARCHAR(10)   NOT NULL CONSTRAINT DF_DuyetHD_KetQua DEFAULT 'ChoDuyet',
    LyDo       NVARCHAR(500) NULL,
    NgayDuyet  DATETIME2(0)  NULL,
    CONSTRAINT UQ_DuyetHD_HD_Cap UNIQUE (MaHD, CapDuyet)
);

CREATE TABLE DangKy (
    MaDangKy    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DangKy PRIMARY KEY,
    MaHD        INT          NOT NULL,
    MaThanhVien INT          NOT NULL,
    NgayDangKy  DATETIME2(0) NOT NULL CONSTRAINT DF_DangKy_Ngay DEFAULT SYSDATETIME(),
    TrangThai   VARCHAR(10)  NOT NULL CONSTRAINT DF_DangKy_TrangThai DEFAULT 'DaDangKy',
    CONSTRAINT UQ_DangKy_HD_TV UNIQUE (MaHD, MaThanhVien)
);

/* ---------- Nhóm 5: Điểm danh ---------- */
-- Phiên + mã hiện hành gộp một bảng (thay cho MaDiemDanh)
CREATE TABLE PhienDiemDanh (
    MaPhien       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PhienDiemDanh PRIMARY KEY,
    MaHD          INT          NOT NULL,
    MaCode        VARCHAR(10)  NULL,
    HetHanLuc     DATETIME2(0) NULL,                  -- thời điểm mã hiện tại hết hạn
    ThoiGianMo    DATETIME2(0) NOT NULL CONSTRAINT DF_Phien_Mo DEFAULT SYSDATETIME(),
    ThoiGianDong  DATETIME2(0) NULL,
    TrangThai     VARCHAR(5)   NOT NULL CONSTRAINT DF_Phien_TrangThai DEFAULT 'Mo'
);

CREATE TABLE DiemDanh (
    MaDiemDanh  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DiemDanh PRIMARY KEY,
    MaPhien     INT           NOT NULL,
    MaThanhVien INT           NOT NULL,
    ThoiGian    DATETIME2(0)  NOT NULL CONSTRAINT DF_DiemDanh_ThoiGian DEFAULT SYSDATETIME(),
    HinhThuc    VARCHAR(10)   NOT NULL,                -- Ma / BoSung
    TrangThai   VARCHAR(10)   NOT NULL CONSTRAINT DF_DiemDanh_TrangThai DEFAULT 'HopLe',
    LyDoBoSung  NVARCHAR(300) NULL,
    MaTKGhi     INT           NULL,                    -- tài khoản nhập bổ sung
    CONSTRAINT UQ_DiemDanh_Phien_TV UNIQUE (MaPhien, MaThanhVien)
);

/* ---------- Nhóm 6: Ngân sách & thu chi ---------- */
-- Đề nghị ngân sách (thay cho XinNganSach + KhoanNganSach)
CREATE TABLE NganSach (
    MaNganSach     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_NganSach PRIMARY KEY,
    MaCLB          INT           NOT NULL,
    MaHD           INT           NULL,
    SoTienDeNghi   DECIMAL(15,2) NOT NULL,
    SoTienDuocCap  DECIMAL(15,2) NULL,
    TrangThai      VARCHAR(10)   NOT NULL CONSTRAINT DF_NganSach_TrangThai DEFAULT 'ChoDuyet',
    NgayDeXuat     DATETIME2(0)  NOT NULL CONSTRAINT DF_NganSach_Ngay DEFAULT SYSDATETIME(),
    NgayKetQua     DATETIME2(0)  NULL
);

CREATE TABLE GiaoDich (
    MaGiaoDich   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_GiaoDich PRIMARY KEY,
    MaCLB        INT           NOT NULL,
    MaHD         INT           NULL,
    MaTKGhi      INT           NOT NULL,
    Loai         VARCHAR(3)    NOT NULL,                -- Thu / Chi
    SoTien       DECIMAL(15,2) NOT NULL,
    NoiDung      NVARCHAR(300) NOT NULL,
    NgayGiaoDich DATE          NOT NULL CONSTRAINT DF_GiaoDich_Ngay DEFAULT (CONVERT(DATE, GETDATE())),
    NgayTao      DATETIME2(0)  NOT NULL CONSTRAINT DF_GiaoDich_NgayTao DEFAULT SYSDATETIME()
);

/* ---------- Nhóm 7: Tài sản & mượn trả ---------- */
CREATE TABLE TaiSan (
    MaTaiSan    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TaiSan PRIMARY KEY,
    MaCLB       INT           NOT NULL,
    TenTaiSan   NVARCHAR(150) NOT NULL,
    LoaiTaiSan  NVARCHAR(100) NOT NULL,                -- thay cho bảng LoaiTaiSan
    TinhTrang   VARCHAR(10)   NOT NULL CONSTRAINT DF_TaiSan_TinhTrang DEFAULT 'Tot'
);

-- Một phiếu = một tài sản (thay cho PhieuMuon + ChiTietMuon)
CREATE TABLE PhieuMuon (
    MaPhieu         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PhieuMuon PRIMARY KEY,
    MaTaiSan        INT           NOT NULL,
    MaThanhVien     INT           NOT NULL,
    NgayDangKy      DATETIME2(0)  NOT NULL CONSTRAINT DF_PhieuMuon_NgayDK DEFAULT SYSDATETIME(),
    NgayMuon        DATE          NOT NULL,
    HanTra          DATE          NOT NULL,
    MucDich         NVARCHAR(200) NULL,
    MucDoCanGap     VARCHAR(10)   NOT NULL CONSTRAINT DF_PhieuMuon_Gap DEFAULT 'Thuong',
    TrangThai       VARCHAR(10)   NOT NULL CONSTRAINT DF_PhieuMuon_TrangThai DEFAULT 'ChoDuyet',
    MaTKDuyet       INT           NULL,
    LyDoTuChoi      NVARCHAR(300) NULL,
    NgayGiao        DATETIME2(0)  NULL,
    NgayTra         DATETIME2(0)  NULL,
    TinhTrangKhiTra VARCHAR(10)   NULL,
    GhiChuTra       NVARCHAR(300) NULL
);

/* ---------- Nhóm 8: Thông báo ---------- */
-- Mỗi dòng = một thông báo gửi cho một tài khoản (thay cho ThongBao + NguoiNhanThongBao)
CREATE TABLE ThongBao (
    MaTB      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ThongBao PRIMARY KEY,
    MaTKNhan  INT            NOT NULL,
    TieuDe    NVARCHAR(200)  NOT NULL,
    NoiDung   NVARCHAR(1000) NULL,
    DaDoc     BIT            NOT NULL CONSTRAINT DF_ThongBao_DaDoc DEFAULT 0,
    NgayTao   DATETIME2(0)   NOT NULL CONSTRAINT DF_ThongBao_NgayTao DEFAULT SYSDATETIME()
);

/* ---------- Bảng 19: yêu cầu quyền xem chi tiết thu chi ---------- */
CREATE TABLE QuyenXemChiTiet (
    MaQuyenXem   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_QuyenXemChiTiet PRIMARY KEY,
    MaThanhVien  INT NOT NULL,
    MaTK         INT NOT NULL,
    PhamVi       VARCHAR(12) NOT NULL, -- Nhom / HoatDong / CLB
    MaNhom       INT NULL,
    MaHD         INT NULL,
    LyDoYeuCau   NVARCHAR(500) NOT NULL,
    TrangThai    VARCHAR(10) NOT NULL CONSTRAINT DF_QuyenXem_TrangThai DEFAULT 'ChoDuyet',
    MaTKQuyetDinh INT NULL,
    NgayYeuCau   DATETIME2(0) NOT NULL CONSTRAINT DF_QuyenXem_NgayYeuCau DEFAULT SYSDATETIME(),
    NgayQuyetDinh DATETIME2(0) NULL
);
GO

PRINT N'Đã tạo 19 bảng.';
SELECT COUNT(*) AS SoBang FROM sys.tables;
GO
