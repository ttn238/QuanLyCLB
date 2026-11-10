using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuanlyyCLB.Services;

namespace QuanlyyCLB.Controllers;

[Authorize]
public class DiemDanhController : Controller
{
    private readonly Repo _r;
    public DiemDanhController(Repo r) { _r = r; }

    [Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult Phien(int id)
    {
        var h = _r.GetHoatDong(id, User.MaTK());
        if (h == null) return NotFound();
        // Danh sách thành viên cho ô chọn "điểm danh bổ sung"
        ViewBag.ThanhViens = _r.ThanhViens(User.MaCLB(), null, null).Where(t => t.TrangThai != "Đã rời").ToList();
        return View(h);
    }

    [HttpPost, Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult Mo(int id)
    {
        try { _r.MoPhien(id, User.MaTK()); }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Phien", new { id });
    }

    [HttpPost, Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult Dong(int id)
    {
        try { _r.DongPhien(id); TempData["ok"] = "Đã đóng phiên điểm danh."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Phien", new { id });
    }

    [HttpPost, Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult BoSung(int id, string tenDangNhap, string lyDo)
    {
        if (string.IsNullOrWhiteSpace(lyDo)) { TempData["err"] = "Điểm danh bổ sung phải có lý do."; return RedirectToAction("Phien", new { id }); }
        var tv = _r.MaThanhVienTheoMSSV(tenDangNhap, User.MaCLB());
        if (tv == null) { TempData["err"] = "Không tìm thấy thành viên."; return RedirectToAction("Phien", new { id }); }
        try { _r.DiemDanhBoSung(tv.Value, id, lyDo, User.MaTK()); TempData["ok"] = "Đã điểm danh bổ sung."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Phien", new { id });
    }

    // Trang quản lý gọi liên tục để lấy mã hiện tại; hết hạn thì tự sinh mã mới
    [Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult MaMoi(int id)
    {
        var (ma, conLai) = _r.MaHienTai(id);
        var h = _r.GetHoatDong(id, User.MaTK());
        return Json(new { ma, conLai, da = h?.DiemDanh.Count ?? 0, tong = h?.DangKy.Count ?? 0, ds = h?.DiemDanh ?? new List<string>() });
    }

    public IActionResult Nhap(int id)
    {
        var h = _r.GetHoatDong(id, User.MaTK());
        return h == null ? NotFound() : View(h);
    }

    [HttpPost]
    public IActionResult Nhap(int id, string ma)
    {
        var h = _r.GetHoatDong(id, User.MaTK());
        if (h == null) return NotFound();
        var tv = User.MaTV();
        if (tv == null) ViewBag.Loi = "Tài khoản này không phải thành viên CLB.";
        else
        {
            try { _r.DiemDanhBangMa(tv.Value, id, (ma ?? "").Trim()); ViewBag.Ok = $"Điểm danh thành công lúc {DateTime.Now:HH:mm}"; }
            catch (Exception ex) { ViewBag.Loi = ex.Message; }   // vd: mã sai/hết hạn, chưa đăng ký, đã điểm danh
        }
        return View(h);
    }
}