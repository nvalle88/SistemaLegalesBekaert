using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
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
    public class DocumentoController : Controller
    {
        private readonly SistemasLegalesContext db;
        private readonly UserManager<ApplicationUser> _userManager;

        public DocumentoController(SistemasLegalesContext context, UserManager<ApplicationUser> userManager)
        {
            db = context;
            _userManager = userManager;
        }

        public async Task<IActionResult> Index()
        {
            IQueryable<Documento> lista = db.Documento.
                Include(x=>x.RequisitoLegal)
                .ThenInclude(x=>x.OrganismoControl)
                .ThenInclude(x=>x.Empresa);
            var resultado = new List<Documento>();
            try
            {
                if (User.IsInRole(Perfiles.AdministradorEmpresa))
                {
                    var UsuarioAutenticado = await _userManager.GetUserAsync(User);
                    lista = lista.Where(x => x.RequisitoLegal.OrganismoControl.IdEmpresa ==UsuarioAutenticado.IdEmpresa);
                }

                resultado =await lista.OrderBy(c => c.Nombre).ToListAsync();
            }
            catch (Exception)
            {
                TempData["Mensaje"] = $"{Mensaje.Error}|{Mensaje.ErrorListado}";
            }
            return View(resultado);
        }

        public async Task<JsonResult> ObtenerRequisitoLegalPorEmpresa(int idEmpresa)
        {
            try
            {
                var listaRequisitoLegal = await db.RequisitoLegal
                    .Where(x => x.OrganismoControl.IdEmpresa == idEmpresa)
                    .Select(y => new RequisitoLegal
                    {
                        IdRequisitoLegal = y.IdRequisitoLegal,
                        Nombre = y.Nombre.Length > 3000 ? y.Nombre.Substring(0, 100).ToString() + " ..." + " | " + y.OrganismoControl.Nombre : y.Nombre + " | " + y.OrganismoControl.Nombre
                   ,
                        OrganismoControl = new OrganismoControl
                        {
                            Nombre = y.OrganismoControl.Nombre,
                            IdOrganismoControl = y.OrganismoControl.IdOrganismoControl,
                            IdEmpresa = y.OrganismoControl.IdEmpresa,
                            Empresa = new Empresa
                            {
                                Nombre = y.OrganismoControl.Empresa.Nombre,
                                IdEmpresa = y.OrganismoControl.Empresa.IdEmpresa,
                            }
                        }
                    }).OrderBy(c => c.Nombre).ToListAsync();

                return Json(listaRequisitoLegal);
            }
            catch (Exception)
            {
                return new JsonResult(new List<RequisitoLegal>());
            }
        }

        public async Task<IActionResult> Gestionar(int? id)
        {
            try
            {
                ViewBag.accion = id == null ? "Crear" : "Editar";

                var UsuarioAutenticado = await _userManager.GetUserAsync(User);
                var ListaEmpresas = await db.Empresa.ToListAsync();
                var ListaRequisitoLegal = await db.RequisitoLegal.OrderBy(c => c.Nombre).Select(y => new RequisitoLegal 
                { 
                    IdRequisitoLegal = y.IdRequisitoLegal, Nombre = y.Nombre.Length > 100 ? y.Nombre.Substring(0, 100).ToString() + " ..." + " | "+ y.OrganismoControl.Nombre : y.Nombre +" | "+ y.OrganismoControl.Nombre
                   ,OrganismoControl= new OrganismoControl 
                   {
                       Nombre=y.OrganismoControl.Nombre,
                       IdOrganismoControl=y.OrganismoControl.IdOrganismoControl,
                       IdEmpresa=y.OrganismoControl.IdEmpresa,
                       Empresa= new Empresa 
                       {
                           Nombre=y.OrganismoControl.Empresa.Nombre,
                           IdEmpresa=y.OrganismoControl.Empresa.IdEmpresa,
                       }
                   }
                }).ToListAsync();
                if (User.IsInRole(Perfiles.AdministradorEmpresa))
                {
                    ListaEmpresas = ListaEmpresas.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa).ToList();
                    ListaRequisitoLegal = ListaRequisitoLegal.Where(x => x.OrganismoControl.IdEmpresa == UsuarioAutenticado.IdEmpresa).ToList();
                }

                var primeraEmpresa = ListaEmpresas.FirstOrDefault();

                ViewData["Empresas"] = new SelectList(ListaEmpresas
                    .OrderBy(x => x.Nombre)
                    .ToList(),
                    "IdEmpresa", "Nombre",
                    primeraEmpresa.IdEmpresa);

                ViewData["RequisitoLegal"] = new SelectList(ListaRequisitoLegal
                    .Where(x => x.OrganismoControl.IdEmpresa == primeraEmpresa.IdEmpresa)
                    .OrderBy(c => c.Nombre).ToList(),
                    "IdRequisitoLegal", "Nombre");


               // ViewData["RequisitoLegal"] = new SelectList(await db.RequisitoLegal.OrderBy(c => c.Nombre).Select(y=> new RequisitoLegal {IdRequisitoLegal=y.IdRequisitoLegal,Nombre=y.Nombre.Length>100?y.Nombre.Substring(0,100).ToString() + " ...":y.Nombre }).ToListAsync(), "IdRequisitoLegal", "Nombre");
                if (id != null)
                {
                    var documento = await db.Documento.Include(c => c.RequisitoLegal)
                        .ThenInclude(c => c.OrganismoControl)
                        .ThenInclude(x=>x.Empresa)
                        .FirstOrDefaultAsync(c => c.IdDocumento == id);
                    if (documento == null)
                        return this.Redireccionar($"{Mensaje.Error}|{Mensaje.RegistroNoEncontrado}");


                    var RequisitoLegal = ListaRequisitoLegal
                        .Where(x => x.IdRequisitoLegal == documento.IdRequisitoLegal).FirstOrDefault();

                    documento.IdEmpresa = RequisitoLegal.OrganismoControl.IdEmpresa ?? 0;

                    ViewData["Empresas"] = new SelectList(ListaEmpresas.OrderBy(x => x.Nombre).ToList(), "IdEmpresa", "Nombre", documento.IdEmpresa);

                    ViewData["RequisitoLegal"] = new SelectList(ListaRequisitoLegal
                        .Where(x => x.OrganismoControl.IdEmpresa == documento.IdEmpresa)
                        .OrderBy(c => c.Nombre).ToList(), "IdRequisitoLegal", "Nombre", 
                        selectedValue: documento.RequisitoLegal.OrganismoControl.IdEmpresa);

                    return View(documento);
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
        public async Task<IActionResult> Gestionar(Documento documento)
        {
            try
            {
                ViewBag.accion = documento.IdDocumento == 0 ? "Crear" : "Editar";

                var UsuarioAutenticado = await _userManager.GetUserAsync(User);
                var ListaEmpresas = new List<Empresa>();
                var ListaRequisitoLegal = new List<RequisitoLegal>();
                var RequisitoLegal = new RequisitoLegal();

                if (ModelState.IsValid)
                {
                    var existeRegistro = false;
                    if (documento.IdDocumento == 0)
                    {
                        if (!await db.Documento.AnyAsync(c => c.Nombre.ToUpper().Trim() == documento.Nombre.ToUpper().Trim() && c.IdRequisitoLegal == documento.IdRequisitoLegal))
                            db.Add(documento);
                        else
                            existeRegistro = true;
                    }
                    else
                    {
                        if (!await db.Documento.Where(c => c.Nombre.ToUpper().Trim() == documento.Nombre.ToUpper().Trim() && c.IdRequisitoLegal == documento.IdRequisitoLegal).AnyAsync(c => c.IdDocumento != documento.IdDocumento))
                            db.Update(documento);
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
                       
                       ListaEmpresas = await db.Empresa.ToListAsync();
                       ListaRequisitoLegal = await db.RequisitoLegal.OrderBy(c => c.Nombre).Select(y => new RequisitoLegal
                        {
                           IdRequisitoLegal = y.IdRequisitoLegal,
                           Nombre = y.Nombre.Length > 100 ? y.Nombre.Substring(0, 100).ToString() + " ..." + " | " + y.OrganismoControl.Nombre : y.Nombre + " | " + y.OrganismoControl.Nombre
                           ,
                            OrganismoControl = new OrganismoControl
                            {
                                Nombre = y.OrganismoControl.Nombre,
                                IdOrganismoControl = y.OrganismoControl.IdOrganismoControl,
                                IdEmpresa = y.OrganismoControl.IdEmpresa,
                                Empresa = new Empresa
                                {
                                    Nombre = y.OrganismoControl.Empresa.Nombre,
                                    IdEmpresa = y.OrganismoControl.Empresa.IdEmpresa,
                                }
                            }
                        }).ToListAsync();

                        if (User.IsInRole(Perfiles.AdministradorEmpresa))
                        {
                            ListaEmpresas = ListaEmpresas.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa).ToList();
                            ListaRequisitoLegal = ListaRequisitoLegal.Where(x => x.OrganismoControl.IdEmpresa == UsuarioAutenticado.IdEmpresa).ToList();
                        }

                         RequisitoLegal = ListaRequisitoLegal
                        .Where(x => x.IdRequisitoLegal == documento.IdRequisitoLegal).FirstOrDefault();

                        documento.IdEmpresa = RequisitoLegal.OrganismoControl.IdEmpresa ?? 0;

                        ViewData["Empresas"] = new SelectList(ListaEmpresas.OrderBy(x => x.Nombre).ToList(), "IdEmpresa", "Nombre", documento.IdEmpresa);

                        ViewData["RequisitoLegal"] = new SelectList(ListaRequisitoLegal
                            .Where(x => x.OrganismoControl.IdEmpresa == documento.IdEmpresa)
                            .OrderBy(c => c.Nombre).ToList(), "IdRequisitoLegal", "Nombre",
                            selectedValue: documento.IdEmpresa);

                        return this.VistaError(documento, $"{Mensaje.Error}|{Mensaje.ExisteRegistro}");

                    }
                    
                }


                ListaEmpresas = await db.Empresa.ToListAsync();
                ListaRequisitoLegal = await db.RequisitoLegal.OrderBy(c => c.Nombre).Select(y => new RequisitoLegal
                {
                    IdRequisitoLegal = y.IdRequisitoLegal,
                    Nombre = y.Nombre.Length > 100 ? y.Nombre.Substring(0, 100).ToString() + " ..." + " | " + y.OrganismoControl.Nombre : y.Nombre + " | " + y.OrganismoControl.Nombre
                    ,
                    OrganismoControl = new OrganismoControl
                    {
                        Nombre = y.OrganismoControl.Nombre,
                        IdOrganismoControl = y.OrganismoControl.IdOrganismoControl,
                        IdEmpresa = y.OrganismoControl.IdEmpresa,
                        Empresa = new Empresa
                        {
                            Nombre = y.OrganismoControl.Empresa.Nombre,
                            IdEmpresa = y.OrganismoControl.Empresa.IdEmpresa,
                        }
                    }
                }).ToListAsync();

                if (User.IsInRole(Perfiles.AdministradorEmpresa))
                {
                    ListaEmpresas = ListaEmpresas.Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa).ToList();
                    ListaRequisitoLegal = ListaRequisitoLegal.Where(x => x.OrganismoControl.IdEmpresa == UsuarioAutenticado.IdEmpresa).ToList();
                }

                RequisitoLegal = ListaRequisitoLegal
               .Where(x => x.IdRequisitoLegal == documento.IdRequisitoLegal).FirstOrDefault();

                documento.IdEmpresa = RequisitoLegal.OrganismoControl.IdEmpresa ?? 0;

                ViewData["Empresas"] = new SelectList(ListaEmpresas.OrderBy(x => x.Nombre).ToList(), "IdEmpresa", "Nombre", documento.IdEmpresa);

                ViewData["RequisitoLegal"] = new SelectList(ListaRequisitoLegal
                    .Where(x => x.OrganismoControl.IdEmpresa == documento.IdEmpresa)
                    .OrderBy(c => c.Nombre).ToList(), "IdRequisitoLegal", "Nombre",
                    selectedValue: documento.RequisitoLegal.OrganismoControl.IdEmpresa);
                return this.VistaError(documento, $"{Mensaje.Error}|{Mensaje.ModeloInvalido}");
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
                var documento = await db.Documento.FirstOrDefaultAsync(m => m.IdDocumento == id);
                if (documento != null)
                {
                    db.Documento.Remove(documento);
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