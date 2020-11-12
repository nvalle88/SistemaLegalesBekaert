﻿using SistemasLegales.Services;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Threading.Tasks;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;
using SistemasLegales.Models.Utiles;

namespace SistemasLegales.Models.Entidades
{
    public partial class Requisito : IValidatableObject
    {
        public Requisito()
        {
            DocumentoRequisito = new HashSet<DocumentoRequisito>();
        }

        public int IdRequisito { get; set; }

        [Display(Name = "Requisito")]
        [Required(ErrorMessage = "Debe seleccionar el {0}.")]
        [Range(1, double.MaxValue, ErrorMessage = "Debe seleccionar el {0}.")]
        public int IdDocumento { get; set; }
        public virtual Documento Documento { get; set; }

        [Display(Name = "Ciudad")]
        [Required(ErrorMessage = "Debe seleccionar la {0}.")]
        [Range(1, double.MaxValue, ErrorMessage = "Debe seleccionar la {0}.")]
        public int IdCiudad { get; set; }
        public virtual Ciudad Ciudad { get; set; }

        [Display(Name = "Proceso")]
        [Required(ErrorMessage = "Debe seleccionar el {0}.")]
        [Range(1, double.MaxValue, ErrorMessage = "Debe seleccionar el {0}.")]
        public int IdProceso { get; set; }
        public virtual Proceso Proceso { get; set; }

        [Display(Name = "Proyecto")]
        [Required(ErrorMessage = "Debe seleccionar el {0}.")]
        [Range(1, double.MaxValue, ErrorMessage = "Debe seleccionar el {0}.")]
        public int? IdProyecto { get; set; }
        public virtual Proyecto Proyecto { get; set; }

        [Display(Name = "Dueño del proceso")]
        [Required(ErrorMessage = "Debe seleccionar el {0}.")]
        [Range(1, double.MaxValue, ErrorMessage = "Debe seleccionar el {0}.")]
        public int IdActorDuennoProceso { get; set; }
        public virtual Actor ActorDuennoProceso { get; set; }

        [Display(Name = "Responsable de gest y seg")]
        [Required(ErrorMessage = "Debe seleccionar el {0}.")]
        [Range(1, double.MaxValue, ErrorMessage = "Debe seleccionar el {0}.")]
        public int IdActorResponsableGestSeg { get; set; }
        public virtual Actor ActorResponsableGestSeg { get; set; }

        [Display(Name = "Custodio de documento")]
        [Required(ErrorMessage = "Debe seleccionar el {0}.")]
        [Range(1, double.MaxValue, ErrorMessage = "Debe seleccionar el {0}.")]
        public int IdActorCustodioDocumento { get; set; }
        public virtual Actor ActorCustodioDocumento { get; set; }

        [Display(Name = "Fecha de cumplimiento")]
        [DataType(DataType.DateTime)]
        [DisplayFormat(DataFormatString = "{0:dd/MM/yyyy}", ApplyFormatInEditMode = true)]
        public DateTime? FechaCumplimiento { get; set; }

        [Display(Name = "Fecha Exigible")]
        [DataType(DataType.DateTime)]
        [Required(ErrorMessage = "Debe seleccionar la {0}.")]
        [DisplayFormat(DataFormatString = "{0:dd/MM/yyyy}", ApplyFormatInEditMode = true)]
        public DateTime? FechaCaducidad { get; set; }

        [Display(Name = "Status")]
        [Required(ErrorMessage = "Debe seleccionar el {0}.")]
        [Range(1, double.MaxValue, ErrorMessage = "Debe seleccionar el {0}.")]
        public int IdStatus { get; set; }
        public virtual Status Status { get; set; }

        [Display(Name = "Duración del trámite (Días)")]
        [Required(ErrorMessage = "Debe introducir la {0}.")]
        public int DuracionTramite { get; set; }

        [Display(Name = "Nro. días para notificación")]
        [Required(ErrorMessage = "Debe introducir el {0}.")]
        public int DiasNotificacion { get; set; }
        
        [EmailAddress(ErrorMessage = "El {0} es inválido.")]
        [Display(Name = "Correo notificación 1")]
        [StringLength(100, MinimumLength = 1, ErrorMessage = "El {0} no puede tener más de {1} y menos de {2} caracteres.")]
        public string EmailNotificacion1 { get; set; }
        
        [EmailAddress(ErrorMessage = "El {0} es inválido.")]
        [Display(Name = "Correo notificación 2")]
        [StringLength(100, MinimumLength = 1, ErrorMessage = "El {0} no puede tener más de {1} y menos de {2} caracteres.")]
        public string EmailNotificacion2 { get; set; }

        [Display(Name = "Observaciones")]
        [DataType(DataType.Text)]
       // [StringLength(1000, MinimumLength = 1, ErrorMessage = "Las {0} no pueden tener más de {1} y menos de {2} caracteres.")]
        public string Observaciones { get; set; }

        [Display(Name = "Notificación enviada")]
        public bool NotificacionEnviada { get; set; }

        [Display(Name = "Notificación enviada")]
        public bool NotificacionEnviadaUltima { get; set; }
        

        public bool Finalizado { get; set; }

        public bool Habilitado { get; set; }

        public int? Criticidad { get; set; }

        public int? FactorIF { get; set; }

        public int? ICF { get; set; }

        public int? EsLegal { get; set; }


        [NotMapped]
        [Display(Name = "Año")]
        public int? Anno { get; set; }

        [NotMapped]
        public bool SemaforoVerde { get; set; }

        [NotMapped]
        public bool SemaforoAmarillo { get; set; }

        [NotMapped]
        public bool SemaforoRojo { get; set; }

        [NotMapped]
        public int IdStatusAnterior { get; set; }

        [NotMapped]
        [Display(Name = "Empresa")]
        public int? IdEmpresa { get; set; }


        public string ConformarMensaje(string url, Requisito requisito,TipoMensaje tipoMensaje,string usuario)
        {
            var FechaCumplimiento = requisito.FechaCumplimiento != null ? requisito.FechaCumplimiento?.ToString("dd/MM/yyyy") : "No Definido";
            var FechaCaducidad = requisito.FechaCaducidad != null ? requisito.FechaCaducidad?.ToString("dd/MM/yyyy") : "No Definido";

            var cabecera = "";

            switch (tipoMensaje)
            {
                case TipoMensaje.CREATE:
                    cabecera = ConstantesCorreo.CabeceraNotificacion.Contains("@TipoMensaje") ? ConstantesCorreo.CabeceraNotificacion.Replace("@TipoMensaje", ConstantesCorreo.MensajeCREATE) : ConstantesCorreo.CabeceraNotificacion;
                    cabecera =cabecera.Contains("@dias")? cabecera.Replace("@dias", ObtenerDiasRestantes()):cabecera;
                    break;
                case TipoMensaje.TERMINADO:
                    cabecera = ConstantesCorreo.CabeceraNotificacion.Contains("@TipoMensaje") ? ConstantesCorreo.CabeceraNotificacion.Replace("@TipoMensaje", ConstantesCorreo.MensajeTERMINADO) : ConstantesCorreo.CabeceraNotificacion;
                    cabecera = cabecera.Contains("@dias") ? cabecera.Replace("@dias", ObtenerDiasRestantes()) : cabecera;
                    break;
                case TipoMensaje.FINALIZADO:
                    cabecera = ConstantesCorreo.CabeceraNotificacion.Contains("@TipoMensaje") ? ConstantesCorreo.CabeceraNotificacion.Replace("@TipoMensaje", ConstantesCorreo.MensajeFINALIZADO) : ConstantesCorreo.CabeceraNotificacion;
                    cabecera = cabecera.Contains("@dias") ? cabecera.Replace("@dias", ObtenerDiasRestantes()) : cabecera;
                    break;
                case TipoMensaje.AUTOMATICO:
                    cabecera = ConstantesCorreo.CabeceraNotificacion.Contains("@TipoMensaje") ? ConstantesCorreo.CabeceraNotificacion.Replace("@TipoMensaje", ConstantesCorreo.MensajeAUTOMATICO) : ConstantesCorreo.CabeceraNotificacion;
                    cabecera = cabecera.Contains("@dias") ? cabecera.Replace("@dias", ObtenerDiasRestantes()) : cabecera;
                    break;
                case TipoMensaje.NOACEPTADO:
                    cabecera = ConstantesCorreo.CabeceraNotificacion.Contains("@TipoMensaje") ? ConstantesCorreo.CabeceraNotificacion.Replace("@TipoMensaje", ConstantesCorreo.MensajeNOACEPTADO) : ConstantesCorreo.CabeceraNotificacion;
                    cabecera = cabecera.Contains("@dias") ? cabecera.Replace("@dias", ObtenerDiasRestantes()) : cabecera;
                    break;
                case TipoMensaje.CADUCAR:
                    cabecera = ConstantesCorreo.CabeceraNotificacion.Contains("@TipoMensaje") ? ConstantesCorreo.CabeceraNotificacion.Replace("@TipoMensaje", ConstantesCorreo.MensajeCADUCAR) : ConstantesCorreo.CabeceraNotificacion;
                    cabecera = cabecera.Contains("@dias") ? cabecera.Replace("@dias", ObtenerDiasRestantes()) : cabecera;
                    break;
                case TipoMensaje.PORCADUCAR:
                    cabecera = ConstantesCorreo.CabeceraNotificacion.Contains("@TipoMensaje") ? ConstantesCorreo.CabeceraNotificacion.Replace("@TipoMensaje", ConstantesCorreo.MensajePORCADUCAR) : ConstantesCorreo.CabeceraNotificacion;
                    cabecera = cabecera.Contains("@dias") ? cabecera.Replace("@dias", ObtenerDiasRestantes()) : cabecera;
                    break;
                case TipoMensaje.FINALIZADOMODIFICADO:
                    var nombreUsuario = ConstantesCorreo.MensajeFINALIZADOMODIFICADO.Replace("@usuario", usuario);
                    cabecera = ConstantesCorreo.CabeceraNotificacion.Contains("@TipoMensaje") ? ConstantesCorreo.CabeceraNotificacion.Replace("@TipoMensaje", nombreUsuario) : ConstantesCorreo.CabeceraNotificacion;
                    cabecera = cabecera.Contains("@dias") ? "FINALIZADO" : "FINALIZADO";
                    break;
                default:
                    break;
            }

            var cuerpo = "";
            cuerpo =ConstantesCorreo.CuerpoNotificacion.Contains("@OrganismoControl")? ConstantesCorreo.CuerpoNotificacion.Replace("@OrganismoControl", requisito.Documento.RequisitoLegal.OrganismoControl.Nombre): ConstantesCorreo.CuerpoNotificacion;
            cuerpo =ConstantesCorreo.CuerpoNotificacion.Contains("BaseLegal") ? cuerpo.Replace("@BaseLegal", requisito.Documento.RequisitoLegal.Nombre): cuerpo;
            cuerpo = ConstantesCorreo.CuerpoNotificacion.Contains("@Requisito") ? cuerpo.Replace("@Requisito", requisito.Documento.Nombre) : cuerpo;
            cuerpo = ConstantesCorreo.CuerpoNotificacion.Contains("@Ciudad") ? cuerpo.Replace("@Ciudad", requisito.Ciudad.Nombre) : cuerpo;
            cuerpo = ConstantesCorreo.CuerpoNotificacion.Contains("@Proceso") ? cuerpo.Replace("@Proceso", requisito.Proceso.Nombre) : cuerpo;
            cuerpo = ConstantesCorreo.CuerpoNotificacion.Contains("@FechaCumplimiento") ? cuerpo.Replace("@FechaCumplimiento", FechaCumplimiento) : cuerpo;
            cuerpo = ConstantesCorreo.CuerpoNotificacion.Contains("@FechaCaducidad") ? cuerpo.Replace("@FechaCaducidad", FechaCaducidad) : cuerpo;
            cuerpo = ConstantesCorreo.CuerpoNotificacion.Contains("@Status") ? cuerpo.Replace("@Status", requisito.Status.Nombre) : cuerpo;
            cuerpo = ConstantesCorreo.CuerpoNotificacion.Contains("@Observaciones") ? cuerpo.Replace("@Observaciones", requisito.Observaciones) : cuerpo;

            if (!string.IsNullOrEmpty(url))
            {
                var miUrl = ConstantesCorreo.UrlNotificacion.Replace("@url", url);
                cuerpo = cuerpo + miUrl;
            }

            var salida = cabecera + cuerpo + ConstantesCorreo.FooterNotificacion;
            return salida;

        }

        public virtual ICollection<Accion> Accion { get; set; }
        public virtual ICollection<DocumentoRequisito> DocumentoRequisito { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            var requisito = (Requisito)validationContext.ObjectInstance;
            if (requisito.EmailNotificacion1 == requisito.EmailNotificacion2)
                yield return new ValidationResult($"El Correo notificación 2 no puede ser igual al Correo notificación 1.", new[] { "EmailNotificacion2" });

            if (requisito.FechaCaducidad != null)
            {
                if (requisito.FechaCumplimiento > requisito.FechaCaducidad)
                    yield return new ValidationResult($"La Fecha de cumplimiento no puede ser mayor que la Fecha de caducidad.", new[] { "FechaCumplimiento" });
            }
            yield return ValidationResult.Success;
        }

        /// <summary>
        /// Retorna el semáforo para el requisito en la forma 1. Verde, 2. Amarillo, 3.Rojo
        /// </summary>
        /// <returns></returns>
        public int ObtenerSemaforo()
        {
            int myNegInt = (Math.Abs(DiasNotificacion+ConstantesSemaforo.MenosDiasNotificacion) * (-1));
            if (FechaCaducidad == null)
                return 3;
            //*********************************

            DateTime diasnotificacion = FechaCaducidad.Value.AddDays(myNegInt);//some datetime
            DateTime diasexigible = FechaCaducidad.Value.AddDays((ConstantesSemaforo.MenosDiasExigible*-1));//some datetime
            DateTime hoy = DateTime.Now;
            TimeSpan restantesexigible = diasexigible - hoy.Date;
            TimeSpan restantenotificacion = diasnotificacion - hoy.Date;

            int diasN = restantenotificacion.Days;
            int diasE = restantesexigible.Days;

            if (diasN>0)
            {
                return 1;

            }          
            else if (diasE <= 0)
            {
                return 3;
            }
            else return 2;
            //*********************************
        }

        public string ObtenerDias()
        {
          
            if (FechaCaducidad == null)
                return "Sin fecha";

            int myNegInt = (Math.Abs(DiasNotificacion+2) * (-1));
            
            DateTime a = FechaCaducidad.Value.AddDays(myNegInt);//some datetime
            DateTime now = DateTime.Now.Date;
            TimeSpan ts =  a - now;
            int days =ts.Days;

            return days.ToString();
        }


        public string ObtenerDiasRestantes()
        {
            if (FechaCaducidad == null)
                return "Sin fecha";
            DateTime a = FechaCaducidad.Value;//some datetime
            DateTime now = DateTime.Now.Date;
            TimeSpan ts = a - now;
            int days = ts.Days;
            return days.ToString();
        }

        public List<string> ListadoEmailsDistinct(List<string> lista)
        {
            var listaSalida= lista.Distinct().ToList();
            return listaSalida;
        }

        public async Task<bool> EnviarEmailNotificaionRequisitoCreacion(string url, IEmailSender emailSender, SistemasLegalesContext db)
        {
            try
            {
                var requisito = await db.Requisito
                                        .Include(c => c.Documento).ThenInclude(c => c.RequisitoLegal.OrganismoControl)
                                        .Include(c => c.Ciudad)
                                        .Include(c => c.Proceso)
                                        .Include(c => c.ActorDuennoProceso)
                                        .Include(c => c.ActorResponsableGestSeg)
                                        .Include(c => c.ActorCustodioDocumento)
                                        .Include(c => c.Status)
                                        .FirstOrDefaultAsync(c => c.IdRequisito == IdRequisito);


                if (requisito != null)
                {
                    var listadoEmails = new List<string>()
                        {
                            ActorDuennoProceso.Email,
                            ActorResponsableGestSeg.Email,
                            ActorCustodioDocumento.Email
                        };

                    if (!String.IsNullOrEmpty(EmailNotificacion1))
                        listadoEmails.Add(EmailNotificacion1);

                    if (!String.IsNullOrEmpty(EmailNotificacion2))
                        listadoEmails.Add(EmailNotificacion2);
                    listadoEmails = ListadoEmailsDistinct(listadoEmails);
                    emailSender.SendEmailAsync(listadoEmails, "Notificación de creación de un requisito.",ConformarMensaje(url,requisito,TipoMensaje.CREATE,""));
                }
                return true;
            }
            catch (Exception)
            { }
            return false;
        }

        public async Task<bool> EnviarEmailNotificaionRequisitoCreacionAutomatica(UserManager<ApplicationUser> userManager, IEmailSender emailSender, SistemasLegalesContext db)
        {
            try
            {
                var requisito = await db.Requisito
                                        .Include(c => c.Documento).ThenInclude(c => c.RequisitoLegal.OrganismoControl)
                                        .Include(c => c.Ciudad)
                                        .Include(c => c.Proceso)
                                        .Include(c => c.ActorDuennoProceso)
                                        .Include(c => c.ActorResponsableGestSeg)
                                        .Include(c => c.ActorCustodioDocumento)
                                        .Include(c => c.Status)
                                        .FirstOrDefaultAsync(c => c.IdRequisito == IdRequisito);


                if (requisito != null)
                {

                    var listadoEmails = new List<string>()
                        {
                            ActorDuennoProceso.Email,
                            ActorResponsableGestSeg.Email,
                            ActorCustodioDocumento.Email
                        };

                    if (!String.IsNullOrEmpty(EmailNotificacion1))
                        listadoEmails.Add(EmailNotificacion1);

                    if (!String.IsNullOrEmpty(EmailNotificacion2))
                        listadoEmails.Add(EmailNotificacion2);


                    var listaAdministradores = await userManager.GetUsersInRoleAsync(Perfiles.Administrador);

                    foreach (var item in listaAdministradores)
                    {
                        listadoEmails.Add(item.Email);
                    }
                    listadoEmails = ListadoEmailsDistinct(listadoEmails);
                    emailSender.SendEmailAsync(listadoEmails, "Notificación de requisito creado automaticamete.", ConformarMensaje("", requisito, TipoMensaje.AUTOMATICO,""));
                }
                return true;
            }
            catch (Exception)
            { }
            return false;
        }

        public async Task<bool> EnviarEmailNotificaionRequisitoFinalizado(IEmailSender emailSender, SistemasLegalesContext db)
        {
            try
            {
                var requisito = await db.Requisito
                                        .Include(c => c.Documento).ThenInclude(c => c.RequisitoLegal.OrganismoControl)
                                        .Include(c => c.Ciudad)
                                        .Include(c => c.Proceso)
                                        .Include(c => c.ActorDuennoProceso)
                                        .Include(c => c.ActorResponsableGestSeg)
                                        .Include(c => c.ActorCustodioDocumento)
                                        .Include(c => c.Status)
                                        .FirstOrDefaultAsync(c => c.IdRequisito == IdRequisito);

                if (requisito!=null)
                {
                    var listadoEmails = new List<string>()
                        {
                            ActorDuennoProceso.Email,
                            ActorResponsableGestSeg.Email,
                            ActorCustodioDocumento.Email
                        };

                    if (!String.IsNullOrEmpty(EmailNotificacion1))
                        listadoEmails.Add(EmailNotificacion1);

                    if (!String.IsNullOrEmpty(EmailNotificacion2))
                        listadoEmails.Add(EmailNotificacion2);
                    listadoEmails = ListadoEmailsDistinct(listadoEmails);
                    emailSender.SendEmailAsync(listadoEmails, "Notificación de requisito finalizado.",ConformarMensaje("", requisito, TipoMensaje.FINALIZADO,""));
                }
                return true;
            }
            catch (Exception)
            { }
            return false;
        }

        //public async Task<bool> EnviarEmailNotificaionRequisitoTerminado(UserManager<ApplicationUser> userManager,string url,IEmailSender emailSender, SistemasLegalesContext db)
        //{
        //    try
        //    {
        //        var listaAdministradores=await userManager.GetUsersInRoleAsync(Perfiles.Administrador);

        //        var requisito = await db.Requisito
        //                                .Include(c => c.Documento).ThenInclude(c => c.RequisitoLegal.OrganismoControl)
        //                                .Include(c => c.Ciudad)
        //                                .Include(c => c.Proceso)
        //                                .Include(c => c.ActorDuennoProceso)
        //                                .Include(c => c.ActorResponsableGestSeg)
        //                                .Include(c => c.ActorCustodioDocumento)
        //                                .Include(c => c.Status)
        //                                .FirstOrDefaultAsync(c => c.IdRequisito == IdRequisito);

        //        var listadoEmails = new List<string>();
        //        foreach (var item in listaAdministradores)
        //        {
        //            listadoEmails.Add(item.Email);
        //        }
        //        if (listaAdministradores.Count>0)
        //        {
        //            listadoEmails = ListadoEmailsDistinct(listadoEmails);
        //            emailSender.SendEmailAsync(listadoEmails, "Notificación de requisito terminado.", ConformarMensaje(url, requisito, TipoMensaje.TERMINADO,""));
        //        }
        //    return true;
        //    }
        //    catch (Exception)
        //    { }
        //    return false;
        //}

        public async Task<bool> EnviarEmailNotificaionFinalizadoModificado(string nombreUsuario,UserManager<ApplicationUser> userManager, IEmailSender emailSender, SistemasLegalesContext db)
        {
            try
            {
                var requisito = await db.Requisito
                                        .Include(c => c.Documento).ThenInclude(c => c.RequisitoLegal.OrganismoControl)
                                        .Include(c => c.Ciudad)
                                        .Include(c => c.Proceso)
                                        .Include(c => c.ActorDuennoProceso)
                                        .Include(c => c.ActorResponsableGestSeg)
                                        .Include(c => c.ActorCustodioDocumento)
                                        .Include(c => c.Status)
                                        .FirstOrDefaultAsync(c => c.IdRequisito == IdRequisito);
                if (requisito != null)
                {
                    var listadoEmails = new List<string>()
                        {
                            ActorDuennoProceso.Email,
                            ActorResponsableGestSeg.Email,
                            ActorCustodioDocumento.Email
                        };

                    if (!String.IsNullOrEmpty(EmailNotificacion1))
                        listadoEmails.Add(EmailNotificacion1);

                    if (!String.IsNullOrEmpty(EmailNotificacion2))
                        listadoEmails.Add(EmailNotificacion2);


                    var listaAdministradores = await userManager.GetUsersInRoleAsync(Perfiles.Administrador);

                    foreach (var item in listaAdministradores)
                    {
                        listadoEmails.Add(item.Email);
                    }
                    listadoEmails = ListadoEmailsDistinct(listadoEmails);
                    emailSender.SendEmailAsync(listadoEmails, "Notificación de requisito finalizado ha sido modificado.", ConformarMensaje(null,requisito, TipoMensaje.FINALIZADOMODIFICADO,nombreUsuario));
                }
                return true;
            }
            catch (Exception)
            { }
            return false;
        }


        public async Task<bool> EnviarEmailNotificaionNoFinalizado(string url, IEmailSender emailSender, SistemasLegalesContext db)
        {
            try
            {
                var requisito = await db.Requisito
                                        .Include(c => c.Documento).ThenInclude(c => c.RequisitoLegal.OrganismoControl)
                                        .Include(c => c.Ciudad)
                                        .Include(c => c.Proceso)
                                        .Include(c => c.ActorDuennoProceso)
                                        .Include(c => c.ActorResponsableGestSeg)
                                        .Include(c => c.ActorCustodioDocumento)
                                        .Include(c => c.Status)
                                        .FirstOrDefaultAsync(c => c.IdRequisito == IdRequisito);
                if (requisito != null)
                {
                    var listadoEmails = new List<string>();
                    listadoEmails.Add(requisito.ActorResponsableGestSeg.Email);
                    listadoEmails = ListadoEmailsDistinct(listadoEmails);
                    emailSender.SendEmailAsync(listadoEmails, "Notificación de requisito.", ConformarMensaje(url, requisito, TipoMensaje.NOACEPTADO,""));
                }
                return true;
            }
            catch (Exception)
            { }
            return false;
        }

        public async Task<bool> EnviarEmailNotificaionDias(IEmailSender emailSender, SistemasLegalesContext db)
        {
            try
            {
                        var requisito = await db.Requisito.Where(x=>x.Finalizado==false && x.Habilitado==true)
                            .Include(c => c.Documento).ThenInclude(c => c.RequisitoLegal.OrganismoControl)
                            .Include(c => c.Ciudad)
                            .Include(c => c.Proceso)
                            .Include(c => c.ActorDuennoProceso)
                            .Include(c => c.ActorResponsableGestSeg)
                            .Include(c => c.ActorCustodioDocumento)
                            .Include(c => c.Status)
                            .FirstOrDefaultAsync(c => c.IdRequisito == IdRequisito);

                        var listadoEmails = new List<string>()
                        {
                            ActorResponsableGestSeg.Email,
                        };

                        var FechaCumplimiento = requisito.FechaCumplimiento != null ? requisito.FechaCumplimiento?.ToString("dd/MM/yyyy") : "No Definido";
                        var FechaCaducidad = requisito.FechaCaducidad != null ? requisito.FechaCaducidad?.ToString("dd/MM/yyyy") : "No Definido";

                listadoEmails = ListadoEmailsDistinct(listadoEmails);
                emailSender.SendEmailAsync(listadoEmails, "Notificación de caducidad de requisito.", ConformarMensaje("", requisito, TipoMensaje.CADUCAR,""));
                        return true;
            }
            catch (Exception)
            { }
            return false;
        }

        public async Task<bool> EnviarEmailNotificaion(UserManager<ApplicationUser> userManager, IEmailSender emailSender, SistemasLegalesContext db)
        {
            try
            {
                var semaforo = ObtenerSemaforo();
                if (semaforo == 2)
                {
                    if (!NotificacionEnviada)
                    {
                        var requisito = await db.Requisito
                            .Include(c => c.Documento).ThenInclude(c=> c.RequisitoLegal.OrganismoControl)
                            .Include(c => c.Ciudad)
                            .Include(c => c.Proceso)
                            .Include(c=> c.ActorDuennoProceso)
                            .Include(c=> c.ActorResponsableGestSeg)
                            .Include(c=> c.ActorCustodioDocumento)
                            .Include(c=> c.Status)
                            .FirstOrDefaultAsync(c => c.IdRequisito == IdRequisito);

                        var listadoEmails = new List<string>()
                        {
                            ActorDuennoProceso.Email,
                            ActorResponsableGestSeg.Email,
                            ActorCustodioDocumento.Email
                        };

                        if (!String.IsNullOrEmpty(EmailNotificacion1))
                            listadoEmails.Add(EmailNotificacion1);

                        if (!String.IsNullOrEmpty(EmailNotificacion2))
                            listadoEmails.Add(EmailNotificacion2);

                        var FechaCumplimiento = requisito.FechaCumplimiento != null ? requisito.FechaCumplimiento?.ToString("dd/MM/yyyy") : "No Definido";
                        var FechaCaducidad = requisito.FechaCaducidad != null ? requisito.FechaCaducidad?.ToString("dd/MM/yyyy") : "No Definido";

                        listadoEmails = ListadoEmailsDistinct(listadoEmails);
                        emailSender.SendEmailAsync(listadoEmails, "Notificación de caducidad de requisito.", ConformarMensaje("", requisito, TipoMensaje.PORCADUCAR,""));
                        NotificacionEnviada = true;
                        await db.SaveChangesAsync();
                        return true;
                    }
                }

                if (semaforo == 3)
                {
                    if (!NotificacionEnviadaUltima)
                    {
                        var requisito = await db.Requisito
                            .Include(c => c.Documento).ThenInclude(c => c.RequisitoLegal.OrganismoControl)
                            .Include(c => c.Ciudad)
                            .Include(c => c.Proceso)
                            .Include(c => c.ActorDuennoProceso)
                            .Include(c => c.ActorResponsableGestSeg)
                            .Include(c => c.ActorCustodioDocumento)
                            .Include(c => c.Status)
                            .FirstOrDefaultAsync(c => c.IdRequisito == IdRequisito);

                        var listadoEmails = new List<string>()
                        {
                            ActorDuennoProceso.Email,
                            ActorResponsableGestSeg.Email,
                            ActorCustodioDocumento.Email
                        };

                        if (!String.IsNullOrEmpty(EmailNotificacion1))
                            listadoEmails.Add(EmailNotificacion1);

                        if (!String.IsNullOrEmpty(EmailNotificacion2))
                            listadoEmails.Add(EmailNotificacion2);


                        //var listaAdministradores = await userManager.GetUsersInRoleAsync(Perfiles.Administrador);

                        //foreach (var item in listaAdministradores)
                        //{
                        //    listadoEmails.Add(item.Email);
                        //}

                        var FechaCumplimiento = requisito.FechaCumplimiento != null ? requisito.FechaCumplimiento?.ToString("dd/MM/yyyy") : "No Definido";
                        var FechaCaducidad = requisito.FechaCaducidad != null ? requisito.FechaCaducidad?.ToString("dd/MM/yyyy") : "No Definido";
                        listadoEmails = ListadoEmailsDistinct(listadoEmails);
                        emailSender.SendEmailAsync(listadoEmails, "Notificación de caducidad de requisito.", ConformarMensaje("", requisito, TipoMensaje.CADUCAR,""));

                        NotificacionEnviadaUltima = true;
                        await db.SaveChangesAsync();
                        return true;
                    }
                }
            }
            catch (Exception)
            { }
            return false;
        }
    }
}
