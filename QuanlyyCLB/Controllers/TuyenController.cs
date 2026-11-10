using System.Globalization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuanlyyCLB.Services;

namespace QuanlyyCLB.Controllers;

[Authorize]
public class TuyenController : Controller
{
    private readonly Repo _r;
    public TuyenController(Repo r) { _r = r; }

    public IActionResult Index()
    {
        int clb = User.MaCLB();
        ViewBag.Dot = User.MaTV() == null ? _r.DotTuyenMo() : _r.DotTuyenMo(clb);
        ViewBag.Nhom = _r.Nhoms(clb);
        ViewBag.DonCuaToi = _r.DonCuaToi(User.FindFirst("MaSV")?.Value ?? "");
        if (User.IsInRole("ChuNhiem"))
        {
            ViewBag.Don = _r.DonCuaCLB(clb);
            ViewBag.ThanhViens = _r.ThanhViens(clb, null, null).Where(t => t.TrangThai != "Đã rời").ToList();   // người phỏng vấn
        }
        return View();
    }

    [HttpPost, Authorize(Roles = "ChuNhiem")]
    public IActionResult TaoDot(string ten, DateTime ngayBatDau, DateTime ngayKetThuc, int? chiTieu)
    {
        try { _r.TaoDotTuyen(User.MaCLB(), ten, ngayBatDau, ngayKetThuc, chiTieu); TempData["ok"] = "Đã tạo đợt tuyển."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    // Sinh viên nộp đơn (MSSV = tên đăng nhập); proc kiểm tra đợt mở, trùng đơn, đã là thành viên
    [HttpPost]
    public IActionResult Nop(int maDot, int? maNhom, string? gioiThieu)
    {
        try { _r.NopDon(maDot, User.Identity!.Name ?? "", maNhom, gioiThieu); TempData["ok"] = "Đã nộp đơn."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    [HttpPost, Authorize(Roles = "ChuNhiem")]
    public IActionResult Cham(int id, string diem, bool dat, string? ghiChu)
    {
        if (!Diem(diem, out var d)) { TempData["err"] = "Điểm không hợp lệ (từ 0 đến 10)."; return RedirectToAction("Index"); }
        try { _r.ChamDon(id, User.MaTK(), d, dat, ghiChu); TempData["ok"] = "Đã chấm đơn."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    [HttpPost, Authorize(Roles = "ChuNhiem")]
    public IActionResult LenLich(int id, DateTime thoiGian, string diaDiem, int nguoiPV)
    {
        if (nguoiPV <= 0) { TempData["err"] = "Chọn một người phỏng vấn."; return RedirectToAction("Index"); }
        try { _r.LenLichPV(id, User.MaTK(), thoiGian, diaDiem, nguoiPV); TempData["ok"] = "Đã lên lịch phỏng vấn và báo cho ứng viên."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    // id = mã buổi phỏng vấn
    [HttpPost, Authorize(Roles = "ChuNhiem")]
    public IActionResult Chot(int id, string diem, string? nhanXet, bool dat)
    {
        if (!Diem(diem, out var d)) { TempData["err"] = "Điểm không hợp lệ (từ 0 đến 10)."; return RedirectToAction("Index"); }
        try { _r.ChotPV(id, d, nhanXet, dat, User.MaTK()); TempData["ok"] = dat ? "Đã chốt: đạt, ứng viên đã được thêm vào CLB." : "Đã chốt: không đạt."; }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }

    // Điểm nhận dạng chữ để không phụ thuộc dấu thập phân của máy (7.5 hay 7,5)
    static bool Diem(string? s, out decimal d) =>
        decimal.TryParse((s ?? "").Trim().Replace(',', '.'), NumberStyles.Number, CultureInfo.InvariantCulture, out d) && d >= 0 && d <= 10;
}
