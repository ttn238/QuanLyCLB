using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuanlyyCLB.Services;

namespace QuanlyyCLB.Controllers;

[Authorize]
public class ThongBaoController : Controller
{
    private readonly Repo _r;
    public ThongBaoController(Repo r) { _r = r; }

    public IActionResult Index() => View(_r.ThongBaos(User.MaTK()));

    [HttpPost]
    public IActionResult DaDoc(int id)
    {
        try { _r.DanhDauDaDoc(id, User.MaTK()); }
        catch (Exception ex) { TempData["err"] = ex.Message; }
        return RedirectToAction("Index");
    }
}
