USE QuanLyCLBSinhVien;
GO
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO
/* =====================================================================
   DỮ LIỆU MẪU. Mật khẩu của MỌI tài khoản: Demo@123
   (lưu dạng PBKDF2-SHA256, 100000 vòng, salt riêng từng tài khoản; hash tính sẵn bằng Python)
   Tài khoản: admin | GV001..GV003 | 2251120011..2251120022 (tên đăng nhập = mã SV/GV)
   ===================================================================== */
-- Toàn bộ seed nằm trong MỘT batch (không có GO) để dùng chung biến.

BEGIN TRY
    BEGIN TRANSACTION;

INSERT SinhVien (MaSV, HoTen, Email, SDT, Khoa, Lop) VALUES
('2251120011', N'Nguyễn Minh Khoa', 'sv011@student.edu.vn', '0901000010', N'Công nghệ thông tin', N'22CNTT1'),
('2251120012', N'Trần Thị Lan', 'sv012@student.edu.vn', '0901000011', N'Công nghệ thông tin', N'22CNTT1'),
('2251120013', N'Lê Hoàng Nam', 'sv013@student.edu.vn', '0901000012', N'Kỹ thuật phần mềm', N'22KTPM1'),
('2251120014', N'Phạm Thu Hà', 'sv014@student.edu.vn', '0901000013', N'Công nghệ thông tin', N'22CNTT2'),
('2251120015', N'Võ Quốc Bảo', 'sv015@student.edu.vn', '0901000014', N'Quản trị kinh doanh', N'22QTKD1'),
('2251120016', N'Đặng Ngọc Mai', 'sv016@student.edu.vn', '0901000015', N'Truyền thông đa phương tiện', N'22TT1'),
('2251120017', N'Bùi Anh Tuấn', 'sv017@student.edu.vn', '0901000016', N'Sư phạm Âm nhạc', N'22AN1'),
('2251120018', N'Hoàng Thị Yến', 'sv018@student.edu.vn', '0901000017', N'Sư phạm Âm nhạc', N'22AN1'),
('2251120019', N'Ngô Đức Huy', 'sv019@student.edu.vn', '0901000018', N'Công nghệ thông tin', N'22CNTT2'),
('2251120020', N'Đỗ Khánh Linh', 'sv020@student.edu.vn', '0901000019', N'Truyền thông đa phương tiện', N'22TT1'),
('2251120021', N'Phan Gia Bảo', 'sv021@student.edu.vn', '0901000020', N'Công nghệ thông tin', N'23CNTT1'),
('2251120022', N'Vũ Thị Hương', 'sv022@student.edu.vn', '0901000021', N'Kỹ thuật phần mềm', N'23KTPM1');

INSERT GiangVien (MaGV, HoTen, Email, Khoa) VALUES
('GV001', N'Nguyễn Văn An', 'gv001@edu.vn', N'Công nghệ thông tin'),
('GV002', N'Trần Thị Bình', 'gv002@edu.vn', N'Sư phạm Âm nhạc'),
('GV003', N'Lê Quốc Cường', 'gv003@edu.vn', N'Quản trị kinh doanh');

INSERT TaiKhoan (TenDangNhap, MatKhauHash, LoaiTaiKhoan, MaSV, MaGV) VALUES
('admin', 'PBKDF2$100000$ZPDailGvbCPwCg1Z0TkUgA==$9gRpkM0FcuTWCf2L5DSmp2DQgOE/Zuf7iinrwr3SxQQ=', 'QuanTri', NULL, NULL),
('GV001', 'PBKDF2$100000$rbDykQCLaUauvv6m8hYpbA==$IbYPwCPnpUuuPVHHk9nq4k4XSSIGpF/5+JUgSw5vHEk=', 'GiangVien', NULL, 'GV001'),
('GV002', 'PBKDF2$100000$9OvJIzgAlGQ9/sLPhR3iPQ==$HP4cJQEw5HZrhU4gw9946tPwcENQ1z1/7XAPE9LqE3M=', 'GiangVien', NULL, 'GV002'),
('GV003', 'PBKDF2$100000$H0Wb59AaAnlC6aiqcoWPoQ==$i+sumnfNtCo8iPiOdFpHAaYirb45RcEkugFokHISjsc=', 'GiangVien', NULL, 'GV003'),
('2251120011', 'PBKDF2$100000$xEA+kzH2LDE0MyVDx4WE2A==$L2ZP+YUW7smB2Fhx+S9qgbAVHZMUuI0fLRH8l3QSoMI=', 'SinhVien', '2251120011', NULL),
('2251120012', 'PBKDF2$100000$gmkN62S3jGya+DukwkTgxQ==$JqYwZT2+ekPHVI2x0W2An+2SyJv9OWBcGF2HyG9qwi0=', 'SinhVien', '2251120012', NULL),
('2251120013', 'PBKDF2$100000$yDndW0UG9YVrSuJDbGuhRQ==$i+n/OphCvzJbJJAJWZxUMAhqreKH3U0gp+8c1GOIw28=', 'SinhVien', '2251120013', NULL),
('2251120014', 'PBKDF2$100000$u5u4rMEGazh4d54pJjckvw==$tTYfZZMXj+vl6YlYF3lLg6SIQTIDzwOzjvfJ+Dz+58Q=', 'SinhVien', '2251120014', NULL),
('2251120015', 'PBKDF2$100000$osH5r0o2460tYsEGOC80Sw==$y4OrlA5/t12kSlg9RHyNMSakPkFfarbbgPr1Ic3DxW4=', 'SinhVien', '2251120015', NULL),
('2251120016', 'PBKDF2$100000$TH4bfzCT93R7+B+8IguXjA==$cZKT3/be8i3Bl6IczxcgJA+3vnYmx5vwCCiTNBZHZUg=', 'SinhVien', '2251120016', NULL),
('2251120017', 'PBKDF2$100000$6yPxsUdYW2XIVAAs3sDA4g==$dAsMMH/frVf45uPVtC+TPyia7pvDEFzMsKcTeKDF39s=', 'SinhVien', '2251120017', NULL),
('2251120018', 'PBKDF2$100000$8m2UN9CcDTd2E4lJmGWakQ==$9DPfvU2jJPr1E8vSM8CkSedxC8Y8fppcXg2QD+lc5/w=', 'SinhVien', '2251120018', NULL),
('2251120019', 'PBKDF2$100000$7pFulfGCz2UNu+dCWSD5Hw==$JyF1gge7uYi/fsyQZqn0pXLgoQfljyPd1G7duVuszRg=', 'SinhVien', '2251120019', NULL),
('2251120020', 'PBKDF2$100000$JJ6IBE3+GvhguRcHbVS6NA==$WhIR36PgpiXMptHuZ5b7bANA0KxgbI3mEi8D4SzG/ic=', 'SinhVien', '2251120020', NULL),
('2251120021', 'PBKDF2$100000$REWqR9RH+vWrVd8abIy1pA==$x29XqxRoly7oanZuCGllsmWcHBY0IPrQm5VWduGr3tY=', 'SinhVien', '2251120021', NULL),
('2251120022', 'PBKDF2$100000$y/JuntOiNUijWFR2S/wxPQ==$DWq1diZY/fRniIAegHoEI9neYjhpL52fdaAFLFz1/5M=', 'SinhVien', '2251120022', NULL);


INSERT CLB (TenCLB, LinhVuc, MoTa, NgayThanhLap, MaGVCoVan) VALUES
(N'Câu lạc bộ Công nghệ thông tin', N'Công nghệ', N'Nơi sinh viên học và thực hành lập trình, làm dự án phần mềm.', '2019-03-15', 'GV001'),
(N'Câu lạc bộ Âm nhạc', N'Nghệ thuật', N'Sinh hoạt, biểu diễn và giao lưu âm nhạc trong trường.', '2018-10-01', 'GV002');
-- MaCLB: 1 = CNTT, 2 = Âm nhạc

INSERT Nhom (MaCLB, TenNhom) VALUES
(1, N'Lập trình'), (1, N'Truyền thông'), (1, N'Sự kiện'),
(2, N'Biểu diễn'), (2, N'Hậu cần');
-- MaNhom: 1 Lập trình, 2 Truyền thông, 3 Sự kiện (CLB 1); 4 Biểu diễn, 5 Hậu cần (CLB 2)

INSERT ThanhVien (MaCLB, MaSV, MaNhom, ChucVu, NgayGiaNhap, TrangThai) VALUES
(1, '2251120011', 1, 'ChuNhiem',            '2025-09-01', 'HoatDong'),      -- MaThanhVien 1
(1, '2251120012', 3, 'NguoiPhuTrachThuChi', '2025-09-01', 'HoatDong'),      -- 2
(1, '2251120013', 1, 'TruongNhom',          '2025-09-05', 'HoatDong'),      -- 3
(1, '2251120014', 1, 'ThanhVien',           '2025-09-10', 'HoatDong'),      -- 4
(1, '2251120015', 2, 'ThanhVien',           '2026-02-20', 'HoatDong'),      -- 5
(1, '2251120016', 2, 'ThanhVien',           '2025-09-10', 'KhongHoatDong'), -- 6 (lâu không tham gia)
(2, '2251120017', 4, 'ChuNhiem',            '2025-09-01', 'HoatDong'),      -- 7
(2, '2251120018', 5, 'NguoiPhuTrachThuChi', '2025-09-01', 'HoatDong'),      -- 8
(2, '2251120019', 4, 'ThanhVien',           '2025-10-01', 'HoatDong'),      -- 9
(2, '2251120020', 5, 'ThanhVien',           '2025-10-01', 'HoatDong');      -- 10

DECLARE @tkCN1 INT = (SELECT MaTK FROM TaiKhoan WHERE TenDangNhap = '2251120011');
DECLARE @tkPT1 INT = (SELECT MaTK FROM TaiKhoan WHERE TenDangNhap = '2251120012');
DECLARE @tkCN2 INT = (SELECT MaTK FROM TaiKhoan WHERE TenDangNhap = '2251120017');
DECLARE @tkPT2 INT = (SELECT MaTK FROM TaiKhoan WHERE TenDangNhap = '2251120018');
DECLARE @tkGV1 INT = (SELECT MaTK FROM TaiKhoan WHERE TenDangNhap = 'GV001');
DECLARE @tkGV2 INT = (SELECT MaTK FROM TaiKhoan WHERE TenDangNhap = 'GV002');

/* ---- Tuyển thành viên ---- */
INSERT DotTuyen (MaCLB, TenDot, NgayBatDau, NgayKetThuc, ChiTieu, TrangThai) VALUES
(1, N'Tuyển thành viên học kỳ 1 năm 2026-2027', '2026-10-15', '2026-11-30', 10, 'DangMo'),
(2, N'Tuyển thành viên Câu lạc bộ Âm nhạc đợt 1', '2026-10-15', '2026-11-30', 8, 'DangMo');

INSERT DonUngTuyen (MaDot, MaSV, MaNhom, GioiThieu, NgayNop, TrangThai, DiemHoSo, GhiChuHoSo, ThoiGianPV, DiaDiemPV, MaNguoiPV) VALUES
(1, '2251120021', 1, N'Em muốn học lập trình web và làm dự án thực tế.', '2026-10-20 09:00', 'DaNop', NULL, NULL, NULL, NULL, NULL),
(1, '2251120022', 2, N'Em thích thiết kế và làm nội dung truyền thông.', '2026-10-21 14:30', 'DatHoSo', 8.50, N'Hồ sơ tốt, có portfolio.', NULL, NULL, NULL),
(1, '2251120020', 1, N'Em muốn tham gia thêm CLB công nghệ.', '2026-10-22 10:15', 'ChoPhongVan', 8.00, N'Đạt hồ sơ.', '2026-11-10 14:00', N'Phòng B203', 3);

/* ---- Hoạt động ---- */
INSERT HoatDong (MaCLB, MaNguoiDeXuat, TenHoatDong, MoTa, DiaDiem, ThoiGianBatDau, ThoiGianKetThuc, SoLuongToiDa, DuToan, TrangThai,
                 ChiPhiThuc, SoThamGiaThucTe, NhanXetTongKet, NgayTongKet) VALUES
(1, 1, N'Workshop Git & GitHub', N'Hướng dẫn làm việc nhóm với Git.', N'Phòng B101', '2026-09-20 18:00', '2026-09-20 20:00', 40, 0, 'DaKetThuc',
    350000, 3, N'Buổi diễn ra tốt, thành viên mới hào hứng.', '2026-09-21 08:00'),                         -- MaHD 1
(1, 2, N'Hackathon CLB 2026', N'Cuộc thi lập trình 24 giờ cho sinh viên.', N'Hội trường A', '2026-12-05 08:00', '2026-12-06 08:00', 30, 5000000, 'DaDuyet',
    NULL, NULL, NULL, NULL),                                                                                -- 2
(1, 2, N'Sinh hoạt định kỳ tháng 11', N'Tổng kết hoạt động tháng và định hướng tháng sau.', N'Phòng B101', '2026-11-15 18:00', '2026-11-15 20:00', NULL, 0, 'ChoDuyet',
    NULL, NULL, NULL, NULL),                                                                                -- 3
(1, 1, N'Training Python cơ bản', N'Chuỗi buổi học Python cho người mới.', N'Phòng B102', '2026-11-20 18:00', '2026-11-20 20:00', 25, 0, 'Nhap',
    NULL, NULL, NULL, NULL),                                                                                -- 4
(2, 7, N'Đêm nhạc Acoustic', N'Đêm nhạc cuối năm của CLB.', N'Sân khấu ngoài trời', '2026-12-12 19:00', '2026-12-12 22:00', 100, 3000000, 'DaDuyet',
    NULL, NULL, NULL, NULL),                                                                                -- 5
(2, 8, N'Giao lưu âm nhạc giữa các khoa', N'Giao lưu và biểu diễn giữa các khoa.', N'Hội trường B', '2026-11-25 18:00', '2026-11-25 21:00', 60, 2000000, 'ChoDuyet',
    NULL, NULL, NULL, NULL),                                                                                -- 6
(1, 1, N'Buổi chia sẻ Cloud cho người mới', N'Chia sẻ kiến thức điện toán đám mây.', N'Phòng B101', '2026-11-10 08:00', '2026-11-10 20:00', 50, 0, 'DangDienRa',
    NULL, NULL, NULL, NULL);                                                                                -- 7

INSERT DuyetHoatDong (MaHD, CapDuyet, MaTKDuyet, KetQua, LyDo, NgayDuyet) VALUES
(1, 1, @tkCN1, 'DongY', NULL, '2026-09-10 09:00'),
(2, 1, @tkCN1, 'DongY', NULL, '2026-11-01 09:00'),
(2, 2, @tkGV1, 'DongY', N'Đồng ý, chú ý an toàn.', '2026-11-02 10:00'),
(3, 1, @tkCN1, 'ChoDuyet', NULL, NULL),
(5, 1, @tkCN2, 'DongY', NULL, '2026-10-25 09:00'),
(5, 2, @tkGV2, 'DongY', NULL, '2026-10-26 09:00'),
(6, 1, @tkCN2, 'DongY', NULL, '2026-11-03 09:00'),
(6, 2, @tkGV2, 'ChoDuyet', NULL, NULL),
(7, 1, @tkCN1, 'DongY', NULL, '2026-10-30 09:00');

INSERT DangKy (MaHD, MaThanhVien, NgayDangKy) VALUES
(1, 3, '2026-09-12 10:00'), (1, 4, '2026-09-12 11:00'), (1, 5, '2026-09-13 08:30'),
(2, 3, '2026-11-02 15:00'), (2, 4, '2026-11-03 09:00'),
(5, 9, '2026-11-01 10:00'), (5, 10, '2026-11-01 10:30'),
(7, 3, '2026-11-01 10:00'), (7, 4, '2026-11-01 10:05'), (7, 5, '2026-11-02 08:00');

/* ---- Điểm danh ---- */
INSERT PhienDiemDanh (MaHD, MaCode, HetHanLuc, ThoiGianMo, ThoiGianDong, TrangThai) VALUES
(1, '482913', NULL, '2026-09-20 18:05', '2026-09-20 19:50', 'Dong'),   -- MaPhien 1
(7, '730215', NULL, '2026-11-10 08:10', NULL, 'Mo');                    -- MaPhien 2 (mã sẽ tự đổi khi hết hạn)

INSERT DiemDanh (MaPhien, MaThanhVien, ThoiGian, HinhThuc, LyDoBoSung, MaTKGhi) VALUES
(1, 3, '2026-09-20 18:10', 'Ma', NULL, NULL),
(1, 4, '2026-09-20 18:12', 'Ma', NULL, NULL),
(1, 5, '2026-09-20 18:40', 'BoSung', N'Có mặt tại buổi nhưng quên nhập mã.', @tkCN1),
(2, 3, '2026-11-10 08:20', 'Ma', NULL, NULL);

/* ---- Ngân sách & thu chi ---- */
INSERT NganSach (MaCLB, MaHD, SoTienDeNghi, SoTienDuocCap, TrangThai, NgayDeXuat, NgayKetQua) VALUES
(1, 2, 5000000, NULL, 'ChoDuyet', '2026-11-03 10:00', NULL),
(2, 5, 3000000, 3000000, 'DuocCap', '2026-10-27 10:00', '2026-11-01 09:00');

INSERT GiaoDich (MaCLB, MaHD, MaTKGhi, Loai, SoTien, NoiDung, NgayGiaoDich) VALUES
(1, NULL, @tkPT1, 'Thu', 2000000, N'Hội phí thành viên đầu kỳ', '2026-09-01'),
(1, NULL, @tkPT1, 'Thu', 3000000, N'Nhà trường hỗ trợ kinh phí hoạt động thường niên', '2026-09-05'),
(1, 1,    @tkPT1, 'Chi',  350000, N'Mua nước và đồ ăn nhẹ cho workshop Git', '2026-09-20'),
(2, NULL, @tkPT2, 'Thu', 1200000, N'Hội phí thành viên đầu kỳ', '2026-09-02'),
(2, 5,    @tkPT2, 'Thu', 3000000, N'Nhà trường cấp kinh phí: Đêm nhạc Acoustic', '2026-11-01'),
(2, 5,    @tkPT2, 'Chi',  800000, N'Đặt cọc thuê âm thanh ánh sáng', '2026-11-03');

/* ---- Tài sản & mượn trả ---- */
INSERT TaiSan (MaCLB, TenTaiSan, LoaiTaiSan, TinhTrang) VALUES
(1, N'Máy chiếu Epson EB-X06', N'Thiết bị trình chiếu', 'Tot'),     -- 1
(1, N'Loa kéo Acnos', N'Thiết bị âm thanh', 'Cu'),                  -- 2
(1, N'Bảng trắng di động', N'Dụng cụ sự kiện', 'Tot'),              -- 3
(1, N'Micro không dây', N'Thiết bị âm thanh', 'HuHong'),            -- 4 (đang hỏng)
(2, N'Bộ trống điện tử', N'Nhạc cụ', 'Tot'),                        -- 5
(2, N'Mixer Yamaha MG10', N'Thiết bị âm thanh', 'Tot');             -- 6

INSERT PhieuMuon (MaTaiSan, MaThanhVien, NgayDangKy, NgayMuon, HanTra, MucDich, MucDoCanGap, TrangThai, MaTKDuyet, NgayGiao, NgayTra, TinhTrangKhiTra) VALUES
(1, 4, '2026-11-04 09:00', '2026-11-06', '2026-11-08', N'Báo cáo đồ án nhóm', 'Thuong', 'ChoDuyet', NULL, NULL, NULL, NULL),
(2, 5, '2026-10-27 08:00', '2026-10-28', '2026-11-02', N'Tổ chức sinh hoạt ngoài trời', 'Gap', 'DangMuon', @tkPT1, '2026-10-28 08:30', NULL, NULL),
(3, 3, '2026-09-17 09:00', '2026-09-18', '2026-09-21', N'Workshop Git', 'Thuong', 'DaTra', @tkPT1, '2026-09-18 09:00', '2026-09-21 10:00', 'Tot'),
(5, 9, '2026-11-04 10:00', '2026-11-10', '2026-11-12', N'Tập luyện cho Đêm nhạc', 'Thuong', 'DaDuyet', @tkPT2, NULL, NULL, NULL);

/* ---- Thông báo ---- */
INSERT ThongBao (MaTKNhan, TieuDe, NoiDung) VALUES
(@tkCN1, N'Có đơn ứng tuyển mới', N'Một sinh viên vừa nộp đơn vào đợt tuyển của CLB.'),
(@tkCN1, N'Hoạt động chờ duyệt', N'Có hoạt động mới đề xuất cần bạn xem xét.'),
(@tkPT1, N'Phiếu mượn tài sản chờ duyệt', N'Có phiếu mượn tài sản mới cần xử lý.'),
(@tkGV2, N'Hoạt động chờ duyệt', N'Có hoạt động mới đề xuất cần bạn xem xét.');

-- Báo cáo nhanh sau khi nạp
SELECT 'SinhVien' AS Bang, COUNT(*) AS SoDong FROM SinhVien UNION ALL
SELECT 'TaiKhoan', COUNT(*) FROM TaiKhoan UNION ALL
SELECT 'ThanhVien', COUNT(*) FROM ThanhVien UNION ALL
SELECT 'HoatDong', COUNT(*) FROM HoatDong UNION ALL
SELECT 'GiaoDich', COUNT(*) FROM GiaoDich UNION ALL
SELECT 'PhieuMuon', COUNT(*) FROM PhieuMuon;
PRINT N'Đã nạp dữ liệu mẫu. Mật khẩu mọi tài khoản: Demo@123';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
