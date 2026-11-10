using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuanlyyCLB.Services;

namespace QuanlyyCLB.Controllers;

[Authorize(Roles = "ChuNhiem,PhuTrach")]
public class ThanhVienController : Controller
{
    private readonly Repo _r;
    public ThanhVienController(Repo r) { _r = r; }

    public IActionResult Index(string q, string tt)
    {
        ViewBag.Q = q; ViewBag.Tt = tt;
        ViewBag.Nhom = _r.Nhoms(User.MaCLB());
        return View(_r.ThanhViens(User.MaCLB(), q, tt));
    }

    [HttpPost, Authorize(Roles = "ChuNhiem")]
    public IActionResult Them(string maSV, int? maNhom, string chucVu)
    {
        try { _r.ThemThanhVien(User.MaCLB(), maSV, maNhom, chucVu); TempData["ok"] = "Đã thêm thành viên."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    [HttpPost, Authorize(Roles = "ChuNhiem")]
    public IActionResult Sua(int id, int? maNhom, string chucVu, string trangThai)
    {
        try { _r.CapNhatThanhVien(id, maNhom, chucVu, trangThai); TempData["ok"] = "Đã cập nhật thành viên."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    [HttpPost, Authorize(Roles = "ChuNhiem")]
    public IActionResult ThemNhom(string ten)
    {
        try { _r.ThemNhom(User.MaCLB(), ten); TempData["ok"] = "Đã thêm nhóm."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    // Ngưỡng 180 ngày do CSDL quyết định (bảng ThamSoHeThong); chỉ đánh dấu, không xóa
    [HttpPost, Authorize(Roles = "ChuNhiem")]
    public IActionResult RaSoat()
    {
        try
        {
            int n = _r.RaSoat(User.MaCLB(), User.MaTK());
            TempData["ok"] = n > 0 ? $"Đã đánh dấu {n} thành viên không hoạt động (chỉ đánh dấu, không xóa)." : "Không có thành viên nào vượt ngưỡng.";
        }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    [HttpPost, Authorize(Roles = "ChuNhiem")]
    public IActionResult Roi(int id, string lyDo)
    {
        try { _r.ThanhVienRoi(id, User.MaTK(), lyDo); TempData["ok"] = $"Đã cho thành viên rời CLB. Lý do: {lyDo}"; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }
}