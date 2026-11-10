using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuanlyyCLB.Services;

namespace QuanlyyCLB.Controllers;

// Xem: Chủ nhiệm, thu chi, giảng viên, quản trị. Gửi xin: Chủ nhiệm, thu chi. Duyệt tổng ngân sách: chỉ Chủ nhiệm
[Authorize(Roles = "ChuNhiem,PhuTrach,GiangVien,QuanTri")]
public class NganSachController : Controller
{
    private readonly Repo _r;
    public NganSachController(Repo r) { _r = r; }

    public IActionResult Index()
    {
        int clb = User.MaCLB();
        ViewBag.Khoan = _r.KhoanNganSachs(clb);
        ViewBag.HoatDong = _r.HoatDongKinhPhi(clb);
        return View(_r.NganSachs(clb));
    }

    [HttpPost, Authorize(Roles = "ChuNhiem")]
    public IActionResult Duyet(int id, bool dong)
    {
        try { _r.DuyetNganSach(id, User.MaTK(), dong); TempData["ok"] = dong ? "Đã duyệt ngân sách." : "Đã từ chối ngân sách."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    // Hoạt động có kinh phí đã được giảng viên duyệt -> lập đề nghị xin nhà trường
    [HttpPost, Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult Xin(int id, decimal soTien)
    {
        if (soTien <= 0) { TempData["err"] = "Số tiền đề nghị phải lớn hơn 0."; return RedirectToAction("Index"); }
        try { _r.GuiXinNganSach(id, User.MaTK(), soTien); TempData["ok"] = "Đã gửi đề nghị xin ngân sách."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    // Ghi kết quả xét ngân sách của nhà trường (được cấp / từ chối)
    [HttpPost, Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult KetQua(int id, bool duocCap, decimal? soTien)
    {
        if (duocCap && (soTien == null || soTien < 0)) { TempData["err"] = "Nhập số tiền được cấp (không âm)."; return RedirectToAction("Index"); }
        try
        {
            _r.GhiKetQuaNganSach(id, User.MaCLB(), User.MaTK(), duocCap, soTien);
            TempData["ok"] = duocCap ? "Đã ghi nhận kết quả: được cấp." : "Đã ghi nhận kết quả: nhà trường từ chối.";
        }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }
}
