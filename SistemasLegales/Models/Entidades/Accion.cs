﻿using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace SistemasLegales.Models.Entidades
{
    public partial class Accion
    {
        public int IdAccion { get; set; }

        [Required(ErrorMessage = "Debe introducir el {0}.")]
        [DataType(DataType.Text)]
        [Display(Name = "Detalle")]
        public string Detalle { get; set; }

        [Required(ErrorMessage = "Debe introducir la {0}")]
        [Display(Name = "Fecha")]
        [DataType(DataType.DateTime)]
        [DisplayFormat(DataFormatString = "{0:dd/MM/yyyy}", ApplyFormatInEditMode = true)]
        public DateTime? Fecha { get; set; }
        public int? IdRequisito { get; set; }

        public virtual Requisito IdRequisitoNavigation { get; set; }
    }
}
