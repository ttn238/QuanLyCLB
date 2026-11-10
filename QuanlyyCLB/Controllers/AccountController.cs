using System.Data;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuanlyyCLB.Services;

namespace QuanlyyCLB.Controllers;

[AllowAnonymous]
public class AccountController : Controller
{
    private readonly Repo _r;
    private readonly ILogger<AccountController> _log;
    public AccountController(Repo r, ILogger<AccountController> log) { _r = r; _log = log; }

    // Chuỗi PBKDF2 hợp lệ dùng để "băm giả" khi tên đăng nhập không tồn tại (cho thời gian phản hồi giống nhau)
    private const string HashGia = "PBKDF2$100000$ZPDailGvbCPwCg1Z0TkUgA==$9gRpkM0FcuTWCf2L5DSmp2DQgOE/Zuf7iinrwr3SxQQ=";

    // Kiểm tra mật khẩu với chuỗi đã lưu dạng PBKDF2$<số vòng>$<salt base64>$<hash base64>
    private static bool KiemTraMatKhau(string? matKhau, string? daLuu)
    {
        if (string.IsNullOrEmpty(matKhau) || matKhau.Length > 200 || string.IsNullOrEmpty(daLuu)) return false;
        var p = daLuu.Split('$');
        if (p.Length != 4 || p[0] != "PBKDF2" || !int.TryParse(p[1], out var soVong) || soVong < 1 || soVong > 1_000_000)
            return false;
        byte[] salt, hashLuu;
        try { salt = Convert.FromBase64String(p[2]); hashLuu = Convert.FromBase64String(p[3]); }
        catch (FormatException) { return false; }
        if (salt.Length == 0 || hashLuu.Length == 0) return false;
        var hashTinh = Rfc2898DeriveBytes.Pbkdf2(Encoding.UTF8.GetBytes(matKhau), salt, soVong,
                                                 HashAlgorithmName.SHA256, hashLuu.Length);
        return CryptographicOperations.FixedTimeEquals(hashTinh, hashLuu);
    }

    [HttpGet]
    public IActionResult Login(string returnUrl)
    {
        ViewBag.ReturnUrl = returnUrl;
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> Login(string tenDangNhap, string matKhau, string returnUrl)
    {
        const string SaiThongTin = "Sai tên đăng nhập hoặc mật khẩu";
        var ten = (tenDangNhap ?? "").Trim();

        DataSet ds;
        try { ds = _r.DangNhap(ten); }
        catch (Exception ex)
        {
            // Chi tiết lỗi chỉ ghi vào log (cửa sổ Output của Visual Studio), không hiện cho người dùng
            _log.LogError(ex, "Không đọc được thông tin đăng nhập của {TenDangNhap}", ten);
            return LoiDangNhap("Không kết nối được CSDL. Vui lòng thử lại sau.", returnUrl);
        }

        if (ds.Tables.Count == 0 || ds.Tables[0].Rows.Count == 0)
        {
            KiemTraMatKhau(matKhau, HashGia);   // băm giả cho thời gian phản hồi giống trường hợp tên đúng
            return LoiDangNhap(SaiThongTin, returnUrl);
        }
        var tk = ds.Tables[0].Rows[0];

        if (!KiemTraMatKhau(matKhau, Convert.ToString(tk["MatKhauHash"])))
            return LoiDangNhap(SaiThongTin, returnUrl);
        if (Convert.ToString(tk["TrangThai"]) != "HoatDong")
            return LoiDangNhap("Tài khoản đã bị khóa", returnUrl);

        int maTK = Convert.ToInt32(tk["MaTK"]);
        string loai = Convert.ToString(tk["LoaiTaiKhoan"]) ?? "";
        var claims = new List<Claim>
        {
            new(ClaimTypes.Name, Convert.ToString(tk["TenDangNhap"]) ?? ""),
            new("HoTen", Convert.ToString(tk["HoTen"]) ?? ""),
            new("MaTK", maTK.ToString())
        };
        if (tk["MaSV"] is not DBNull && !string.IsNullOrWhiteSpace(Convert.ToString(tk["MaSV"])))
            claims.Add(new("MaSV", Convert.ToString(tk["MaSV"])!));

        int maCLB;
        if (loai == "GiangVien")
        {
            claims.Add(new(ClaimTypes.Role, "GiangVien"));
            // Bảng 2: các CLB mà giảng viên làm cố vấn (lấy CLB đầu tiên)
            var cv = ds.Tables.Count > 2 ? ds.Tables[2] : new DataTable();
            maCLB = cv.Rows.Count > 0 ? Convert.ToInt32(cv.Rows[0]["MaCLB"]) : _r.MaCLBMacDinh();
        }
        else if (loai == "QuanTri")
        {
            claims.Add(new(ClaimTypes.Role, "QuanTri"));
            maCLB = _r.MaCLBMacDinh();
        }
        else
        {
            // Sinh viên: bảng 1 là các CLB đang tham gia, TenVaiTro = chức vụ (đã sắp Chủ nhiệm, Phụ trách lên đầu)
            var vt = ds.Tables.Count > 1 ? ds.Tables[1] : new DataTable();
            maCLB = _r.MaCLBMacDinh();
            if (vt.Rows.Count > 0)
            {
                maCLB = Convert.ToInt32(vt.Rows[0]["MaCLB"]);
                claims.Add(new("MaTV", Convert.ToString(vt.Rows[0]["MaThanhVien"]) ?? ""));
            }
            var ten2 = vt.Rows.Cast<DataRow>().Select(r => Convert.ToString(r["TenVaiTro"])).ToList();
            bool quanLy = false;
            if (ten2.Contains("ChuNhiem")) { claims.Add(new(ClaimTypes.Role, "ChuNhiem")); quanLy = true; }
            if (ten2.Contains("NguoiPhuTrachThuChi")) { claims.Add(new(ClaimTypes.Role, "PhuTrach")); quanLy = true; }
            if (!quanLy) claims.Add(new(ClaimTypes.Role, "ThanhVien"));
        }
        claims.Add(new("MaCLB", maCLB.ToString()));

        try { _r.GhiNhanDangNhap(maTK); } catch { /* không để lỗi ghi nhận làm hỏng đăng nhập */ }

        var id = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(id));
        return Redirect(Url.IsLocalUrl(returnUrl) ? returnUrl : "/Dashboard");
    }

    IActionResult LoiDangNhap(string loi, string returnUrl)
    {
        ViewBag.Loi = loi;
        ViewBag.ReturnUrl = returnUrl;
        return View();
    }

    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction("Login");
    }

    public IActionResult Denied() => View();
}