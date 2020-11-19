using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using SistemasLegales.Models.Entidades;
using SistemasLegales.Services;
using System;

namespace SistemasLegales.Controllers
{
    public class ReportController : Controller
    {

        private readonly IReporteServicio reporteServicio;
        private readonly UserManager<ApplicationUser> _userManager;
        public IConfiguration Configuration { get; }
        public ReportController( IReporteServicio reporteServicio, IConfiguration Configuration, UserManager<ApplicationUser> userManager)
        {
            this.Configuration = Configuration;
            this.reporteServicio = reporteServicio;
            _userManager = userManager;
        }

      
        public ActionResult RepTramites(int id)
        {
            var UsuarioAutenticado = _userManager.GetUserAsync(User).Result;
            var nombreParametroIdEmpresa = Configuration.GetSection("NombreParametroIdEmpresa").Value;
            var parametersToAdd = reporteServicio.GetDefaultParameters(Configuration.GetSection("ReporteTramites").Value);
            parametersToAdd = reporteServicio.AddParameters(nombreParametroIdEmpresa,Convert.ToString(UsuarioAutenticado.IdEmpresa),parametersToAdd);
            var newUri = reporteServicio.GenerateUri(parametersToAdd);
            return Redirect(newUri);
        }

        public ActionResult ReporteEstadoVsTiempo()
        {
            var UsuarioAutenticado = _userManager.GetUserAsync(User).Result;
            var nombreParametroIdEmpresa = Configuration.GetSection("NombreParametroIdEmpresa").Value;
            var parametersToAdd = reporteServicio.GetDefaultParameters(Configuration.GetSection("ReporteEstadoVsTiempo").Value);
            parametersToAdd = reporteServicio.AddParameters(nombreParametroIdEmpresa, Convert.ToString(UsuarioAutenticado.IdEmpresa), parametersToAdd);
            var newUri = reporteServicio.GenerateUri(parametersToAdd);
            return Redirect(newUri);
        }


    }
}

