using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuanlyyCLB.Services;

namespace QuanlyyCLB.Controllers;

[Authorize]
public class ThuChiController : Controller
{
    private readonly Repo _r;
    public ThuChiController(Repo r) { _r = r; }

    public IActionResult Index()
    {
        int clb = User.MaCLB();
        var (thu, chi) = _r.TongThuChi(clb);
        ViewBag.Thu = thu; ViewBag.Chi = chi;                       // tổng toàn CLB
        ViewBag.Nhom = _r.Nhoms(clb);                               // ô chọn trong form xin quyền
        ViewBag.HoatDong = _r.HoatDongTen(clb);
        ViewBag.ChoCap = _r.QuyenXemChoToi(clb, User.MaTK());       // yêu cầu đang chờ người này cấp
        bool xemHet = User.IsInRole("GiangVien") || User.IsInRole("QuanTri") || User.IsInRole("ChuNhiem") || User.IsInRole("PhuTrach");
        return View(_r.GiaoDichs(clb, User.MaTV() ?? 0, User.MaTK(), xemHet));
    }

    [HttpPost, Authorize(Roles = "ChuNhiem,PhuTrach")]
    public IActionResult Ghi(string loai, decimal soTien, string noiDung, int? maHD)
    {
        if (soTien <= 0 || string.IsNullOrWhiteSpace(noiDung)) { TempData["err"] = "Nhập đủ số tiền và nội dung."; return RedirectToAction("Index"); }
        try { _r.GhiGiaoDich(User.MaCLB(), User.MaTK(), loai, soTien, noiDung, maHD); TempData["ok"] = "Đã ghi giao dịch."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    // Thành viên xin xem chi tiết theo nhóm / hoạt động / toàn CLB
    [HttpPost]
    public IActionResult XinQuyen(string phamVi, int? maNhom, int? maHD, string lyDo)
    {
        var tv = User.MaTV();
        if (tv == null) TempData["err"] = "Tài khoản này không phải thành viên CLB.";
        else if (string.IsNullOrWhiteSpace(lyDo)) TempData["err"] = "Hãy nhập lý do xin xem chi tiết.";
        else if ((phamVi == "Nhom" && maNhom == null) || (phamVi == "HoatDong" && maHD == null)) TempData["err"] = "Hãy chọn nhóm hoặc hoạt động tương ứng với phạm vi.";
        else
        {
            try { _r.XinQuyenXem(tv.Value, phamVi, maNhom, maHD, lyDo); TempData["ok"] = "Đã gửi yêu cầu, chờ người có thẩm quyền cấp quyền."; }
            catch (Exception ex) { TempData["err"] = ex.Message; }
        }
        return RedirectToAction("Index");
    }

    // Người cấp quyền (trưởng nhóm hoặc Chủ nhiệm) cấp / từ chối; Repo kiểm tra đúng người
    [HttpPost]
    public IActionResult CapQuyen(int id, bool dong)
    {
        try { _r.QuyetDinhQuyenXem(id, User.MaCLB(), User.MaTK(), dong); TempData["ok"] = dong ? "Đã cấp quyền xem chi tiết." : "Đã từ chối yêu cầu."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }
}
