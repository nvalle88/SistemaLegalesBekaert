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
    public class OrganismoControlController : Controller
    {
        private readonly SistemasLegalesContext db;
        private readonly UserManager<ApplicationUser> _userManager;

        public OrganismoControlController(SistemasLegalesContext context, UserManager<ApplicationUser> userManager)
        {
            db = context;
            _userManager = userManager;
        }

        public async Task<IActionResult> Index()
        {
            IQueryable<OrganismoControl> lista = db.OrganismoControl;
            var resultado = new List<OrganismoControl>();
            try
            {
                if (User.IsInRole(Perfiles.AdministradorEmpresa))
                {
                    var UsuarioAutenticado = await _userManager.GetUserAsync(User);
                    lista = lista.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa);
                }
                resultado =await lista.Include(x=>x.Empresa).OrderBy(c=> c.Nombre).ToListAsync();
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
                    var organismoControl = await db.OrganismoControl.FirstOrDefaultAsync(c => c.IdOrganismoControl == id);
                    if (organismoControl == null)
                        return this.Redireccionar($"{Mensaje.Error}|{Mensaje.RegistroNoEncontrado}");

                    return View(organismoControl);
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
        public async Task<IActionResult> Gestionar(OrganismoControl organismoControl)
        {
            try
            {
                ViewBag.accion = organismoControl.IdOrganismoControl == 0 ? "Crear" : "Editar";
                var UsuarioAutenticado = await _userManager.GetUserAsync(User);
                if (ModelState.IsValid)
                {
                    var existeRegistro = false;
                    if (organismoControl.IdOrganismoControl == 0)
                    {
                        if (!await db.OrganismoControl.AnyAsync(c => c.Nombre.ToUpper().Trim() == organismoControl.Nombre.ToUpper().Trim()
                         && c.IdEmpresa == UsuarioAutenticado.IdEmpresa))
                            db.Add(organismoControl);
                        else
                            existeRegistro = true;
                    }
                    else
                    {
                        if (!await db.OrganismoControl.Where(c => c.Nombre.ToUpper().Trim() == organismoControl.Nombre.ToUpper().Trim()
                        && c.IdEmpresa == UsuarioAutenticado.IdEmpresa).AnyAsync(c => c.IdOrganismoControl != organismoControl.IdOrganismoControl))
                            db.Update(organismoControl);
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
                        return this.VistaError(organismoControl, $"{Mensaje.Error}|{Mensaje.ExisteRegistro}");

                    }
                }
                return this.VistaError(organismoControl, $"{Mensaje.Error}|{Mensaje.ModeloInvalido}");
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
                var organismoControl = await db.OrganismoControl.FirstOrDefaultAsync(m => m.IdOrganismoControl == id);
                if (organismoControl != null)
                {
                    db.OrganismoControl.Remove(organismoControl);
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