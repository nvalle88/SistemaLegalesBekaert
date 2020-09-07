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
    public class CiudadController : Controller
    {
        private readonly SistemasLegalesContext db;
        private readonly UserManager<ApplicationUser> _userManager;

        public CiudadController(SistemasLegalesContext context, UserManager<ApplicationUser> userManager)
        {
            db = context;
            _userManager = userManager;
        }

        public async Task<IActionResult> Index()
        {
            IQueryable<Ciudad> lista=db.Ciudad;
            var resultado = new List<Ciudad>();
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
                    var ciudad = await db.Ciudad.FirstOrDefaultAsync(c => c.IdCiudad == id);
                    if (ciudad == null)
                        return this.Redireccionar($"{Mensaje.Error}|{Mensaje.RegistroNoEncontrado}");
                    if (User.IsInRole(Perfiles.AdministradorEmpresa))
                        if (ciudad.IdEmpresa!=UsuarioAutenticado.IdEmpresa)
                            return this.Redireccionar($"{Mensaje.Error}|{Mensaje.CiudadNoPerteneceEmpresa}", nameof(Index));

                    return View(ciudad);
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
        public async Task<IActionResult> Gestionar(Ciudad ciudad)
        {
            try
            {
                ViewBag.accion = ciudad.IdCiudad == 0 ? "Crear" : "Editar";
                var UsuarioAutenticado = await _userManager.GetUserAsync(User);
              
                if (ModelState.IsValid)
                {
                    var existeRegistro = false;
                    if (ciudad.IdCiudad == 0)
                    {
                        if (!await db.Ciudad.AnyAsync(c => c.Nombre.ToUpper().Trim() == ciudad.Nombre.ToUpper().Trim()
                        && c.IdEmpresa == UsuarioAutenticado.IdEmpresa))
                            db.Add(ciudad);
                        else
                            existeRegistro = true;
                    }
                    else
                    {
                        if (!await db.Ciudad.Where(c => c.Nombre.ToUpper().Trim() == ciudad.Nombre.ToUpper().Trim()
                        && c.IdEmpresa == UsuarioAutenticado.IdEmpresa).AnyAsync(c => c.IdCiudad != ciudad.IdCiudad))
                            db.Update(ciudad);
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
                        return this.VistaError(ciudad, $"{Mensaje.Error}|{Mensaje.ExisteRegistro}");

                    }
                  

                }
                return this.VistaError(ciudad, $"{Mensaje.Error}|{Mensaje.ModeloInvalido}");
            }
            catch (Exception ex)
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
                var ciudad = await db.Ciudad.FirstOrDefaultAsync(m => m.IdCiudad == id);
                if (ciudad != null)
                {
                    if (User.IsInRole(Perfiles.AdministradorEmpresa))
                    {
                        var UsuarioAutenticado = await _userManager.GetUserAsync(User);
                        if (ciudad.IdEmpresa!=UsuarioAutenticado.IdEmpresa)
                            return this.Redireccionar($"{Mensaje.Informacion}|{Mensaje.CiudadNoPerteneceEmpresa}");
                    }
                    db.Ciudad.Remove(ciudad);
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