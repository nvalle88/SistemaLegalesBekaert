using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using SistemasLegales.Models.Entidades;
using SistemasLegales.Models.Extensores;
using SistemasLegales.Models.Utiles;

namespace SistemasLegales.Controllers
{
    [Authorize(Policy = "Administracion")]
    public class ActorController : Controller
    {
        private readonly SistemasLegalesContext db;
        private readonly UserManager<ApplicationUser> _userManager;
        public ActorController(SistemasLegalesContext context, UserManager<ApplicationUser> userManager)
        {
            db = context;
            _userManager = userManager;
        }

        public async Task<IActionResult> Index()
        {
            IQueryable<Actor> lista = db.Actor;
            var resultado = new List<Actor>();
            try
            {
                if (User.IsInRole(Perfiles.AdministradorEmpresa))
                {
                    var UsuarioAutenticado = await _userManager.GetUserAsync(User);
                    lista = lista.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa);
                }
                resultado = await lista.Include(x => x.Empresa).OrderBy(c => c.Nombres).ToListAsync();
            }
            catch (Exception)
            {
                TempData["Mensaje"] = $"{Mensaje.Error}|{Mensaje.ErrorListado}";
            }
            return View(resultado);
        }
        
        public async Task<IActionResult> Gestionar(int? id)
        {
            try
            {
                ViewBag.accion = id == null ? "Crear" : "Editar";

                var UsuarioAutenticado = await _userManager.GetUserAsync(User);

                if (User.IsInRole(Perfiles.AdministradorEmpresa))
                    ViewData["Empresas"] = new SelectList(db.Empresa.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa).OrderBy(x => x.Nombre).ToList(), "IdEmpresa", "Nombre");
                else
                    ViewData["Empresas"] = new SelectList(db.Empresa.OrderBy(x => x.Nombre).ToList(), "IdEmpresa", "Nombre");

                if (id != null)
                {
                    var actor = await db.Actor.FirstOrDefaultAsync(c => c.IdActor == id);
                    if (actor == null)
                        return this.Redireccionar($"{Mensaje.Error}|{Mensaje.RegistroNoEncontrado}");

                    return View(actor);
                }
                return View();
            }
            catch (Exception)
            {
                return this.Redireccionar($"{Mensaje.Error}|{Mensaje.ErrorCargarDatos}");
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Gestionar(Actor actor)
        {
            try
            {
                ViewBag.accion = actor.IdActor == 0 ? "Crear" : "Editar";
                var UsuarioAutenticado = await _userManager.GetUserAsync(User);
                if (ModelState.IsValid)
                {
                    var existeRegistro = false;
                    if (actor.IdActor == 0)
                    {
                        if (!await db.Actor.AnyAsync(c => c.Nombres.ToUpper().Trim() == actor.Nombres.ToUpper().Trim()
                        && c.IdEmpresa == UsuarioAutenticado.IdEmpresa))
                            db.Add(actor);
                        else
                            existeRegistro = true;
                    }
                    else
                    {
                        if (!await db.Actor.Where(c => c.Nombres.ToUpper().Trim() == actor.Nombres.ToUpper().Trim()
                        && c.IdEmpresa == UsuarioAutenticado.IdEmpresa).AnyAsync(c => c.IdActor != actor.IdActor))
                            db.Update(actor);
                        else
                            existeRegistro = true;
                    }
                    if (!existeRegistro)
                    {
                        await db.SaveChangesAsync();
                        return this.Redireccionar($"{Mensaje.Informacion}|{Mensaje.Satisfactorio}");
                    }
                    else
                    {
                        if (User.IsInRole(Perfiles.AdministradorEmpresa))
                            ViewData["Empresas"] = new SelectList(db.Empresa.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa).OrderBy(x => x.Nombre).ToList(), "IdEmpresa", "Nombre");
                        else
                            ViewData["Empresas"] = new SelectList(db.Empresa.OrderBy(x => x.Nombre).ToList(), "IdEmpresa", "Nombre");
                        return this.VistaError(actor, $"{Mensaje.Error}|{Mensaje.ExisteRegistro}");

                    }
                }
                return this.VistaError(actor, $"{Mensaje.Error}|{Mensaje.ModeloInvalido}");
            }
            catch (Exception)
            {
                return this.Redireccionar($"{Mensaje.Error}|{Mensaje.Excepcion}");
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Eliminar(int id)
        {
            try
            {
                var actor = await db.Actor.FirstOrDefaultAsync(m => m.IdActor == id);
                if (actor != null)
                {
                    db.Actor.Remove(actor);
                    await db.SaveChangesAsync();
                    return this.Redireccionar($"{Mensaje.Informacion}|{Mensaje.Satisfactorio}");
                }
                return this.Redireccionar($"{Mensaje.Error}|{Mensaje.RegistroNoEncontrado}");
            }
            catch (Exception)
            {
                return this.Redireccionar($"{Mensaje.Error}|{Mensaje.BorradoNoSatisfactorio}");
            }
        }
    }
}