using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;

namespace SistemasLegales.Models.Entidades
{
    public class ApplicationUser : IdentityUser
    {
        public int? IdEmpresa { get; set; }

        public virtual Empresa Empresa { get; set; }
    }
}
