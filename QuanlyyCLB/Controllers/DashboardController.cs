using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuanlyyCLB.Services;

namespace QuanlyyCLB.Controllers;

[Authorize]
public class DashboardController : Controller
{
    private readonly Repo _r;
    public DashboardController(Repo r) { _r = r; }

    public IActionResult Index()
    {
        int clb = User.MaCLB(), tk = User.MaTK(), tv = User.MaTV() ?? 0;
        var t = _r.ThongKe(clb, tv);
        ViewBag.ChoDuyet = t.choDuyet;
        ViewBag.KhongHD = t.khongHD;
        ViewBag.PhieuCho = t.phieuCho;
        ViewBag.SoDu = t.soDu;
        ViewBag.DaThamGia = t.daThamGia;
        ViewBag.SapToi = _r.SapToi(clb, tk);
        return View();
    }
}