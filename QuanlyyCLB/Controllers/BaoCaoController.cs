using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuanlyyCLB.Services;

namespace QuanlyyCLB.Controllers;

[Authorize(Roles = "ChuNhiem,PhuTrach,GiangVien,QuanTri")]
public class BaoCaoController : Controller
{
    private readonly Repo _r;
    public BaoCaoController(Repo r) { _r = r; }

    // Mặc định 90 ngày gần nhất; đổi khoảng ngày trên form
    public IActionResult Index(DateTime? tu, DateTime? den)
    {
        var t = (tu ?? DateTime.Today.AddDays(-90)).Date;
        var d = (den ?? DateTime.Today).Date;
        ViewBag.Tu = t; ViewBag.Den = d;
        try { return View(_r.BaoCao(User.MaCLB(), t, d)); }
        catch (Exception ex) { TempData["err"] = ex.Message; return View(new System.Data.DataSet()); }
    }
}
