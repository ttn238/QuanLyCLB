using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuanlyyCLB.Services;

namespace QuanlyyCLB.Controllers;

[Authorize]
public class HoatDongController : Controller
{
    private readonly Repo _r;
    public HoatDongController(Repo r) { _r = r; }

    public IActionResult Index(string tab = "Đã duyệt")
    {
        if ((tab == "Chờ duyệt" || tab == "Dự thảo") && User.IsInRole("ThanhVien")) tab = "Đã duyệt";
        ViewBag.Tab = tab;
        return View(_r.HoatDongTheoTab(User.MaCLB(), User.MaTK(), User.MaTV() ?? 0, tab));
    }

    public IActionResult ChiTiet(int id)
    {
        var h = _r.GetHoatDong(id, User.MaTK());
        if (h == null) return NotFound();
        ViewBag.TongKet = _r.TongKetCuaHD(id);   // null nếu chưa tổng kết
        return View(h);
    }

    // Lịch sử các hoạt động đã điểm danh của thành viên đang đăng nhập
    public IActionResult LichSu()
    {
        var tv = User.MaTV();
        if (tv == null) { TempData["err"] = "Tài khoản này không phải thành viên CLB."; return RedirectToAction("Index"); }
        return View(_r.LichSuThamGia(tv.Value));
    }

    // Tổng kết hoạt động: chốt số người tham gia, chi phí thực và chuyển sang "Kết thúc"
    [HttpPost, Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult TongKet(int id, string? nhanXet)
    {
        try { _r.TongKetHoatDong(id, User.MaTK(), nhanXet); TempData["ok"] = "Đã tổng kết và kết thúc hoạt động."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("ChiTiet", new { id });
    }

    [Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult DeXuat() => View();

    [HttpPost, Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult DeXuat(string ten, string diaDiem, DateTime batDau, int soLuong, decimal duToan, string moTa, bool nhap)
    {
        var tv = User.MaTV();
        if (tv == null) { TempData["err"] = "Tài khoản này không phải thành viên CLB."; return RedirectToAction("Index"); }
        try
        {
            _r.DeXuatHoatDong(tv.Value, ten, diaDiem, batDau, soLuong, duToan, moTa, nhap);
            TempData["ok"] = nhap ? "Đã lưu nháp." : "Đã gửi duyệt.";
        }
        catch (Exception ex) { TempData["err"] = ex.Message; return RedirectToAction("DeXuat"); }
        return RedirectToAction("Index", new { tab = nhap ? "Dự thảo" : "Chờ duyệt" });
    }

    [HttpPost]
    public IActionResult DangKy(int id)
    {
        var tv = User.MaTV();
        if (tv == null) TempData["err"] = "Tài khoản này không phải thành viên CLB.";
        else
        {
            try { _r.DangKy(tv.Value, id); TempData["ok"] = "Đăng ký thành công."; }
            catch (Exception ex) { TempData["err"] = ex.Message; }
        }
        return RedirectToAction("ChiTiet", new { id });
    }

    [HttpPost]
    public IActionResult HuyDangKy(int id)
    {
        var tv = User.MaTV();
        if (tv == null) TempData["err"] = "Tài khoản này không phải thành viên CLB.";
        else
        {
            try { _r.HuyDangKy(tv.Value, id); TempData["ok"] = "Đã hủy đăng ký."; }
            catch (Exception ex) { TempData["err"] = ex.Message; }
        }
        return RedirectToAction("ChiTiet", new { id });
    }

    // Chủ nhiệm hoặc Giảng viên; CSDL kiểm tra đúng người được giao duyệt
    [HttpPost, Authorize(Roles = "ChuNhiem,GiangVien")]
    public IActionResult Duyet(int id, bool dong, string lyDo)
    {
        if (!dong && string.IsNullOrWhiteSpace(lyDo)) { TempData["err"] = "Từ chối phải nhập lý do."; return RedirectToAction("ChiTiet", new { id }); }
        try
        {
            _r.DuyetHoatDong(id, User.MaTK(), dong, lyDo);
            TempData["ok"] = dong ? "Đã duyệt hoạt động." : "Đã từ chối hoạt động.";
        }
        catch (Exception ex) { TempData["err"] = ex.Message; return RedirectToAction("ChiTiet", new { id }); }
        return RedirectToAction("Index", new { tab = "Chờ duyệt" });
    }
}