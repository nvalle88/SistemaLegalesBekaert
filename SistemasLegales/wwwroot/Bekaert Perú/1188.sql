---------------Mensaje Servicios Inactivos-----------------------------------------------

  IF NOT EXISTS (SELECT 1 FROM [Saludsa].[Administracion].[ParametroServicioWeb] P
WHERE P.[Servicio] = 'WebApiLiquidaciones' AND P.[Codigo] = 'MensajeServicioInactivoReembolso')
BEGIN
PRINT 'Creando -> MensajeServicioInactivoReembolso - WebApiLiquidaciones'
INSERT INTO [Saludsa].[Administracion].[ParametroServicioWeb] ([Codigo], [Servicio], [Valor])
VALUES (N'MensajeServicioInactivoReembolso', N'WebApiLiquidaciones',
N'¡Aviso Importante! Le pedimos mil disculpas nos encontramos realizando mantenimiento, podrá ingresar su solicitud a partir de las 09:00. Gracias por su comprensión.')
END
ELSE
BEGIN
PRINT 'Actualizado -> WebApiLiquidaciones - MensajeServicioInactivoReembolso'
UPDATE [Saludsa].[Administracion].[ParametroServicioWeb]
SET [Valor] = N'¡Aviso Importante! Le pedimos mil disculpas nos encontramos realizando mantenimiento, podrá ingresar su solicitud a partir de las 09:00. Gracias por su comprensión.'
WHERE [Servicio] = 'WebApiLiquidaciones' AND [Codigo] = 'MensajeServicioInactivoReembolso'
END
 ------------------------------------------------------------------------------------------

  --------------- Estado Servicios Reembolso-----------------------------------------------

IF NOT EXISTS (SELECT 1 FROM [Saludsa].[Administracion].[ParametroServicioWeb] P
WHERE P.[Servicio] = 'WebApiLiquidaciones' AND P.[Codigo] = 'EstadoActivoServicioReembolso')
BEGIN
PRINT 'Creando -> EstadoActivoServicioReembolso - WebApiLiquidaciones'
INSERT INTO [Saludsa].[Administracion].[ParametroServicioWeb] ([Codigo], [Servicio], [Valor])
VALUES (N'EstadoActivoServicioReembolso', N'WebApiLiquidaciones', N'false')
END
ELSE
BEGIN
PRINT 'Actualizado -> WebApiLiquidaciones - EstadoActivoServicioReembolso'
UPDATE [Saludsa].[Administracion].[ParametroServicioWeb]
SET [Valor] = N'false'
WHERE [Servicio] = 'WebApiLiquidaciones' AND [Codigo] = 'EstadoActivoServicioReembolso'
END
 ------------------------------------------------------------------------------------------