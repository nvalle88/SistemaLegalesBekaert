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
    public class ProyectoController : Controller
    {
        private readonly SistemasLegalesContext db;
        private readonly UserManager<ApplicationUser> _userManager;

        public ProyectoController(SistemasLegalesContext context, UserManager<ApplicationUser> userManager)
        {
            db = context;
            _userManager = userManager;
        }

        public async Task<IActionResult> Index()
        {
            IQueryable<Proyecto> lista = db.Proyecto;
            var resultado = new List<Proyecto>();
            try
            {
                if (User.IsInRole(Perfiles.AdministradorEmpresa))
                {
                    var UsuarioAutenticado = await _userManager.GetUserAsync(User);
                    lista = lista.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa);
                }
                resultado = await lista.Include(x => x.Empresa).OrderBy(c => c.Nombre).ToListAsync();
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
                    var proyecto = await db.Proyecto.FirstOrDefaultAsync(c => c.IdProyecto == id);
                    if (proyecto == null)
                        return this.Redireccionar($"{Mensaje.Error}|{Mensaje.RegistroNoEncontrado}");

                    return View(proyecto);
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
        public async Task<IActionResult> Gestionar(Proyecto proyecto)
        {
            try
            {
                ViewBag.accion = proyecto.IdProyecto == 0 ? "Crear" : "Editar";
                var UsuarioAutenticado = await _userManager.GetUserAsync(User);
                if (ModelState.IsValid)
                {
                    var existeRegistro = false;
                    if (proyecto.IdProyecto == 0)
                    {
                        if (!await db.Proyecto.AnyAsync(c => c.Nombre.ToUpper().Trim() == proyecto.Nombre.ToUpper().Trim()
                        && c.IdEmpresa == UsuarioAutenticado.IdEmpresa))
                            db.Add(proyecto);
                        else
                            existeRegistro = true;
                    }
                    else
                    {
                        if (!await db.Proyecto.Where(c => c.Nombre.ToUpper().Trim() == proyecto.Nombre.ToUpper().Trim()
                         && c.IdEmpresa == UsuarioAutenticado.IdEmpresa).AnyAsync(c => c.IdProyecto != proyecto.IdProyecto))
                            db.Update(proyecto);
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
                        return this.VistaError(proyecto, $"{Mensaje.Error}|{Mensaje.ExisteRegistro}");

                    }
                }
                return this.VistaError(proyecto, $"{Mensaje.Error}|{Mensaje.ModeloInvalido}");
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
                var proyecto = await db.Proyecto.FirstOrDefaultAsync(m => m.IdProyecto == id);
                if (proyecto != null)
                {
                    db.Proyecto.Remove(proyecto);
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
