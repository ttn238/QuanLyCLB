using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuanlyyCLB.Services;

namespace QuanlyyCLB.Controllers;

[Authorize(Roles = "QuanTri")]
public class QuanTriController : Controller
{
    private readonly Repo _repo;
    public QuanTriController(Repo repo) => _repo = repo;

    public IActionResult Index() => View(_repo.TaiKhoans());

    [HttpPost]
    public IActionResult TaoTaiKhoan(string tenDangNhap, string matKhau, string loaiTaiKhoan, string? maSV, string? maGV)
    {
        try { _repo.TaoTaiKhoan(tenDangNhap, Hash(matKhau), loaiTaiKhoan, maSV, maGV); TempData["ok"] = "Đã tạo tài khoản."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    [HttpPost]
    public IActionResult Khoa(int id, bool khoa)
    {
        try { _repo.DoiTrangThaiTaiKhoan(id, khoa ? "Khoa" : "HoatDong"); TempData["ok"] = "Đã cập nhật trạng thái tài khoản."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    private static string Hash(string value)
    {
        if (string.IsNullOrWhiteSpace(value)) throw new ArgumentException("Mật khẩu không được để trống.");
        var salt = RandomNumberGenerator.GetBytes(16);
        var hash = Rfc2898DeriveBytes.Pbkdf2(Encoding.UTF8.GetBytes(value), salt, 100000, HashAlgorithmName.SHA256, 32);
        return $"PBKDF2$100000${Convert.ToBase64String(salt)}${Convert.ToBase64String(hash)}";
    }
}