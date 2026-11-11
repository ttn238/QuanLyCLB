using System.Data;
using Microsoft.Data.SqlClient;
using QuanlyyCLB.Models;
using static QuanlyyCLB.Services.Db;

namespace QuanlyyCLB.Services;

public class Repo
{
    private readonly Db _db;
    public Repo(Db db) { _db = db; }

    // ====== Hàm đọc ô dữ liệu an toàn (xử lý NULL) ======
    static string S(DataRow r, string c) => r[c] is DBNull ? "" : Convert.ToString(r[c]) ?? "";
    static int I(DataRow r, string c) => r[c] is DBNull ? 0 : Convert.ToInt32(r[c]);
    static decimal D(DataRow r, string c) => r[c] is DBNull ? 0m : Convert.ToDecimal(r[c]);
    static DateTime T(DataRow r, string c) => r[c] is DBNull ? DateTime.MinValue : Convert.ToDateTime(r[c]);

    // ====== Bảng đổi mã trạng thái trong SQL -> chữ hiển thị trên web ======
    static readonly Dictionary<string, string> HoatDongTT = new()
    {
        ["Nhap"] = "Dự thảo",
        ["ChoDuyet"] = "Chờ duyệt",
        ["DaDuyet"] = "Đã duyệt",
        ["TuChoi"] = "Từ chối",
        ["DangDienRa"] = "Đang diễn ra",
        ["DaKetThuc"] = "Kết thúc",
        ["DaHuy"] = "Đã hủy"
    };
    static readonly Dictionary<string, string> ThanhVienTT = new()
    { ["HoatDong"] = "Đang hoạt động", ["KhongHoatDong"] = "Không hoạt động", ["DaRoi"] = "Đã rời" };
    static readonly Dictionary<string, string> PhieuTT = new()
    {
        ["ChoDuyet"] = "Chờ duyệt",
        ["DaDuyet"] = "Đã duyệt",
        ["TuChoi"] = "Từ chối",
        ["DangMuon"] = "Đang mượn",
        ["DaTra"] = "Đã trả",
        ["TraTre"] = "Trả trễ",
        ["Huy"] = "Đã hủy"
    };
    static readonly Dictionary<string, string> TinhTrangTS = new()
    { ["Tot"] = "Tốt", ["Cu"] = "Cũ", ["HuNhe"] = "Hỏng nhẹ", ["HuHong"] = "Hỏng" };
    static readonly Dictionary<string, string> VaiTroTV = new()
    {
        ["ChuNhiem"] = "Chủ nhiệm",
        ["PhoChuNhiem"] = "Phó chủ nhiệm",
        ["TruongNhom"] = "Trưởng nhóm",
        ["ThanhVien"] = "Thành viên",
        ["NguoiPhuTrachThuChi"] = "Phụ trách thu chi"
    };

    static string Dich(Dictionary<string, string> d, string k) => d.TryGetValue(k, out var v) ? v : k;
    static string DichVaiTro(string s) =>
        string.Join(", ", s.Split(", ", StringSplitOptions.RemoveEmptyEntries).Select(x => Dich(VaiTroTV, x)));
    // Đổi chữ hiển thị ngược lại về mã SQL (dùng khi lọc theo tab / trạng thái)
    static string HoatDongDb(string hienThi) => HoatDongTT.FirstOrDefault(x => x.Value == hienThi).Key ?? "DaDuyet";
    static string ThanhVienDb(string? hienThi) =>
        string.IsNullOrWhiteSpace(hienThi) ? "" : (ThanhVienTT.FirstOrDefault(x => x.Value == hienThi).Key ?? hienThi);

    // =====================================================================
    // ĐĂNG NHẬP
    // =====================================================================

    // Gọi sp_LayThongTinDangNhap: bảng 0 = tài khoản, bảng 1 = vai trò/quyền trong CLB
    public DataSet DangNhap(string tenDangNhap) =>
        _db.Run("sp_LayThongTinDangNhap", true, P("@TenDangNhap", tenDangNhap));

    // Ghi lần đăng nhập cuối
    public void GhiNhanDangNhap(int maTK) => _db.Proc("sp_GhiNhanDangNhap", P("@MaTK", maTK));

    // Giảng viên và quản trị không có dòng ThanhVien, nên lấy CLB qua cố vấn trên CLB.
    public int MaCLBGiangVien(string? maGV)
    {
        var v = _db.Scalar("SELECT TOP 1 MaCLB FROM CLB WHERE MaGVCoVan=@gv ORDER BY MaCLB", P("@gv", maGV));
        return v == null ? MaCLBMacDinh() : Convert.ToInt32(v);
    }
    public int MaCLBMacDinh() => Convert.ToInt32(_db.Scalar("SELECT TOP 1 MaCLB FROM CLB ORDER BY MaCLB") ?? 1);

    // =====================================================================
    // HOẠT ĐỘNG
    // =====================================================================

    // Câu SELECT chung. @tk = tài khoản đang đăng nhập (để biết người đó có lượt duyệt nào đang chờ không)
    const string SelHoatDong = @"
SELECT h.MaHD, h.TenHoatDong, h.DiaDiem, h.MoTa, h.ThoiGianBatDau, ISNULL(h.SoLuongToiDa,0) AS SoLuongToiDa,
       h.TrangThai, sv.MaSV AS NguoiDeXuat,
       h.DuToan,
       (SELECT TOP 1 d.LyDo FROM DuyetHoatDong d WHERE d.MaHD=h.MaHD AND d.KetQua='TuChoi' ORDER BY d.MaDuyet DESC) AS LyDoTuChoi,
       CASE WHEN EXISTS (SELECT 1 FROM PhienDiemDanh p WHERE p.MaHD=h.MaHD AND p.TrangThai='Mo') THEN 1 ELSE 0 END AS PhienMo,
       ISNULL((SELECT TOP 1 d.MaDuyet FROM DuyetHoatDong d WHERE d.MaHD=h.MaHD AND d.MaTKDuyet=@tk AND d.KetQua='ChoDuyet' ORDER BY d.MaDuyet),0) AS MaDuyetCuaToi
FROM HoatDong h
 JOIN ThanhVien tv ON tv.MaThanhVien = h.MaNguoiDeXuat
JOIN SinhVien sv ON sv.MaSV = tv.MaSV";

    static HoatDong MapHD(DataRow r) => new()
    {
        Id = I(r, "MaHD"),
        Ten = S(r, "TenHoatDong"),
        DiaDiem = S(r, "DiaDiem"),
        MoTa = S(r, "MoTa"),
        BatDau = T(r, "ThoiGianBatDau"),
        SoLuongToiDa = I(r, "SoLuongToiDa"),
        DuToan = D(r, "DuToan"),
        NguoiDeXuat = S(r, "NguoiDeXuat"),
        TrangThai = Dich(HoatDongTT, S(r, "TrangThai")),
        LyDoTuChoi = S(r, "LyDoTuChoi"),
        PhienMo = I(r, "PhienMo") == 1,
        MaDuyetCuaToi = I(r, "MaDuyetCuaToi")
    };

    // Điền danh sách người đăng ký và đã điểm danh (mã SV) cho nhiều hoạt động bằng 2 truy vấn
    void GanDanhSach(List<HoatDong> ds)
    {
        if (ds.Count == 0) return;
        var ids = string.Join(",", ds.Select(h => h.Id));   // toàn số nguyên nên không có nguy cơ SQL injection
        var byId = ds.ToDictionary(h => h.Id);
        foreach (DataRow r in _db.Table($@"SELECT d.MaHD, sv.MaSV FROM DangKy d
            JOIN ThanhVien tv ON tv.MaThanhVien=d.MaThanhVien JOIN SinhVien sv ON sv.MaSV=tv.MaSV
            WHERE d.TrangThai='DaDangKy' AND d.MaHD IN ({ids})").Rows)
            byId[I(r, "MaHD")].DangKy.Add(S(r, "MaSV"));
        foreach (DataRow r in _db.Table($@"SELECT DISTINCT p.MaHD, sv.MaSV FROM DiemDanh dd
            JOIN PhienDiemDanh p ON p.MaPhien=dd.MaPhien
            JOIN ThanhVien tv ON tv.MaThanhVien=dd.MaThanhVien JOIN SinhVien sv ON sv.MaSV=tv.MaSV
            WHERE dd.TrangThai='HopLe' AND p.MaHD IN ({ids})").Rows)
            byId[I(r, "MaHD")].DiemDanh.Add(S(r, "MaSV"));
    }

    // Danh sách hoạt động theo tab (Đã duyệt, Chờ duyệt, Dự thảo...). Bản nháp chỉ hiện của chính người đề xuất
    public List<HoatDong> HoatDongTheoTab(int maCLB, int maTK, int maTV, string tab)
    {
        var tt = HoatDongDb(tab);
        var sql = SelHoatDong + " WHERE h.MaCLB=@clb AND h.TrangThai=@tt"
        + (tt == "Nhap" ? " AND h.MaNguoiDeXuat=@tv" : "") + " ORDER BY h.ThoiGianBatDau";
        var ps = new List<SqlParameter> { P("@tk", maTK), P("@clb", maCLB), P("@tt", tt) };
        if (tt == "Nhap") ps.Add(P("@tv", maTV));
        var ds = _db.Table(sql, ps.ToArray()).Rows.Cast<DataRow>().Select(MapHD).ToList();
        GanDanhSach(ds);
        return ds;
    }

    // Hoạt động sắp tới (cho Dashboard)
    public List<HoatDong> SapToi(int maCLB, int maTK)
    {
        var ds = _db.Table(SelHoatDong + " WHERE h.MaCLB=@clb AND h.TrangThai IN ('DaDuyet','DangDienRa') ORDER BY h.ThoiGianBatDau",
                           P("@tk", maTK), P("@clb", maCLB)).Rows.Cast<DataRow>().Select(MapHD).ToList();
        GanDanhSach(ds);
        return ds;
    }

    public HoatDong? GetHoatDong(int id, int maTK)
    {
        var t = _db.Table(SelHoatDong + " WHERE h.MaHD=@id", P("@tk", maTK), P("@id", id));
        if (t.Rows.Count == 0) return null;
        var h = MapHD(t.Rows[0]);
        GanDanhSach(new List<HoatDong> { h });
        return h;
    }

    // Đề xuất hoạt động. Gửi duyệt -> proc tự tạo lượt duyệt theo quy tắc (có kinh phí thì giảng viên duyệt).
    // Lưu nháp -> INSERT trực tiếp trạng thái 'Nhap' (proc luôn tạo trạng thái chờ duyệt nên không dùng được)
    public void DeXuatHoatDong(int maTV, string ten, string? diaDiem, DateTime batDau, int soLuong, decimal duToan, string? moTa, bool nhap)
    {
        var ketThuc = batDau.AddHours(2);          // form chưa có giờ kết thúc, mặc định 2 giờ
        var mota = moTa;
        object? sl = soLuong > 0 ? soLuong : null;

        if (!nhap)
        {
            _db.Proc("sp_DeXuatHoatDong", P("@MaThanhVienDeXuat", maTV), P("@TenHoatDong", ten), P("@MoTa", mota),
                P("@ThoiGianBatDau", batDau), P("@ThoiGianKetThuc", ketThuc), P("@DiaDiem", diaDiem),
                P("@SoLuongToiDa", sl), P("@DuToan", duToan), P("@Nhap", false), Out("@MaHD", SqlDbType.Int));
            return;
        }
        _db.Scalar(@"INSERT HoatDong(MaCLB, MaNguoiDeXuat, TenHoatDong, MoTa, ThoiGianBatDau, ThoiGianKetThuc,
                                     DiaDiem, SoLuongToiDa, DuToan, TrangThai)
                     SELECT tv.MaCLB, tv.MaThanhVien, @ten, @mota, @bd, @kt, @dd, @sl, @duToan, 'Nhap'
                     FROM ThanhVien tv WHERE tv.MaThanhVien=@tv;
                     SELECT CAST(SCOPE_IDENTITY() AS INT);",
            P("@ten", ten), P("@mota", mota), P("@bd", batDau), P("@kt", ketThuc), P("@dd", diaDiem),
            P("@sl", sl), P("@duToan", duToan), P("@tv", maTV));
    }

    // Duyệt / từ chối: xử lý hết các lượt duyệt đang chờ của người này cho hoạt động đó
    public void DuyetHoatDong(int maHD, int maTK, bool dongY, string? lyDo)
    {
        var rows = _db.Table("SELECT MaDuyet FROM DuyetHoatDong WHERE MaHD=@hd AND MaTKDuyet=@tk AND KetQua='ChoDuyet' ORDER BY MaDuyet",
                             P("@hd", maHD), P("@tk", maTK));
        if (rows.Rows.Count == 0) throw new InvalidOperationException("Bạn không có lượt duyệt nào đang chờ cho hoạt động này.");
        foreach (DataRow r in rows.Rows)
        {
            _db.Proc("sp_DuyetHoatDong", P("@MaDuyet", I(r, "MaDuyet")), P("@MaTK", maTK),
                     P("@KetQua", dongY ? "DongY" : "TuChoi"), P("@LyDo", lyDo));
            if (!dongY) break;   // đã từ chối một lượt thì hoạt động bị từ chối, không xử lý tiếp
        }
    }

    public void DangKy(int maTV, int maHD) =>
        _db.Proc("sp_DangKyHoatDong", P("@MaThanhVien", maTV), P("@MaHD", maHD), Out("@MaDangKy", SqlDbType.Int));

    public void HuyDangKy(int maTV, int maHD) =>
        _db.Proc("sp_HuyDangKy", P("@MaThanhVien", maTV), P("@MaHD", maHD));

    // =====================================================================
    // ĐIỂM DANH
    // =====================================================================

    int? PhienDangMo(int maHD)
    {
        var v = _db.Scalar("SELECT TOP 1 MaPhien FROM PhienDiemDanh WHERE MaHD=@hd AND TrangThai='Mo' ORDER BY MaPhien DESC", P("@hd", maHD));
        return v == null ? null : Convert.ToInt32(v);
    }

    // Mở phiên: proc cũng tự chuyển hoạt động từ 'Đã duyệt' sang 'Đang diễn ra' và sinh mã đầu tiên
    public void MoPhien(int maHD, int maTK) =>
        _db.Proc("sp_MoPhienDiemDanh", P("@MaHD", maHD), P("@MaTK", maTK), Out("@MaPhien", SqlDbType.Int), Out("@GiaTriMa", SqlDbType.VarChar, 20));

    public void DongPhien(int maHD)
    {
        var p = PhienDangMo(maHD) ?? throw new InvalidOperationException("Không có phiên điểm danh nào đang mở.");
        _db.Proc("sp_DongPhienDiemDanh", P("@MaPhien", p));
    }

    // Lấy mã đang hiệu lực; nếu hết hạn thì sinh mã mới. Số giây còn lại tính ngay trong SQL để cùng đồng hồ với DB
    public (string ma, int conLai) MaHienTai(int maHD)
    {
        var p = PhienDangMo(maHD);
        if (p == null) return ("------", 0);
        DataRow? Lay()
        {
            var t = _db.Table(@"SELECT MaCode AS GiaTriMa, DATEDIFF(SECOND, SYSDATETIME(), HetHanLuc) AS ConLai
                                FROM PhienDiemDanh WHERE MaPhien=@p", P("@p", p.Value));
            return t.Rows.Count == 0 ? null : t.Rows[0];
        }
        var r = Lay();
        if (r == null || I(r, "ConLai") <= 0)
        {
            _db.Proc("sp_LayMaDiemDanh", P("@MaHD", maHD), Out("@GiaTriMa", SqlDbType.VarChar, 20), Out("@ConLai", SqlDbType.Int));
            r = Lay();
        }
        return r == null ? ("------", 0) : (S(r, "GiaTriMa"), Math.Max(0, I(r, "ConLai")));
    }

    public void DiemDanhBangMa(int maTV, int maHD, string ma) =>
        _db.Proc("sp_DiemDanhBoSung".Replace("BoSung", "BangMa"), P("@MaThanhVien", maTV), P("@MaHD", maHD),
                 P("@GiaTriMa", ma), Out("@MaDiemDanh", SqlDbType.Int));

    // Điểm danh bổ sung do quản lý nhập.
    public void DiemDanhBoSung(int maTV, int maHD, string lyDo, int maTKXacNhan)
    {
        _db.Proc("sp_DiemDanhBoSung", P("@MaThanhVien", maTV), P("@MaHD", maHD), P("@LyDo", lyDo),
                 P("@MaTKGhi", maTKXacNhan), Out("@MaDiemDanh", SqlDbType.Int));
    }

    // Đổi mã sinh viên (tên đăng nhập) sang MaThanhVien trong CLB
    public int? MaThanhVienTheoMSSV(string mssv, int maCLB)
    {
        var v = _db.Scalar("SELECT TOP 1 MaThanhVien FROM ThanhVien WHERE MaSV=@sv AND MaCLB=@clb AND TrangThai<>'DaRoi'",
                           P("@sv", mssv), P("@clb", maCLB));
        return v == null ? null : Convert.ToInt32(v);
    }

    // =====================================================================
    // TÀI SẢN & PHIẾU MƯỢN
    // =====================================================================

    static string IconTS(string loai) =>
        loai.Contains("trình chiếu") ? "bi-projector" : loai.Contains("âm thanh") ? "bi-speaker" : "bi-box-seam";

    // Mỗi dòng TaiSan trong SQL là 1 món đồ: TongSo = 1, ConLai = 1 nếu đang sẵn sàng
    public List<TaiSan> TaiSans(int maCLB) =>
        _db.Table(@"SELECT MaTaiSan, TenTaiSan, LoaiTaiSan, TinhTrang, TrangThaiMuon
                    FROM vw_TaiSanHienTrang
                    WHERE MaCLB=@clb ORDER BY MaTaiSan", P("@clb", maCLB))
          .Rows.Cast<DataRow>().Select(r => new TaiSan
          {
              Id = I(r, "MaTaiSan"),
              Ten = S(r, "TenTaiSan"),
              Ma = "TS-" + I(r, "MaTaiSan").ToString("000"),
              TongSo = 1,
               ConLai = S(r, "TrangThaiMuon") == "SanSang" ? 1 : 0,
              TinhTrang = Dich(TinhTrangTS, S(r, "TinhTrang")),
               Icon = IconTS(S(r, "LoaiTaiSan"))
          }).ToList();

    // maTV = 0: lấy phiếu của cả CLB (người quản lý); maTV > 0: chỉ phiếu của người đó
    public List<PhieuMuon> PhieuMuons(int maCLB, int maTV) =>
        _db.Table(@"SELECT pm.MaPhieu, sv.MaSV, pm.HanTra, pm.MucDoCanGap, pm.TrangThai,
                           ts.TenTaiSan, 1 AS SoLuong, pm.MaTaiSan AS TaiSanId,
                           CASE WHEN pm.TrangThai='DangMuon' THEN pm.MaPhieu ELSE 0 END AS MaChiTiet
                    FROM PhieuMuon pm
                     JOIN TaiSan ts ON ts.MaTaiSan=pm.MaTaiSan
                    JOIN ThanhVien tv ON tv.MaThanhVien=pm.MaThanhVien
                    JOIN SinhVien sv ON sv.MaSV=tv.MaSV
                    WHERE tv.MaCLB=@clb AND (@tv=0 OR pm.MaThanhVien=@tv)
                    ORDER BY pm.NgayDangKy DESC", P("@clb", maCLB), P("@tv", maTV))
          .Rows.Cast<DataRow>().Select(r => new PhieuMuon
          {
              Id = I(r, "MaPhieu"),
              TaiSanId = I(r, "TaiSanId"),
              MaChiTiet = I(r, "MaChiTiet"),
              TenTaiSan = S(r, "TenTaiSan"),
              NguoiMuon = S(r, "MaSV"),
              SoLuong = I(r, "SoLuong"),
              HanTra = T(r, "HanTra"),
              Gap = S(r, "MucDoCanGap") != "Thuong",
              TrangThai = Dich(PhieuTT, S(r, "TrangThai"))
          }).ToList();

    // Mượn trong "soNgay" ngày kể từ hôm nay. Proc kiểm tra ngày, tài sản tồn tại...
    public void DangKyMuon(int maTV, int maTaiSan, int soNgay, bool gap)
    {
        var homNay = DateTime.Today;
        _db.Proc("sp_DangKyMuon", P("@MaThanhVien", maTV), P("@MaTaiSan", maTaiSan), P("@NgayMuon", homNay), P("@HanTra", homNay.AddDays(Math.Max(1, soNgay))),
                 P("@MucDich", "Mượn từ web"), P("@MucDoCanGap", gap ? "Gap" : "Thuong"),
                 Out("@MaPhieu", SqlDbType.Int));
    }

    // Duyệt/từ chối phiếu. Proc bắt buộc có lý do khi từ chối nên điền lý do mặc định
    public void DuyetPhieu(int maPhieu, int maTK, bool dongY) =>
        _db.Proc("sp_DuyetPhieuMuon", P("@MaPhieu", maPhieu), P("@MaTK", maTK), P("@DongY", dongY),
                 P("@LyDo", dongY ? null : "Từ chối bởi người quản lý"));

    // =====================================================================
    // THU CHI
    // =====================================================================

    // Chi tiết thu chi chỉ hiện theo quyền được cấp; tổng thu chi vẫn xem được toàn CLB.
    public List<GiaoDich> GiaoDichs(int maCLB, int maTV, int maTK, bool xemHet) =>
        _db.Table(@"SELECT MaGiaoDich, NgayGiaoDich, NoiDung, Loai, SoTien, NguoiGhi
                    FROM vw_ThuChiChiTiet
                    WHERE MaCLB=@clb AND (@all=1 OR EXISTS (SELECT 1 FROM QuyenXemChiTiet q WHERE q.MaTK=@tk AND q.TrangThai='DaCap' AND (q.PhamVi='CLB' OR (q.PhamVi='HoatDong' AND q.MaHD=vw_ThuChiChiTiet.MaHD))))
                    ORDER BY NgayGiaoDich DESC, MaGiaoDich DESC",
                  P("@clb", maCLB), P("@all", xemHet ? 1 : 0), P("@tv", maTV), P("@tk", maTK))
          .Rows.Cast<DataRow>().Select(r => new GiaoDich
          {
              Id = I(r, "MaGiaoDich"), Ngay = T(r, "NgayGiaoDich"), NoiDung = S(r, "NoiDung"),
              Loai = S(r, "Loai"), SoTien = D(r, "SoTien"), NguoiThucHien = S(r, "NguoiGhi")
          }).ToList();

    // Khoản chi bắt buộc có số chứng từ hoặc lý do thiếu (ràng buộc CK_GiaoDich_ChungTu), form chưa có ô chứng từ nên ghi lý do mặc định
    public void GhiGiaoDich(int maCLB, int maTK, string loai, decimal soTien, string noiDung, int? maHD) =>
        _db.Proc("sp_GhiGiaoDich", P("@MaCLB", maCLB), P("@MaTKGhi", maTK), P("@Loai", loai), P("@SoTien", soTien),
                  P("@NoiDung", noiDung), P("@MaHD", maHD),
                 Out("@MaGiaoDich", SqlDbType.Int));

    // =====================================================================
    // THÀNH VIÊN
    // =====================================================================

    // Đọc từ view vw_ThanhVienChiTiet (đã tính sẵn nhóm, vai trò, số ngày không hoạt động)
    public List<ThanhVien> ThanhViens(int maCLB, string? q, string? tt) =>
        _db.Table(@"SELECT MaThanhVien, HoTen, MaSV, NhomHienTai, VaiTroHienTai, NgayGiaNhap, TrangThai, SoNgayKhongHoatDong
                    FROM vw_ThanhVienChiTiet
                    WHERE MaCLB=@clb
                      AND (@q='' OR HoTen LIKE N'%'+@q+N'%' OR MaSV LIKE '%'+@q+'%')
                      AND (@tt='' OR TrangThai=@tt)
                    ORDER BY HoTen", P("@clb", maCLB), P("@q", q?.Trim() ?? ""), P("@tt", ThanhVienDb(tt)))
          .Rows.Cast<DataRow>().Select(r => new ThanhVien
          {
              Id = I(r, "MaThanhVien"),
              HoTen = S(r, "HoTen"),
              MSSV = S(r, "MaSV"),
              Nhom = S(r, "NhomHienTai"),
              ChucVu = DichVaiTro(S(r, "VaiTroHienTai")),
              NgayThamGia = T(r, "NgayGiaNhap"),
              TrangThai = Dich(ThanhVienTT, S(r, "TrangThai")),
              SoNgayKhongHD = I(r, "SoNgayKhongHoatDong")
          }).ToList();

    // Rà soát: proc đánh dấu "không hoạt động" và trả về danh sách vừa đổi
    public int RaSoat(int maCLB, int maTK)
    {
        var ds = _db.Run("sp_RaSoatThanhVienKhongHoatDong", true, P("@MaCLB", maCLB), P("@MaTK", maTK));
        return ds.Tables.Count == 0 ? 0 : ds.Tables[ds.Tables.Count - 1].Rows.Count;
    }

    // "Cho rời" = đổi trạng thái DaRoi (CSDL không xóa cứng để giữ lịch sử); trigger tự đóng nhóm và vai trò
    public void ThanhVienRoi(int maTV, int maTK, string? lyDo) =>
        _db.Proc("sp_ThanhVienRoiCLB", P("@MaThanhVien", maTV), P("@MaTK", maTK), P("@LyDo", lyDo));

    // =====================================================================
    // DASHBOARD
    // =====================================================================

    public (int choDuyet, int khongHD, int phieuCho, decimal soDu, int daThamGia) ThongKe(int maCLB, int maTV)
    {
        int Dem(string sql, params SqlParameter[] ps) => Convert.ToInt32(_db.Scalar(sql, ps) ?? 0);
        var choDuyet = Dem("SELECT COUNT(*) FROM HoatDong WHERE MaCLB=@c AND TrangThai='ChoDuyet'", P("@c", maCLB));
        var khongHD = Dem(@"SELECT COUNT(*) FROM vw_ThanhVienChiTiet WHERE MaCLB=@c AND TrangThai<>'DaRoi'
                            AND (TrangThai='KhongHoatDong' OR SoNgayKhongHoatDong>180)", P("@c", maCLB));
        var phieuCho = Dem(@"SELECT COUNT(*) FROM PhieuMuon pm JOIN ThanhVien tv ON tv.MaThanhVien=pm.MaThanhVien
                             WHERE tv.MaCLB=@c AND pm.TrangThai='ChoDuyet'", P("@c", maCLB));
        var soDu = Convert.ToDecimal(_db.Scalar("SELECT ISNULL(SUM(ConLai),0) FROM vw_TongThuChiCLB WHERE MaCLB=@c", P("@c", maCLB)) ?? 0m);
        var daThamGia = Dem("SELECT COUNT(*) FROM DiemDanh WHERE MaThanhVien=@tv AND TrangThai='HopLe'", P("@tv", maTV));
        return (choDuyet, khongHD, phieuCho, soDu, daThamGia);
    }

// =====================================================================
    // TASK 2 – DÙNG CHUNG: danh sách cho các ô chọn
    // =====================================================================
    public DataTable Nhoms(int maCLB) =>
        _db.Table("SELECT MaNhom, TenNhom FROM Nhom WHERE MaCLB=@clb ORDER BY TenNhom", P("@clb", maCLB));

    public DataTable HoatDongTen(int maCLB) =>
        _db.Table("SELECT MaHD, TenHoatDong FROM HoatDong WHERE MaCLB=@clb AND TrangThai<>'Nhap' ORDER BY ThoiGianBatDau DESC", P("@clb", maCLB));

    // =====================================================================
    // TASK 2 – TUYỂN THÀNH VIÊN
    // =====================================================================

    // Đợt tuyển đang mở (cho người nộp đơn xem)
    public DataTable DotTuyenMo(int maCLB) =>
        _db.Table("UPDATE DotTuyen SET TrangThai=CASE WHEN CAST(GETDATE() AS DATE)>NgayKetThuc THEN 'DaDong' WHEN CAST(GETDATE() AS DATE)>=NgayBatDau THEN 'DangMo' ELSE 'SapMo' END WHERE MaCLB=@clb; SELECT MaDot, TenDot, NgayBatDau, NgayKetThuc FROM DotTuyen WHERE MaCLB=@clb AND TrangThai='DangMo' ORDER BY NgayBatDau", P("@clb", maCLB));

    public DataTable DotTuyenMo() =>
        _db.Table("UPDATE DotTuyen SET TrangThai=CASE WHEN CAST(GETDATE() AS DATE)>NgayKetThuc THEN 'DaDong' WHEN CAST(GETDATE() AS DATE)>=NgayBatDau THEN 'DangMo' ELSE 'SapMo' END; SELECT MaDot, TenDot, NgayBatDau, NgayKetThuc FROM DotTuyen WHERE TrangThai='DangMo' ORDER BY NgayBatDau");

    // Đơn của chính người đăng nhập (tìm theo MSSV)
    public DataTable DonCuaToi(string maSV) =>
        _db.Table(@"SELECT d.MaDon, dt.TenDot, n.TenNhom, d.NgayNop, d.TrangThai, d.DiemHoSo, d.ThoiGianPV AS ThoiGian, d.DiaDiemPV AS DiaDiem
                    FROM DonUngTuyen d JOIN DotTuyen dt ON dt.MaDot=d.MaDot
                    LEFT JOIN Nhom n ON n.MaNhom=d.MaNhom
                    WHERE d.MaSV=@sv ORDER BY d.NgayNop DESC", P("@sv", maSV));

    // Toàn bộ đơn của CLB kèm buổi phỏng vấn gần nhất (cho Chủ nhiệm xử lý)
    public DataTable DonCuaCLB(int maCLB) =>
        _db.Table(@"SELECT d.MaDon, d.MaSV, sv.HoTen, dt.TenDot, n.TenNhom, d.NgayNop, d.TrangThai, d.DiemHoSo,
                           d.ThoiGianPV, d.DiaDiemPV, d.DiemPV AS KetQua
                    FROM DonUngTuyen d JOIN DotTuyen dt ON dt.MaDot=d.MaDot JOIN SinhVien sv ON sv.MaSV=d.MaSV
                    LEFT JOIN Nhom n ON n.MaNhom=d.MaNhom
                    WHERE dt.MaCLB=@clb ORDER BY d.NgayNop DESC", P("@clb", maCLB));

    public void NopDon(int maDot, string maSV, int? maNhom, string? gioiThieu) =>
        _db.Proc("sp_NopDon", P("@MaDot", maDot), P("@MaSV", maSV), P("@MaNhomNguyenVong", maNhom),
                 P("@GioiThieu", gioiThieu), Out("@MaDon", SqlDbType.Int));

    public void ChamDon(int maDon, int maTK, decimal diem, bool dat, string? ghiChu) =>
        _db.Proc("sp_ChamDon", P("@MaDon", maDon), P("@MaTK", maTK), P("@Diem", diem), P("@Dat", dat), P("@GhiChu", ghiChu));

    public void LenLichPV(int maDon, int maTK, DateTime thoiGian, string diaDiem, int maNguoiPV) =>
        _db.Proc("sp_LenLichPhongVan", P("@MaDon", maDon), P("@MaTK", maTK), P("@ThoiGian", thoiGian), P("@DiaDiem", diaDiem),
                 P("@MaNguoiPV", maNguoiPV));

    // Chốt kết quả: đạt thì proc tự tạo thành viên, vai trò, nhóm và gửi thông báo
    public void ChotPV(int maDon, decimal diem, string? nhanXet, bool dat, int maTK) =>
        _db.Proc("sp_ChotKetQuaPhongVan", P("@MaDon", maDon), P("@Diem", diem), P("@NhanXet", nhanXet),
                 P("@KetQua", dat ? "Dat" : "KhongDat"), P("@MaTKThucHien", maTK));

    // =====================================================================
    // TASK 2 – NGÂN SÁCH
    // =====================================================================

    // Tổng ngân sách + tổng hạn mức các khoản (Chủ nhiệm duyệt)
    public DataTable NganSachs(int maCLB) =>
        _db.Table(@"SELECT ns.MaNganSach, h.TenHoatDong, ns.SoTienDeNghi, ns.SoTienDuocCap, ns.TrangThai,
                           ns.SoTienDeNghi AS TongHanMuc
                    FROM NganSach ns LEFT JOIN HoatDong h ON h.MaHD=ns.MaHD WHERE ns.MaCLB=@clb ORDER BY ns.MaNganSach DESC", P("@clb", maCLB));

    // Hạn mức / đã chi / còn lại từng khoản (view có sẵn)
    public DataTable KhoanNganSachs(int maCLB) =>
        _db.Table("SELECT TenHoatDong AS TenKhoan, SoTienDuocCap AS HanMuc, DaChi, ConLai FROM vw_NganSachSuDung WHERE MaCLB=@clb ORDER BY MaNganSach DESC", P("@clb", maCLB));

    public void DuyetNganSach(int maNganSach, int maTK, bool dongY) =>
        _db.Proc("sp_DuyetNganSach", P("@MaNganSach", maNganSach), P("@MaTK", maTK), P("@DongY", dongY));

    // Hoạt động có kinh phí đã được duyệt hoặc đã có đề nghị ngân sách.
    public DataTable HoatDongKinhPhi(int maCLB) =>
        _db.Table(@"SELECT h.MaHD, h.TenHoatDong, ns.MaNganSach AS MaDeNghi, ns.SoTienDeNghi,
                           ns.TrangThai AS KetQua, ns.SoTienDuocCap
                    FROM HoatDong h LEFT JOIN NganSach ns ON ns.MaHD=h.MaHD
                    WHERE h.MaCLB=@clb AND h.DuToan>0 AND (h.TrangThai='DaDuyet' OR ns.MaNganSach IS NOT NULL)
                    ORDER BY h.ThoiGianBatDau", P("@clb", maCLB));

    public void GuiXinNganSach(int maHD, int maTK, decimal soTien) =>
        _db.Proc("sp_GuiXinNganSach", P("@MaHD", maHD), P("@MaTK", maTK), P("@SoTienDeNghi", soTien), Out("@MaNganSach", SqlDbType.Int));

    // =====================================================================
    // TASK 2 – QUYỀN XEM CHI TIẾT THU CHI
    // =====================================================================

    // Ai là người cấp quyền: trưởng nhóm (nếu xin theo nhóm), còn lại là Chủ nhiệm.
    // Cùng quy tắc với sp_XinQuyenXemChiTiet (nơi gửi thông báo), vì sp_QuyetDinhQuyenXem không tự kiểm tra người cấp.
    const string NguoiCapQuyen = @"
FROM QuyenXemChiTiet q
JOIN ThanhVien tv ON tv.MaThanhVien=q.MaThanhVien
JOIN SinhVien sv ON sv.MaSV=tv.MaSV
LEFT JOIN Nhom n ON n.MaNhom=q.MaNhom
LEFT JOIN HoatDong h ON h.MaHD=q.MaHD
WHERE tv.MaCLB=@clb AND q.TrangThai='ChoDuyet'
       AND (dbo.fn_LaQuanLyCLB(@tk,tv.MaCLB)=1 OR EXISTS
       (SELECT 1 FROM ThanhVien tm JOIN TaiKhoan t ON t.MaSV=tm.MaSV
         WHERE @tk=t.MaTK AND q.PhamVi='Nhom' AND tm.MaNhom=q.MaNhom AND tm.ChucVu='TruongNhom' AND tm.TrangThai<>'DaRoi'))";

    // Tổng thu / tổng chi toàn CLB (thành viên nào cũng được xem)
    public (decimal thu, decimal chi) TongThuChi(int maCLB)
    {
        var t = _db.Table("SELECT ISNULL(SUM(TongThu),0) AS TongThu, ISNULL(SUM(TongChi),0) AS TongChi FROM vw_TongThuChiCLB WHERE MaCLB=@c", P("@c", maCLB));
        return (D(t.Rows[0], "TongThu"), D(t.Rows[0], "TongChi"));
    }

    public DataTable QuyenXemChoToi(int maCLB, int maTK) =>
        _db.Table("SELECT q.MaQuyenXem, sv.HoTen, q.PhamVi, n.TenNhom, h.TenHoatDong, q.LyDoYeuCau " + NguoiCapQuyen + " ORDER BY q.MaQuyenXem",
                  P("@clb", maCLB), P("@tk", maTK));

    public void XinQuyenXem(int maTV, string phamVi, int? maNhom, int? maHD, string lyDo) =>
        _db.Proc("sp_XinQuyenXemChiTiet", P("@MaThanhVien", maTV), P("@PhamVi", phamVi),
                 P("@MaNhom", phamVi == "Nhom" ? maNhom : null), P("@MaHD", phamVi == "HoatDong" ? maHD : null),
                 P("@LyDo", lyDo), Out("@MaQuyenXem", SqlDbType.Int));

    // Cấp / từ chối: kiểm tra đúng người được giao rồi mới gọi proc
    public void QuyetDinhQuyenXem(int maQuyenXem, int maCLB, int maTK, bool dongY)
    {
        var ok = _db.Scalar("SELECT COUNT(*) " + NguoiCapQuyen + " AND q.MaQuyenXem=@id", P("@clb", maCLB), P("@tk", maTK), P("@id", maQuyenXem));
        if (Convert.ToInt32(ok) == 0) throw new InvalidOperationException("Bạn không phải người được giao cấp quyền cho yêu cầu này.");
        _db.Proc("sp_QuyetDinhQuyenXem", P("@MaQuyenXem", maQuyenXem), P("@MaTK", maTK), P("@DongY", dongY));
    }

    // =====================================================================
    // TASK 2 – THÔNG BÁO
    // =====================================================================
    public DataTable ThongBaos(int maTK) =>
        _db.Table(@"SELECT MaTB AS MaNhan, TieuDe, NoiDung, NgayTao, DaDoc
                    FROM ThongBao WHERE MaTKNhan=@tk ORDER BY DaDoc, NgayTao DESC", P("@tk", maTK));

    public int SoThongBaoChuaDoc(int maTK) =>
        Convert.ToInt32(_db.Scalar("SELECT COUNT(*) FROM vw_ThongBaoChuaDoc WHERE MaTK=@tk", P("@tk", maTK)) ?? 0);

    public void DanhDauDaDoc(int maNhan, int maTK) =>
        _db.Proc("sp_DanhDauDaDoc", P("@MaNhan", maNhan), P("@MaTK", maTK));

    // =====================================================================
    // TASK 2 – TÀI SẢN: GIAO, TRẢ, TRỄ HẠN
    // =====================================================================
    public void GiaoTaiSan(int maPhieu, int maTK) =>
        _db.Proc("sp_GiaoTaiSan", P("@MaPhieu", maPhieu), P("@MaTK", maTK));

    public void TraTaiSan(int maPhieu, int maTK, string tinhTrang, string? ghiChu) =>
        _db.Proc("sp_TraTaiSan", P("@MaPhieu", maPhieu), P("@MaTK", maTK), P("@TinhTrangKhiTra", tinhTrang), P("@GhiChu", ghiChu));

    // Proc đánh dấu phiếu quá hạn thành "Trả trễ" và nhắc người mượn (chỉ tác động phiếu mới trễ, chạy lại không sao); rồi lấy danh sách đang trễ
    public DataTable PhieuTreHan(int maCLB)
    {
        _db.Proc("sp_DanhDauMuonTreHan");
        return _db.Table("SELECT MaPhieu, HoTen, HanTra, SoNgayTre, TaiSanChuaTra FROM vw_PhieuMuonTreHan WHERE MaCLB=@clb ORDER BY SoNgayTre DESC", P("@clb", maCLB));
    }

    // =====================================================================
    // TASK 2 – BÁO CÁO CUỐI KỲ (proc trả 6 bảng kết quả)
    // =====================================================================
    public DataSet BaoCao(int maCLB, DateTime tu, DateTime den) =>
        _db.Run("sp_BaoCaoCuoiKy", true, P("@MaCLB", maCLB), P("@TuNgay", tu.Date), P("@DenNgay", den.Date));

    // =====================================================================
    // HOÀN THIỆN – TỔNG KẾT HOẠT ĐỘNG, KẾT QUẢ NGÂN SÁCH, LỊCH SỬ THAM GIA
    // =====================================================================

    // Tổng kết (chốt) hoạt động: proc ghi số người tham gia, chi phí thực và chuyển hoạt động sang "Kết thúc".
    // Kiểm tra hoạt động thuộc CLB đang làm việc vì proc không tự kiểm tra điều này.
    public void TongKetHoatDong(int maHD, int maTK, string? nhanXet)
    {
        _db.Proc("sp_TongKetHoatDong", P("@MaHD", maHD), P("@MaTK", maTK), P("@NhanXet", string.IsNullOrWhiteSpace(nhanXet) ? null : nhanXet.Trim()));
    }

    // Bản tổng kết đã lập của một hoạt động (null nếu chưa có)
    public DataRow? TongKetCuaHD(int maHD)
    {
        var t = _db.Table("SELECT SoThamGiaThucTe, ChiPhiThuc, NhanXetTongKet AS NhanXet, NgayTongKet AS NgayLap FROM HoatDong WHERE MaHD=@hd AND NgayTongKet IS NOT NULL", P("@hd", maHD));
        return t.Rows.Count == 0 ? null : t.Rows[0];
    }

    // Ghi kết quả xét ngân sách của nhà trường cho một đề nghị (thuộc CLB đang làm việc)
    public void GhiKetQuaNganSach(int maDeNghi, int maCLB, int maTK, bool duocCap, decimal? soTien)
    {
        var ok = Convert.ToInt32(_db.Scalar("SELECT COUNT(*) FROM NganSach WHERE MaNganSach=@id AND MaCLB=@clb", P("@id", maDeNghi), P("@clb", maCLB)) ?? 0);
        if (ok == 0) throw new InvalidOperationException("Đề nghị không thuộc CLB của bạn.");
        _db.Proc("sp_GhiNhanKetQuaNganSach", P("@MaNganSach", maDeNghi), P("@MaTK", maTK), P("@KetQua", duocCap ? "DuocCap" : "TuChoi"),
                 P("@SoTienDuocCap", duocCap ? soTien : null));
    }

    // Lịch sử các hoạt động đã điểm danh của một thành viên
    public DataTable LichSuThamGia(int maTV) =>
        _db.Table("SELECT MaThanhVien, MaHD, TenHoatDong, ThoiGianBatDau, HinhThuc, ThoiGian FROM vw_LichSuThamGia WHERE MaThanhVien=@tv ORDER BY ThoiGian DESC", P("@tv", maTV));

    public void ThemThanhVien(int maCLB, string maSV, int? maNhom, string chucVu)
    {
        _db.Scalar(@"IF NOT EXISTS (SELECT 1 FROM SinhVien WHERE MaSV=@sv) THROW 50500, N'Không tìm thấy sinh viên.', 1;
                    IF EXISTS (SELECT 1 FROM ThanhVien WHERE MaCLB=@clb AND MaSV=@sv AND TrangThai<>'DaRoi') THROW 50501, N'Sinh viên đã là thành viên.', 1;
                    IF @nhom IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Nhom WHERE MaNhom=@nhom AND MaCLB=@clb) THROW 50502, N'Nhóm không thuộc CLB.', 1;
                    IF @cv NOT IN ('ChuNhiem','PhoChuNhiem','TruongNhom','ThanhVien','NguoiPhuTrachThuChi','BanTuyen') THROW 50503, N'Chức vụ không hợp lệ.', 1;
                    INSERT ThanhVien(MaCLB,MaSV,MaNhom,ChucVu) VALUES(@clb,@sv,@nhom,@cv); SELECT 1;",
            P("@clb", maCLB), P("@sv", maSV.Trim()), P("@nhom", maNhom), P("@cv", chucVu));
    }

    public void CapNhatThanhVien(int maTV, int? maNhom, string chucVu, string trangThai) =>
        _db.Scalar(@"UPDATE ThanhVien SET MaNhom=@nhom, ChucVu=@cv, TrangThai=@tt,
                    NgayRoi=CASE WHEN @tt='DaRoi' THEN ISNULL(NgayRoi,CAST(GETDATE() AS DATE)) ELSE NULL END
                    WHERE MaThanhVien=@id; SELECT 1;", P("@id", maTV), P("@nhom", maNhom), P("@cv", chucVu), P("@tt", trangThai));

    public void ThemNhom(int maCLB, string ten) =>
        _db.Scalar("INSERT Nhom(MaCLB,TenNhom) VALUES(@clb,@ten); SELECT 1;", P("@clb", maCLB), P("@ten", ten.Trim()));

    public void SuaNhom(int maNhom, int maCLB, string ten) =>
        _db.Scalar("UPDATE Nhom SET TenNhom=@ten WHERE MaNhom=@id AND MaCLB=@clb; SELECT 1;", P("@id", maNhom), P("@clb", maCLB), P("@ten", ten.Trim()));

    public void XoaNhom(int maNhom, int maCLB) =>
        _db.Scalar("IF EXISTS (SELECT 1 FROM ThanhVien WHERE MaNhom=@id) THROW 50510, N'Không thể xóa nhóm đang có thành viên.', 1; DELETE Nhom WHERE MaNhom=@id AND MaCLB=@clb; SELECT 1;", P("@id", maNhom), P("@clb", maCLB));

    public void ThemTaiSan(int maCLB, string ten, string loai, string tinhTrang) =>
        _db.Scalar("INSERT TaiSan(MaCLB,TenTaiSan,LoaiTaiSan,TinhTrang) VALUES(@clb,@ten,@loai,@tt); SELECT 1;", P("@clb", maCLB), P("@ten", ten.Trim()), P("@loai", loai.Trim()), P("@tt", tinhTrang));

    public void TaoDotTuyen(int maCLB, string ten, DateTime batDau, DateTime ketThuc, int? chiTieu) =>
        _db.Scalar("INSERT DotTuyen(MaCLB,TenDot,NgayBatDau,NgayKetThuc,ChiTieu,TrangThai) VALUES(@clb,@ten,@bd,@kt,@ct,CASE WHEN @bd<=CAST(GETDATE() AS DATE) THEN 'DangMo' ELSE 'SapMo' END); SELECT 1;", P("@clb", maCLB), P("@ten", ten.Trim()), P("@bd", batDau.Date), P("@kt", ketThuc.Date), P("@ct", chiTieu));

    public DataTable TaiKhoans() => _db.Table("SELECT MaTK,TenDangNhap,LoaiTaiKhoan,TrangThai,MaSV,MaGV,LanDangNhapCuoi FROM TaiKhoan ORDER BY TenDangNhap");

    public void TaoTaiKhoan(string ten, string hash, string loai, string? maSV, string? maGV) =>
        _db.Scalar("INSERT TaiKhoan(TenDangNhap,MatKhauHash,LoaiTaiKhoan,MaSV,MaGV) VALUES(@ten,@hash,@loai,@sv,@gv); SELECT 1;", P("@ten", ten.Trim()), P("@hash", hash), P("@loai", loai), P("@sv", string.IsNullOrWhiteSpace(maSV) ? null : maSV.Trim()), P("@gv", string.IsNullOrWhiteSpace(maGV) ? null : maGV.Trim()));

    public void DoiTrangThaiTaiKhoan(int maTK, string trangThai) =>
        _db.Scalar("UPDATE TaiKhoan SET TrangThai=@tt WHERE MaTK=@id; SELECT 1;", P("@id", maTK), P("@tt", trangThai));
}
