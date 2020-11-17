using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SistemasLegales.Models.Entidades;
using SistemasLegales.Models.Extensores;
using SistemasLegales.Models.Utiles;

namespace SistemasLegales.Controllers
{

    [Authorize(Policy = "Administracion")]
    public class EmpresaController : Controller
    {
        private readonly SistemasLegalesContext db;
        private readonly UserManager<ApplicationUser> _userManager;

        public EmpresaController(SistemasLegalesContext context,UserManager<ApplicationUser> userManager)
        {
            db = context;
            _userManager = userManager;
        }

        public async Task<IActionResult> Index()
        {
            IQueryable<Empresa> lista = db.Empresa;
            var resultado = new List<Empresa>();

            try
            {

                if (User.IsInRole(Perfiles.AdministradorEmpresa))
                {
                    var UsuarioAutenticado = await _userManager.GetUserAsync(User);
                    lista = lista.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa);
                }
                resultado = await lista.OrderBy(c => c.Nombre).ToListAsync();
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
                if (id != null)
                {
                    var empresa = await db.Empresa.FirstOrDefaultAsync(c => c.IdEmpresa == id);
                    if (empresa == null)
                        return this.Redireccionar($"{Mensaje.Error}|{Mensaje.RegistroNoEncontrado}");

                    if (User.IsInRole(Perfiles.AdministradorEmpresa))
                        if (empresa.IdEmpresa != UsuarioAutenticado.IdEmpresa)
                            return this.Redireccionar($"{Mensaje.Error}|{Mensaje.EmpresaNoPerteneceEmpresa}", nameof(Index));

                    return View(empresa);
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
        public async Task<IActionResult> Gestionar(Empresa empresa)
        {
            try
            {
                ViewBag.accion = empresa.IdEmpresa == 0 ? "Crear" : "Editar";
                if (ModelState.IsValid)
                {
                    var existeRegistro = false;
                    if (empresa.IdEmpresa == 0)
                    {
                        if (!await db.Empresa.AnyAsync(c => c.Nombre.ToUpper().Trim() == empresa.Nombre.ToUpper().Trim()))
                            db.Add(empresa);
                        else
                            existeRegistro = true;
                    }
                    else
                    {
                        if (!await db.Empresa.Where(c => c.Nombre.ToUpper().Trim() == empresa.Nombre.ToUpper().Trim()).AnyAsync(c => c.IdEmpresa != empresa.IdEmpresa))
                            db.Update(empresa);
                        else
                            existeRegistro = true;
                    }
                    if (!existeRegistro)
                    {
                        await db.SaveChangesAsync();
                        return this.Redireccionar($"{Mensaje.Informacion}|{Mensaje.Satisfactorio}");
                    }
                    else
                        return this.VistaError(empresa, $"{Mensaje.Error}|{Mensaje.ExisteRegistro}");
                }
                return this.VistaError(empresa, $"{Mensaje.Error}|{Mensaje.ModeloInvalido}");
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
                var empresa = await db.Empresa.FirstOrDefaultAsync(m => m.IdEmpresa == id);
                if (empresa != null)
                {
                    if (User.IsInRole(Perfiles.AdministradorEmpresa))
                    {
                        var UsuarioAutenticado = await _userManager.GetUserAsync(User);
                        if (empresa.IdEmpresa != UsuarioAutenticado.IdEmpresa)
                            return this.Redireccionar($"{Mensaje.Informacion}|{Mensaje.CiudadNoPerteneceEmpresa}");
                    }
                    db.Empresa.Remove(empresa);
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