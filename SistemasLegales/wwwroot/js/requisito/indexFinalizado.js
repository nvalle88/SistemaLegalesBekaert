﻿MiApp.Requisito = function () {
    var semaforoVerde = false;
    var semaforoAmarillo = false;
    var semaforoRojo = true;

    this.eventoOrganismoControl = function () {
        $("#IdOrganismoControl").on("change", function (e) {
            partialViewListadoTabla();
        });
    };

    this.eventoResponsableGestSeg = function () {
        $("#IdActorResponsableGestSeg").on("change", function (e) {
            partialViewListadoTabla();
        });
    };

    this.eventoProyecto = function () {
        $("#IdProyecto").on("change", function (e) {
            partialViewListadoTabla();
        });
    };

    this.eventoFechaAnno = function () {
        MiApp.DatePicker.fnCallbackChangeDatepicker = function () {
            partialViewListadoTabla();
        };
    };

    this.partialViewListadoTabla = function () {
        MiApp.LoadingPanel.mostrarNotificacion("bodyTemplate", "Cargando datos...");
        $.ajax({
            url: urlListadoResult,
            method: "POST",
            data: {
                requisito: {
                    Documento: {
                        RequisitoLegal: {
                            IdOrganismoControl: $("#IdOrganismoControl").val(),
                        }
                    },
                    IdActorResponsableGestSeg: $("#IdActorResponsableGestSeg").val(),
                    IdProyecto: $("#IdProyecto").val(),
                    Anno: $("#Anno").val(),
                }
            },
            success: function (data) {
                $("#divTablaListado").html(data);
                MiApp.Datatables.inicializarDatatable();
            },
            error: function (errorMessage) {
                MiApp.Mensajes.mostrarNotificacion("error", "Ocurrió un error al cargar los datos, inténtelo nuevamente.");
            },
            complete: function () {
                $("#bodyTemplate").waitMe("hide");
            }
        });
    };

    return {
        init: function () {
            eventoOrganismoControl();
            eventoResponsableGestSeg();
            eventoProyecto();
            eventoFechaAnno();
            eventoSemaforoEstado();
            partialViewListadoTabla();
        }
    }
}();
MiApp.Requisito.init();