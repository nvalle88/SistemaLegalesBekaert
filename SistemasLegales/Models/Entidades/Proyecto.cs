using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace SistemasLegales.Models.Entidades
{
    public partial class Proyecto
    {
        public Proyecto()
        {
            Requisito = new HashSet<Requisito>();
        }

        public int IdProyecto { get; set; }
        public string Nombre { get; set; }


        [Display(Name = "Empresa")]
        public int? IdEmpresa { get; set; }

        [Display(Name = "Empresa")]
        public virtual Empresa Empresa { get; set; }

        public virtual ICollection<Requisito> Requisito { get; set; }
    }

}
