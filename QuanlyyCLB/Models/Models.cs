namespace QuanlyyCLB.Models;

public class ThanhVien
{
    public int Id { get; set; }
    public string HoTen { get; set; }
    public string MSSV { get; set; }
    public string Nhom { get; set; }
    public string ChucVu { get; set; }
    public DateTime NgayThamGia { get; set; }
    public string TrangThai { get; set; } // Đang hoạt động | Không hoạt động | Đã rời
    public int SoNgayKhongHD { get; set; }
}

public class HoatDong
{
    public int Id { get; set; }
    public string Ten { get; set; }
    public string DiaDiem { get; set; }
    public string MoTa { get; set; }
    public DateTime BatDau { get; set; }
    public int SoLuongToiDa { get; set; }
    public decimal DuToan { get; set; }
    public string NguoiDeXuat { get; set; }
    public string TrangThai { get; set; } // Dự thảo | Chờ duyệt | Đã duyệt | Đang diễn ra | Kết thúc | Từ chối
    public string LyDoTuChoi { get; set; }
    public List<string> DangKy { get; set; } = new();
    public List<string> DiemDanh { get; set; } = new();
    public bool PhienMo { get; set; }
    public string MaDiemDanh { get; set; }
    public DateTime MaHetHan { get; set; }
    public int MaDuyetCuaToi { get; set; }   // > 0 nếu người đang đăng nhập có lượt duyệt đang chờ
}

public class GiaoDich
{
    public int Id { get; set; }
    public DateTime Ngay { get; set; }
    public string NoiDung { get; set; }
    public string Loai { get; set; } // Thu | Chi
    public decimal SoTien { get; set; }
    public string NguoiThucHien { get; set; }
}

public class TaiSan
{
    public int Id { get; set; }
    public string Ten { get; set; }
    public string Ma { get; set; }
    public int TongSo { get; set; }
    public int ConLai { get; set; }
    public string TinhTrang { get; set; } // Tốt | Hỏng
    public string Icon { get; set; }
}

public class PhieuMuon
{
    public int Id { get; set; }
    public int TaiSanId { get; set; }
    public string TenTaiSan { get; set; }
    public string NguoiMuon { get; set; }
    public int SoLuong { get; set; }
    public DateTime HanTra { get; set; }
    public bool Gap { get; set; }
    public string TrangThai { get; set; } // Chờ duyệt | Đã duyệt | Từ chối
    public int MaChiTiet { get; set; }   // > 0 nếu còn tài sản đã giao chưa trả
}