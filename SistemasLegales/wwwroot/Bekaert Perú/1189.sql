---------------Mensaje Servicios Inactivos-----------------------------------------------

  IF NOT EXISTS (SELECT 1 FROM [Saludsa].[Administracion].[ParametroServicioWeb] P
WHERE P.[Servicio] = 'WebApiLiquidaciones' AND P.[Codigo] = 'MensajeServicioInactivoReembolso')
BEGIN
PRINT 'Creando -> MensajeServicioInactivoReembolso - WebApiLiquidaciones'
INSERT INTO [Saludsa].[Administracion].[ParametroServicioWeb] ([Codigo], [Servicio], [Valor])
VALUES (N'MensajeServicioInactivoReembolso', N'WebApiLiquidaciones',
N'Aviso importante. Te pedimos mil disculpas ya que nos encontramos en mantenimiento. Te notificaremos a tu celular registrado cuando se restablezca nuestro servicio. Gracias por tu comprensión.')
END
ELSE
BEGIN
PRINT 'Actualizado -> WebApiLiquidaciones - MensajeServicioInactivoReembolso'
UPDATE [Saludsa].[Administracion].[ParametroServicioWeb]
SET [Valor] = N'Aviso importante. Te pedimos mil disculpas ya que nos encontramos en mantenimiento. Te notificaremos a tu celular registrado cuando se restablezca nuestro servicio. Gracias por tu comprensión.'
WHERE [Servicio] = 'WebApiLiquidaciones' AND [Codigo] = 'MensajeServicioInactivoReembolso'
END
 ------------------------------------------------------------------------------------------

  --------------- Estado Servicios Reembolso-----------------------------------------------

IF NOT EXISTS (SELECT 1 FROM [Saludsa].[Administracion].[ParametroServicioWeb] P
WHERE P.[Servicio] = 'WebApiLiquidaciones' AND P.[Codigo] = 'EstadoActivoServicioReembolso')
BEGIN
PRINT 'Creando -> EstadoActivoServicioReembolso - WebApiLiquidaciones'
INSERT INTO [Saludsa].[Administracion].[ParametroServicioWeb] ([Codigo], [Servicio], [Valor])
VALUES (N'EstadoActivoServicioReembolso', N'WebApiLiquidaciones', N'true')
END
ELSE
BEGIN
PRINT 'Actualizado -> WebApiLiquidaciones - EstadoActivoServicioReembolso'
UPDATE [Saludsa].[Administracion].[ParametroServicioWeb]
SET [Valor] = N'true'
WHERE [Servicio] = 'WebApiLiquidaciones' AND [Codigo] = 'EstadoActivoServicioReembolso'
END
 ------------------------------------------------------------------------------------------