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
    public class RequisitoLegalController : Controller
    {
        private readonly SistemasLegalesContext db;
        private readonly UserManager<ApplicationUser> _userManager;
        public RequisitoLegalController(SistemasLegalesContext context, UserManager<ApplicationUser> userManager)
        {
            db = context;
            _userManager = userManager;
        }

        public async Task<IActionResult> Index()
        {
            IQueryable<RequisitoLegal> lista = db.RequisitoLegal;
            var resultado = new List<RequisitoLegal>();
            try
            {
                if (User.IsInRole(Perfiles.AdministradorEmpresa))
                {
                    var UsuarioAutenticado = await _userManager.GetUserAsync(User);
                    lista = lista.Where(x => x.OrganismoControl.Empresa.IdEmpresa == UsuarioAutenticado.IdEmpresa);
                }
                resultado = await lista.Include(c=> c.OrganismoControl).ThenInclude(x=>x.Empresa).OrderBy(c => c.Nombre).ToListAsync();
            }
            catch (Exception ex)
            {
                TempData["Mensaje"] = $"{Mensaje.Error}|{Mensaje.ErrorListado}";
            }
            return View(resultado);
        }


        public async Task<JsonResult> ObtenerOrganismoControlPorEmpresa(int idEmpresa)
        {
            try
            {
                var listaOrganismoControl= await db.OrganismoControl
                    .Where(x => x.IdEmpresa == idEmpresa)
                    .OrderBy(c => c.Nombre).ToListAsync();

                return Json(listaOrganismoControl);
            }
            catch (Exception)
            {
                return new JsonResult(new List<OrganismoControl>());
            }
        }

        public async Task<IActionResult> Gestionar(int? id)
        {
            try
            {
                ViewBag.accion = id == null ? "Crear" : "Editar";

                var UsuarioAutenticado = await _userManager.GetUserAsync(User);

                var ListaEmpresas = db.Empresa.ToList();
                var ListaOrganismoControl = db.OrganismoControl.ToList();
                if (User.IsInRole(Perfiles.AdministradorEmpresa))
                {
                    ListaEmpresas = ListaEmpresas.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa).ToList();
                    ListaOrganismoControl = ListaOrganismoControl.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa).ToList();
                }

                var primeraEmpresa = ListaEmpresas.FirstOrDefault();

                ViewData["Empresas"] = new SelectList(ListaEmpresas
                    .OrderBy(x => x.Nombre)
                    .ToList(), 
                    "IdEmpresa", "Nombre",
                    primeraEmpresa.IdEmpresa);

                ViewData["OrganismoControl"] = new SelectList(ListaOrganismoControl
                    .Where(x=>x.IdEmpresa==primeraEmpresa.IdEmpresa)
                    .OrderBy(c => c.Nombre).ToList(), 
                    "IdOrganismoControl", "Nombre");

                if (id != null)
                {
                    var requisitoLegal = await db.RequisitoLegal.Include(c => c.OrganismoControl).ThenInclude(x => x.Empresa).FirstOrDefaultAsync(c => c.IdRequisitoLegal == id);
                    if (requisitoLegal == null)
                        return this.Redireccionar($"{Mensaje.Error}|{Mensaje.RegistroNoEncontrado}");

                    var OrganismoControl =  ListaOrganismoControl
                        .Where(x => x.IdOrganismoControl == requisitoLegal.IdOrganismoControl).FirstOrDefault();

                    requisitoLegal.IdEmpresa = OrganismoControl.IdEmpresa ?? 0;
                    
                    ViewData["Empresas"] = new SelectList(ListaEmpresas.OrderBy(x => x.Nombre).ToList(),"IdEmpresa", "Nombre",OrganismoControl.IdEmpresa);

                    ViewData["OrganismoControl"] = new SelectList(ListaOrganismoControl.Where(x => x.IdEmpresa == OrganismoControl.IdEmpresa).OrderBy(c => c.Nombre).ToList(),"IdOrganismoControl", "Nombre", selectedValue: requisitoLegal.IdOrganismoControl);

                    return View(requisitoLegal);
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
        public async Task<IActionResult> Gestionar(RequisitoLegal requisitoLegal)
        {
            try
            {
                ViewBag.accion = requisitoLegal.IdRequisitoLegal == 0 ? "Crear" : "Editar";
                var UsuarioAutenticado = await _userManager.GetUserAsync(User);
                var ListaEmpresas = new List<Empresa>();
                var ListaOrganismoControl = new List<OrganismoControl>();
                var OrganismoControl= new OrganismoControl();

                if (ModelState.IsValid)
                {
                    var existeRegistro = false;
                    if (requisitoLegal.IdRequisitoLegal == 0)
                    {
                        if (!await db.RequisitoLegal.AnyAsync(c => c.Nombre.ToUpper().Trim() == requisitoLegal.Nombre.ToUpper().Trim() && c.IdOrganismoControl == requisitoLegal.IdOrganismoControl))
                            db.Add(requisitoLegal);
                        else
                            existeRegistro = true;
                    }
                    else
                    {
                        if (!await db.RequisitoLegal.Where(c => c.Nombre.ToUpper().Trim() == requisitoLegal.Nombre.ToUpper().Trim() && c.IdOrganismoControl == requisitoLegal.IdOrganismoControl).AnyAsync(c => c.IdRequisitoLegal != requisitoLegal.IdRequisitoLegal))
                            db.Update(requisitoLegal);
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
                       
                        if (requisitoLegal == null)
                            return this.Redireccionar($"{Mensaje.Error}|{Mensaje.RegistroNoEncontrado}");

                         ListaEmpresas = db.Empresa.ToList();
                        ListaOrganismoControl = db.OrganismoControl.ToList();

                        if (User.IsInRole(Perfiles.AdministradorEmpresa))
                        {
                            ListaEmpresas = ListaEmpresas.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa).ToList();
                            ListaOrganismoControl = ListaOrganismoControl.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa).ToList();
                        }

                        OrganismoControl = ListaOrganismoControl
                        .Where(x => x.IdOrganismoControl == requisitoLegal.IdOrganismoControl).FirstOrDefault();

                        requisitoLegal.IdEmpresa = OrganismoControl.Empresa?.IdEmpresa ?? 0;

                        ViewData["Empresas"] = new SelectList(ListaEmpresas.OrderBy(x => x.Nombre).ToList(),"IdEmpresa", "Nombre",requisitoLegal.IdEmpresa);

                        ViewData["OrganismoControl"] = new SelectList( ListaOrganismoControl .Where(x => x.IdEmpresa == requisitoLegal.IdEmpresa).OrderBy(c => c.Nombre).ToList(),"IdOrganismoControl", "Nombre",selectedValue: requisitoLegal.IdOrganismoControl);


                        return this.VistaError(requisitoLegal, $"{Mensaje.Error}|{Mensaje.ExisteRegistro}");

                    }
                        
                }

                 ListaEmpresas = db.Empresa.ToList();
                 ListaOrganismoControl = db.OrganismoControl.ToList();

                if (User.IsInRole(Perfiles.AdministradorEmpresa))
                {
                    ListaEmpresas = ListaEmpresas.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa).ToList();
                    ListaOrganismoControl = ListaOrganismoControl.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa).ToList();
                }

                OrganismoControl = ListaOrganismoControl
                .Where(x => x.IdOrganismoControl == requisitoLegal.IdOrganismoControl).FirstOrDefault();

                requisitoLegal.IdEmpresa = OrganismoControl.Empresa?.IdEmpresa ?? 0;

                ViewData["Empresas"] = new SelectList(ListaEmpresas.OrderBy(x => x.Nombre).ToList(), "IdEmpresa", "Nombre", requisitoLegal.IdEmpresa);

                ViewData["OrganismoControl"] = new SelectList(ListaOrganismoControl.Where(x => x.IdEmpresa == requisitoLegal.IdEmpresa).OrderBy(c => c.Nombre).ToList(), "IdOrganismoControl", "Nombre", selectedValue: requisitoLegal.IdOrganismoControl);
                return this.VistaError(requisitoLegal, $"{Mensaje.Error}|{Mensaje.ModeloInvalido}");
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
                var requisitoLegal = await db.RequisitoLegal.FirstOrDefaultAsync(m => m.IdRequisitoLegal == id);
                if (requisitoLegal != null)
                {
                    db.RequisitoLegal.Remove(requisitoLegal);
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