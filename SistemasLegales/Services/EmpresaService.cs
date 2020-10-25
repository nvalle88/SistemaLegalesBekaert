using EnviarCorreo;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SendMails.methods;
using SistemasLegales.Models.Entidades;
using SistemasLegales.Models.Utiles;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace SistemasLegales.Services
{
    // This class is used by the application to send Email and SMS
    // when you turn on two-factor authentication in ASP.NET Identity.
    // For more details see this link https://go.microsoft.com/fwlink/?LinkID=532713
    public class EmpresaService 
    {

        private readonly SistemasLegalesContext db;
        private readonly UserManager<ApplicationUser> _userManager;
        public EmpresaService(SistemasLegalesContext context, UserManager<ApplicationUser> userManager)
        {
            db = context;
            _userManager = userManager;
        }

        public List<Empresa> ListaEmpresas{ get; set; }

        private List<Empresa> Empresas() 
        {
            if (ListaEmpresas==null )
            {
                ListaEmpresas= db.Empresa.ToList();
                return ListaEmpresas;
            }

            return ListaEmpresas;
        }

        public  string ObtenerNombreEmpresa(ClaimsPrincipal user) 
        {
            if (user.IsInRole(Perfiles.Administrador))
                return "Acceso total";

            var UsuarioAutenticado = _userManager.GetUserAsync(user).Result;

            var empresa =Empresas().Where(x => x.IdEmpresa == UsuarioAutenticado.IdEmpresa).FirstOrDefault();
            if (empresa != null)
                return empresa.Nombre;

            return "Sin definir";
        }


    }
}
