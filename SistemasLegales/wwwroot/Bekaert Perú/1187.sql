‌
‌IF NOT EXISTS (SELECT 1 FROM [Saludsa].[Administracion].[ParametroServicioWeb] P 
    WHERE P.[Codigo] = 'DiasBusquedaOdaLote' AND P.[Servicio] = 'WebApiOrdenAtencion') 
BEGIN
    PRINT 'Creando -> DiasBusquedaOdaLote'
    INSERT INTO [Saludsa].[Administracion].[ParametroServicioWeb] ([Codigo],[Servicio],[Valor]) 
    VALUES (N'DiasBusquedaOdaLote',N'WebApiOrdenAtencion',N'360')
END
ELSE
BEGIN
	UPDATE [Saludsa].[Administracion].[ParametroServicioWeb] 
    SET [Valor] = N'360'
	WHERE [Codigo]='DiasBusquedaOdaLote' AND [Servicio] = 'WebApiOrdenAtencion'
	PRINT 'Actualizado -> DiasBusquedaOdaLote'
END
‌