using System.Globalization;

namespace QuanlyyCLB.Services;

public static class Ui
{
    public static string Badge(string tt) => tt switch
    {
        "Dự thảo" => "bg-secondary",
        "Chờ duyệt" => "bg-warning text-dark",
        "Đã duyệt" => "bg-success",
        "Đang diễn ra" => "bg-info text-dark",
        "Kết thúc" => "badge-dark",
        "Từ chối" => "bg-danger",
        "Đã hủy" => "bg-secondary",
        "Đang hoạt động" => "bg-success",
        "Không hoạt động" => "bg-warning text-dark",
        "Đã rời" => "bg-secondary",
        "Tốt" => "bg-success",
        "Cũ" => "bg-warning text-dark",
        "Hỏng nhẹ" => "bg-warning text-dark",
        "Hỏng" => "bg-danger",
        "Đang mượn" => "bg-info text-dark",
        "Đã trả" => "bg-success",
        "Trả trễ" => "bg-danger",
        "Đạt hồ sơ" or "Đạt" or "Được cấp" => "bg-success",
        "Không đạt hồ sơ" or "Không đạt" => "bg-danger",
        "Chờ phỏng vấn" => "bg-info text-dark",
        "Chờ kết quả" => "bg-warning text-dark",
        _ => "bg-secondary"
    };

    public static string Tien(decimal v) =>
        string.Format(CultureInfo.GetCultureInfo("vi-VN"), "{0:N0} đ", v);

    public static string TenVaiTro(string v) => v switch
    {
        "ChuNhiem" => "Chủ nhiệm",
        "PhuTrach" => "Phụ trách thu chi/tài sản",
        "GiangVien" => "Giảng viên cố vấn",
        "QuanTri" => "Quản trị hệ thống",
        _ => "Thành viên"
    };
    // Đổi mã trạng thái SQL sang chữ hiển thị trên web.
    public static string Nhan(object? ma) => Convert.ToString(ma) switch
    {
        "DaNop" => "Đã nộp", "DatHoSo" => "Đạt hồ sơ", "KhongDatHoSo" => "Không đạt hồ sơ",
        "ChoPhongVan" => "Chờ phỏng vấn", "Dat" => "Đạt", "KhongDat" => "Không đạt",
        "DaRut" => "Đã rút", "ChuaCo" => "Chưa có kết quả",
        "Nhap" => "Nháp", "ChoDuyet" => "Chờ duyệt", "DaDuyet" => "Đã duyệt", "TuChoi" => "Từ chối",
        "ChoKetQua" => "Chờ kết quả", "DuocCap" => "Được cấp",
        "DangDienRa" => "Đang diễn ra", "DaKetThuc" => "Kết thúc", "DaHuy" => "Đã hủy",
        "Nhom" => "Nhóm", "HoatDong" => "Hoạt động", "CLB" => "Toàn CLB",
        var s => s ?? ""
    };
}
