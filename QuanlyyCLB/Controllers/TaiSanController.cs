using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuanlyyCLB.Services;

namespace QuanlyyCLB.Controllers;

[Authorize]
public class TaiSanController : Controller
{
    private readonly Repo _r;
    public TaiSanController(Repo r) { _r = r; }

    public IActionResult Index()
    {
        bool quanLy = !User.IsInRole("ThanhVien");
        ViewBag.TreHan = _r.PhieuTreHan(User.MaCLB());
        ViewBag.Phieus = _r.PhieuMuons(User.MaCLB(), quanLy ? 0 : (User.MaTV() ?? -1));
        return View(_r.TaiSans(User.MaCLB()));
    }

    [HttpPost, Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult Them(string ten, string loai, string tinhTrang = "Tot")
    {
        try { _r.ThemTaiSan(User.MaCLB(), ten, loai, tinhTrang); TempData["ok"] = "Đã thêm tài sản."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    // soLuong giữ lại để khớp form; mỗi tài sản trong CSDL là 1 món nên không dùng
    [HttpPost]
    public IActionResult Muon(int id, int soLuong, int soNgay, bool gap)
    {
        var tv = User.MaTV();
        if (tv == null) { TempData["err"] = "Tài khoản này không phải thành viên CLB."; return RedirectToAction("Index"); }
        try { _r.DangKyMuon(tv.Value, id, soNgay, gap); TempData["ok"] = "Đã gửi yêu cầu mượn, chờ duyệt."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    [HttpPost, Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult DuyetPhieu(int id, bool dong)
    {
        try { _r.DuyetPhieu(id, User.MaTK(), dong); TempData["ok"] = dong ? "Đã duyệt phiếu mượn." : "Đã từ chối phiếu mượn."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    // Giao tài sản cho người mượn (phiếu phải đã duyệt).
    [HttpPost, Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult Giao(int id)
    {
        try { _r.GiaoTaiSan(id, User.MaTK()); TempData["ok"] = "Đã giao tài sản."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    // Nhận trả một món và ghi tình trạng khi trả.
    [HttpPost, Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult Tra(int id, string tinhTrang, string? ghiChu)
    {
        try { _r.TraTaiSan(id, User.MaTK(), tinhTrang, ghiChu); TempData["ok"] = "Đã nhận trả tài sản."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }
}