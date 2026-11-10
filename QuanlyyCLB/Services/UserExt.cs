using System.Security.Claims;

namespace QuanlyyCLB.Services;

public static class UserExt
{
    // MaTK: khóa tài khoản trong bảng TaiKhoan
    public static int MaTK(this ClaimsPrincipal u) => int.TryParse(u.FindFirstValue("MaTK"), out var v) ? v : 0;

    // MaTV: khóa thành viên; null với giảng viên / quản trị (không phải thành viên CLB)
    public static int? MaTV(this ClaimsPrincipal u) => int.TryParse(u.FindFirstValue("MaTV"), out var v) ? v : null;

    // MaCLB: CLB đang làm việc
    public static int MaCLB(this ClaimsPrincipal u) => int.TryParse(u.FindFirstValue("MaCLB"), out var v) ? v : 1;
}