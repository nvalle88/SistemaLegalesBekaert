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
    public class ProcesoController : Controller
    {
        private readonly SistemasLegalesContext db;
        private readonly UserManager<ApplicationUser> _userManager;

        public ProcesoController(SistemasLegalesContext context, UserManager<ApplicationUser> userManager)
        {
            db = context;
            _userManager = userManager;
        }

        public async Task<IActionResult> Index()
        {
            IQueryable<Proceso> lista = db.Proceso;
            var resultado = new List<Proceso>();
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
                    var proceso = await db.Proceso.FirstOrDefaultAsync(c => c.IdProceso == id);
                    if (proceso == null)
                        return this.Redireccionar($"{Mensaje.Error}|{Mensaje.RegistroNoEncontrado}");

                    return View(proceso);
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
        public async Task<IActionResult> Gestionar(Proceso proceso)
        {
            try
            {
                ViewBag.accion = proceso.IdProceso == 0 ? "Crear" : "Editar";
                var UsuarioAutenticado = await _userManager.GetUserAsync(User);

                if (ModelState.IsValid)
                {
                    var existeRegistro = false;
                    if (proceso.IdProceso == 0)
                    {
                        if (!await db.Proceso.AnyAsync(c => c.Nombre.ToUpper().Trim() == proceso.Nombre.ToUpper().Trim()
                         && c.IdEmpresa == UsuarioAutenticado.IdEmpresa))
                            db.Add(proceso);
                        else
                            existeRegistro = true;
                    }
                    else
                    {
                        if (!await db.Proceso.Where(c => c.Nombre.ToUpper().Trim() == proceso.Nombre.ToUpper().Trim()
                        && c.IdEmpresa == UsuarioAutenticado.IdEmpresa).AnyAsync(c => c.IdProceso != proceso.IdProceso))
                            db.Update(proceso);
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
                        return this.VistaError(proceso, $"{Mensaje.Error}|{Mensaje.ExisteRegistro}");

                    }
                }
                return this.VistaError(proceso, $"{Mensaje.Error}|{Mensaje.ModeloInvalido}");
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
                var proceso = await db.Proceso.FirstOrDefaultAsync(m => m.IdProceso == id);
                if (proceso != null)
                {
                    db.Proceso.Remove(proceso);
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