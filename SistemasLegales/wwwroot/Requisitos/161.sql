/*---------------------------------------------------------------------------*/
/* Nombre       centro_médico_medirecreo.sql									 */
/* BD           Saludsa                                                      */
/* Autor        Néstor Valle										 */
/* Creacion     2020.06.11                                                   */
/* Proposito    Inserción de registros para la parametrizaci�n de            */
/*              agendamiento de citas correspondientes al prestador MediRecreo*/
/*---------------------------------------------------------------------------*/
SET nocount ON
GO

USE [Saludsa]
GO

/*---------------------------------------------------------------------------*/
DECLARE
	@CodigoError			int,
	--
	@EntidadId				bigint,
	@PrestadorId			int,
	@Nombre					varchar(128),
	@NombreCorto			varchar(30),
	@NumeroConvenio			int,
	@Identificacion			varchar(13),
	@NacionalidadId			smallint,
	@TipoIdentificacionId	tinyint,
	@TipoPrestadorId		smallint,
	@TipoServicioId			tinyint,
	@URLBase				varchar(128),
	@TipoAutId				tinyint,
	@URLAut					varchar(128),
	@Token					varchar(128),
	@NombreUsuario			varchar(64),
	@Contrasena				varchar(64),
	@EstadoActivo			smallint

SELECT
	@CodigoError			= 0,
	@EntidadId				= 0,
	@PrestadorId			= 0,
	@Nombre					= 'MediRecreo',
	@NombreCorto			= 'MEDIRECREO',
	@NumeroConvenio			= 5018628,
	@Identificacion			= '1792160316001',
	@NacionalidadId			= 57, -- Ecuador
	@TipoIdentificacionId	= 3, -- RUC
	@TipoPrestadorId		= 6, -- Centro M�dico
	@TipoServicioId			= 1, -- 1 = REST, 2 = SOAP	
	@TipoAutId				= 1, -- 1 = Token, 2 = Usuario/Contrase�a
	@EstadoActivo			= 1,
	@URLAut					= 'Login',
	@Token					= '',

/***** DESARROLLO ************************************************************/
	@URLBase				= 'http://186.4.255.77/medirecreo/api/',
	@NombreUsuario			= 'saludsa',
	@Contrasena				= 'Saludsa2020'
/***** DESARROLLO ************************************************************/

/***** PRUEBAS ***************************************************************/
	--@URLBase				= '',	
	--@NombreUsuario			= '',
	--@Contrasena				= ''
/***** PRUEBAS ***************************************************************/

/***** PRODUCCI�N ************************************************************/
	--@URLBase				= '',	
	--@NombreUsuario			= '',
	--@Contrasena				= ''
/***** PRODUCCI�N ************************************************************/


/*Crear Especialidades en SQL Server Base de Datos Saludsa Tabla Catalogo.EspecialidadesMedicas*/





BEGIN TRANSACTION

/*---------------------------------------------------------------------------*/
/* ENTIDAD */
SELECT @EntidadId = a.EntidadId
FROM [Entidad].[Organizacion] a
WHERE a.NacionalidadId = @NacionalidadId
	AND a.TipoIdentificacionId = @TipoIdentificacionId
	AND a.Identificacion = @Identificacion

IF @EntidadId = 0
BEGIN
	INSERT INTO [Entidad].[Entidad] (TipoEntidadId)
	VALUES (2)

	SELECT
		@CodigoError	= @@ERROR,
		@EntidadId		= @@IDENTITY

	IF @CodigoError <> 0
	BEGIN
		ROLLBACK TRANSACTION
		PRINT 'Error creando Entidad. Se revertirón los cambios.'
		GOTO Finalizar
	END
END

/*---------------------------------------------------------------------------*/
/* ORGANIZACION */
IF EXISTS (SELECT 1 FROM [Entidad].[Organizacion] a WHERE a.EntidadId = @EntidadId)
BEGIN
	UPDATE [Entidad].[Organizacion]
	SET Nombre = @Nombre, NombreCorto = @NombreCorto
	WHERE EntidadId = @EntidadId
END
ELSE
BEGIN
	INSERT INTO [Entidad].[Organizacion] (EntidadId, NacionalidadId, TipoIdentificacionId, Identificacion, Nombre, NombreCorto)
	VALUES (@EntidadId, @NacionalidadId, @TipoIdentificacionId, @Identificacion, @Nombre, @NombreCorto)
END

SELECT @CodigoError = @@ERROR

IF @CodigoError <> 0
BEGIN
	ROLLBACK TRANSACTION
	PRINT 'Error creando Organización. Se revertirán los cambios.'
	GOTO Finalizar
END

/*---------------------------------------------------------------------------*/
/* PRESTADOR */
SELECT @PrestadorId = a.Id
FROM [Prestador].[Prestador] a
WHERE a.EntidadId = @EntidadId

IF @PrestadorId = 0
BEGIN
	INSERT INTO [Prestador].[Prestador] (TipoPrestadorId, EntidadId, NumeroConvenio, EstadoActivo)
	VALUES (@TipoPrestadorId, @EntidadId, @NumeroConvenio, 1)

	SELECT
		@CodigoError	= @@ERROR,
		@PrestadorId	= @@IDENTITY
END
ELSE
BEGIN
	UPDATE [Prestador].[Prestador]
	SET TipoPrestadorId = @TipoPrestadorId, NumeroConvenio = @NumeroConvenio, EstadoActivo = @EstadoActivo
	WHERE EntidadId = @EntidadId

	SELECT
		@CodigoError	= @@ERROR
END

IF @CodigoError <> 0
BEGIN
	ROLLBACK TRANSACTION
	PRINT 'Error creando Prestador. Se revertirán los cambios.'
	GOTO Finalizar
END
Print('Prestador')
Print(@PrestadorId)
Print('Entidad Id')
Print(@EntidadId)
/*---------------------------------------------------------------------------*/
/* CONFIGURACIÓN DE SERVICIOS DE CENTRO M�DICO - URLs Y AUTENTICACI�N */
IF EXISTS (SELECT 1 FROM [ServiciosMedicos].[ConfiguracionPrestadorSrvCita] a WHERE a.PrestadorId = @PrestadorId)
BEGIN
	UPDATE [ServiciosMedicos].[ConfiguracionPrestadorSrvCita]
	SET TipoServicioId = @TipoServicioId, URLBase = @URLBase, TipoAutId = @TipoAutId, URLAut = @URLAut, Token = @Token, NombreUsuario = @NombreUsuario, Contrasena = @Contrasena, EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
END
ELSE
BEGIN
	INSERT INTO [ServiciosMedicos].[ConfiguracionPrestadorSrvCita] (PrestadorId, TipoServicioId, URLBase, TipoAutId, URLAut, Token, NombreUsuario, Contrasena, EstadoActivo)
	VALUES (@PrestadorId, @TipoServicioId, @URLBase, @TipoAutId, @URLAut, @Token, @NombreUsuario, @Contrasena, @EstadoActivo)
END

SELECT @CodigoError	= @@ERROR

IF @CodigoError <> 0
BEGIN
	ROLLBACK TRANSACTION
	PRINT 'Error creando Configuracion del Servicio. Se revertir�n los cambios.'
	GOTO Finalizar
END

/*---------------------------------------------------------------------------*/
/* ESPECIALIDADES POR CIUDAD - ELIMINACI�N DE INFORMACI�N PREVIA E INSERSI�N DE NUEVA INFORMACI�N */
UPDATE [Catalogo].[EspecialidadCiudad]
SET EstadoActivo = 0
WHERE PrestadorId = @PrestadorId


IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GIN')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - GIN'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GIN'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GIN')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'

IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CLI')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - CLI'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CLI'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CLI')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
    
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEC')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - NEC'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEC'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEC')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'



IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CCV')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - CCV'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CCV'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CCV')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIR')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - CIR'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIR'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIR')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIRONC')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - CIRONC'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIRONC'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIRONC')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CPE')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - CPE'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CPE'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CPE')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIP')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - CIP'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIP'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIP')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ALE')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - ALE'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ALE'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ALE')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DER')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - DER'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DER'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DER')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CAR')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - CAR'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CAR'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CAR')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CARP')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - CARP'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CARP'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CARP')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'END')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - END'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'END'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'END')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ENDP')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - ENDP'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ENDP'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ENDP')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GAS')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - GAS'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GAS'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GAS')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GASP')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - GASP'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GASP'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GASP')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GER')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - GER'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GER'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GER')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEM')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - HEM'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEM'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEM')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEMP')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - HEMP'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEMP'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEMP')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GEN')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - GEN'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GEN'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GEN')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INF')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - INF'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INF'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INF')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INM')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - INM'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INM'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INM')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FAM')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - FAM'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FAM'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FAM')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DEP')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - DEP'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DEP'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DEP')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FIS')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - FIS'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FIS'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FIS')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEF')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - NEF'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEF'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEF')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEON')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - NEON'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEON'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEON')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEM')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - NEM'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEM'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEM')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEMP')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - NEMP'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEMP'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEMP')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NECP')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - NECP'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NECP'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NECP')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEU')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - NEU'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEU'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEU')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEUP')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - NEUP'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEUP'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEUP')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OFT')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - OFT'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OFT'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OFT')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONC')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - ONC'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONC'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONC')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONCP')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - ONCP'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONCP'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONCP')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OTO')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - OTO'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OTO'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OTO')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PED')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - PED'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PED'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PED')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PRO')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - PRO'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PRO'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PRO')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'REU')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - REU'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'REU'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'REU')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRA')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - TRA'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRA'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRA')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'URO')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - URO'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'URO'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'URO')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MNU')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - MNU'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MNU'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MNU')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'UROP')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - UROP'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'UROP'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'UROP')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FST')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - FST'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FST'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FST')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MGE')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - MGE'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MGE'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MGE')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRAP')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - TRAP'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRAP'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRAP')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DERP')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - DERP'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DERP'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DERP')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'
IF NOT EXISTS (SELECT 1 FROM Saludsa.Catalogo.EspecialidadCiudad WHERE PrestadorId = @PrestadorId 
AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'VAS')
AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito')))
BEGIN PRINT 'Insertando Especialidad x ciudad - VAS'
INSERT INTO [Catalogo].[EspecialidadCiudad] (EspecialidadId, CiudadId, PrestadorId, EstadoActivo) 
SELECT 
	EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'VAS'), 
	CiudadId = c.Id, 
	PrestadorId = @PrestadorId, 
	EstadoActivo = @EstadoActivo
FROM [Catalogo].[Ciudad] c
WHERE c.Nombre IN ('Quito')
END ELSE BEGIN PRINT 'Acutalizando Especialidad x ciudad - GEN (Quito)'
	UPDATE [Catalogo].[EspecialidadCiudad]
	SET EstadoActivo = @EstadoActivo
	WHERE PrestadorId = @PrestadorId
	AND EspecialidadId = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'VAS')
	AND CiudadId IN (SELECT a.[ID] FROM [Catalogo].[Ciudad] a WHERE a.Nombre IN ('Quito'))
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad.'


/*---------------------------------------------------------------------------*/
/* HOMOLOGACIONES - ELIMINACI�N DE INFORMACI�N PREVIA E INSERSI�N DE NUEVA HOMOLOGACI�N */
UPDATE [Homologacion].[Equivalencia]
SET EstadoActivo = @EstadoActivo
WHERE EntidadId = @EntidadId

IF @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	PRINT 'Error eliminando Homologaciones anteriores. Se revertir�n los cambios.'
	GOTO Finalizar
END

-- Ciudades - Temática = 2

IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 2 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[Ciudad] a WHERE a.[Nombre] = 'Quito'))
BEGIN PRINT 'Insertando ciudad Quito'
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 2, 
	CodigoExterno = N'1',
	DescripcionExterna = N'Quito',
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[Ciudad] a WHERE a.[Nombre] = 'Quito'), 
	CodigoAlfaHomologado = '', 
	DescripcionHomologada = N'Quito', 
	EstadoActivo = @EstadoActivo
END ELSE BEGIN PRINT 'Actualizando ciudad Quito'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo
	WHERE TematicaId = 2 AND EntidadId = @EntidadId
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[Ciudad] a WHERE a.[Nombre] = 'Quito')
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Ciudad Quito.'

-- Especialidades - Temática = 3

IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GIN') 
AND CodigoExterno = '1') 
BEGIN PRINT 'Insertando especialidad GIN' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'1', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GIN'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GIN'), 
	CodigoAlfaHomologado = 'GIN', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GIN'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad GIN'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'GIN'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GIN')
	AND CodigoExterno = '1'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad GIN.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CLI') 
AND CodigoExterno = '2') 
BEGIN PRINT 'Insertando especialidad CLI' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'2', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CLI'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CLI'), 
	CodigoAlfaHomologado = 'CLI', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CLI'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad CLI'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'CLI'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CLI')
	AND CodigoExterno = '2'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad CLI.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEC') 
AND CodigoExterno = '3') 
BEGIN PRINT 'Insertando especialidad NEC' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'3', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEC'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEC'), 
	CodigoAlfaHomologado = 'NEC', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEC'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad NEC'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'NEC'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEC')
	AND CodigoExterno = '3'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad NEC.'

IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CCV') 
AND CodigoExterno = '6') 
BEGIN PRINT 'Insertando especialidad CCV' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'6', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CCV'),  
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CCV'), 
	CodigoAlfaHomologado = 'CCV', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CCV'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad CCV'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'CCV'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CCV')
	AND CodigoExterno = '6'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad CCV.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIR') 
AND CodigoExterno = '11') 
BEGIN PRINT 'Insertando especialidad CIR' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'11', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIR'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIR'), 
	CodigoAlfaHomologado = 'CIR', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIR'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad CIR'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'CIR'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIR')
	AND CodigoExterno = '11'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad CIR.'

IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIRONC') 
AND CodigoExterno = '13') 
BEGIN PRINT 'Insertando especialidad CIRONC' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'13', 
	DescripcionExterna =(SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIRONC'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIRONC'), 
	CodigoAlfaHomologado = 'CIRONC', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIRONC'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad CIRONC'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'CIRONC'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIRONC')
	AND CodigoExterno = '13'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad CIRONC.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CPE') 
AND CodigoExterno = '14') 
BEGIN PRINT 'Insertando especialidad CPE' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'14', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CPE'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CPE'), 
	CodigoAlfaHomologado = 'CPE', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CPE'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad CPE'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'CPE'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CPE')
	AND CodigoExterno = '14'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad CPE.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIP') 
AND CodigoExterno = '15') 
BEGIN PRINT 'Insertando especialidad CIP' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'15', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIP'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIP'), 
	CodigoAlfaHomologado = 'CIP', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIP'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad CIP'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'CIP'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CIP')
	AND CodigoExterno = '15'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad CIP.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ALE') 
AND CodigoExterno = '18') 
BEGIN PRINT 'Insertando especialidad ALE' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'18', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ALE'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ALE'), 
	CodigoAlfaHomologado = 'ALE', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ALE'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad ALE'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'ALE'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ALE')
	AND CodigoExterno = '18'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad ALE.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DER') 
AND CodigoExterno = '20') 
BEGIN PRINT 'Insertando especialidad DER' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'20', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DER'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DER'), 
	CodigoAlfaHomologado = 'DER', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DER'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad DER'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'DER'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DER')
	AND CodigoExterno = '20'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad DER.'


    IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CAR') 
AND CodigoExterno = '21') 
BEGIN PRINT 'Insertando especialidad CAR' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'21', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CAR'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CAR'), 
	CodigoAlfaHomologado = 'CAR', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CAR'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad CAR'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'CAR'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CAR')
	AND CodigoExterno = '21'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad CAR.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CARP') 
AND CodigoExterno = '22') 
BEGIN PRINT 'Insertando especialidad CARP' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'22', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CARP'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CARP'), 
	CodigoAlfaHomologado = 'CARP', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CARP'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad CARP'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'CARP'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'CARP')
	AND CodigoExterno = '22'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad CARP.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'END') 
AND CodigoExterno = '26') 
BEGIN PRINT 'Insertando especialidad END' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'26', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'END'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'END'), 
	CodigoAlfaHomologado = 'END', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'END'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad END'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'END'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'END')
	AND CodigoExterno = '26'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad END.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ENDP') 
AND CodigoExterno = '27') 
BEGIN PRINT 'Insertando especialidad ENDP' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'27', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ENDP'),  
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ENDP'), 
	CodigoAlfaHomologado = 'ENDP', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ENDP'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad ENDP'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'ENDP'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ENDP')
	AND CodigoExterno = '27'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad ENDP.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GAS') 
AND CodigoExterno = '32') 
BEGIN PRINT 'Insertando especialidad GAS' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'32', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GAS'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GAS'), 
	CodigoAlfaHomologado = 'GAS', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GAS'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad GAS'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'GAS'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GAS')
	AND CodigoExterno = '32'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad GAS.'



IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GASP') 
AND CodigoExterno = '33') 
BEGIN PRINT 'Insertando especialidad GASP' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'33', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GASP'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GASP'), 
	CodigoAlfaHomologado = 'GASP', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GASP'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad GASP'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'GASP'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GASP')
	AND CodigoExterno = '33'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad GASP.'



IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GER') 
AND CodigoExterno = '34') 
BEGIN PRINT 'Insertando especialidad GER' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'34', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GER'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GER'), 
	CodigoAlfaHomologado = 'GER', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GER'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad GER'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'GER'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GER')
	AND CodigoExterno = '34'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad GER.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEM') 
AND CodigoExterno = '36') 
BEGIN PRINT 'Insertando especialidad HEM' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'36', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEM'),  
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEM'), 
	CodigoAlfaHomologado = 'HEM', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEM'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad HEM'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'HEM'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEM')
	AND CodigoExterno = '36'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad HEM.'



IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEMP') 
AND CodigoExterno = '37') 
BEGIN PRINT 'Insertando especialidad HEMP' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'37', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEMP'),  
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEMP'), 
	CodigoAlfaHomologado = 'HEMP', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEMP'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad HEMP'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'HEMP'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'HEMP')
	AND CodigoExterno = '37'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad HEMP.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GEN') 
AND CodigoExterno = '41') 
BEGIN PRINT 'Insertando especialidad GEN' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'41', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GEN'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GEN'), 
	CodigoAlfaHomologado = 'GEN', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GEN'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad GEN'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'GEN'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'GEN')
	AND CodigoExterno = '41'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad GEN.'



IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INF') 
AND CodigoExterno = '42') 
BEGIN PRINT 'Insertando especialidad INF' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'42', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INF'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INF'), 
	CodigoAlfaHomologado = 'INF', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INF'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad INF'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'INF'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INF')
	AND CodigoExterno = '42'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad INF.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INM') 
AND CodigoExterno = '43') 
BEGIN PRINT 'Insertando especialidad INM' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'43', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INM'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INM'), 
	CodigoAlfaHomologado = 'INM', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INM'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad INM'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'INM'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'INM')
	AND CodigoExterno = '43'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad INM.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FAM') 
AND CodigoExterno = '45') 
BEGIN PRINT 'Insertando especialidad FAM' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'45', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FAM'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FAM'), 
	CodigoAlfaHomologado = 'FAM', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FAM'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad FAM'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'FAM'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FAM')
	AND CodigoExterno = '45'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad FAM.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DEP') 
AND CodigoExterno = '46') 
BEGIN PRINT 'Insertando especialidad DEP' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'46', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DEP'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DEP'), 
	CodigoAlfaHomologado = 'DEP', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DEP'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad DEP'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'DEP'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DEP')
	AND CodigoExterno = '46'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad DEP.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FIS') 
AND CodigoExterno = '47') 
BEGIN PRINT 'Insertando especialidad FIS' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'47', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FIS'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FIS'), 
	CodigoAlfaHomologado = 'FIS', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FIS'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad FIS'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'FIS'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FIS')
	AND CodigoExterno = '47'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad FIS.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEF') 
AND CodigoExterno = '48') 
BEGIN PRINT 'Insertando especialidad NEF' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'48', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEF'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEF'), 
	CodigoAlfaHomologado = 'NEF', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEF'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad NEF'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'NEF'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEF')
	AND CodigoExterno = '48'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad NEF.'



IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEON') 
AND CodigoExterno = '49') 
BEGIN PRINT 'Insertando especialidad NEON' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'49', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEON'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEON'), 
	CodigoAlfaHomologado = 'NEON', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEON'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad NEON'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'NEON'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEON')
	AND CodigoExterno = '49'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad NEON.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEM') 
AND CodigoExterno = '50') 
BEGIN PRINT 'Insertando especialidad NEM' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'50', 
	DescripcionExterna =(SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEM'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEM'), 
	CodigoAlfaHomologado = 'NEM', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEM'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad NEM'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'NEM'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEM')
	AND CodigoExterno = '50'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad NEM.'

IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEMP') 
AND CodigoExterno = '51') 
BEGIN PRINT 'Insertando especialidad NEMP' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'51', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEMP'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEMP'), 
	CodigoAlfaHomologado = 'NEMP', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEMP'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad NEMP'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'NEMP'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEMP')
	AND CodigoExterno = '51'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad NEMP.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NECP') 
AND CodigoExterno = '52') 
BEGIN PRINT 'Insertando especialidad NECP' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'52', 
	DescripcionExterna =(SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NECP'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NECP'), 
	CodigoAlfaHomologado = 'NECP', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NECP'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad NECP'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'NECP'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NECP')
	AND CodigoExterno = '52'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad NECP.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEU') 
AND CodigoExterno = '53') 
BEGIN PRINT 'Insertando especialidad NEU' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'53', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEU'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEU'), 
	CodigoAlfaHomologado = 'NEU', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEU'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad NEU'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'NEU'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEU')
	AND CodigoExterno = '53'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad NEU.'



IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEUP') 
AND CodigoExterno = '54') 
BEGIN PRINT 'Insertando especialidad NEUP' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'54', 
	DescripcionExterna =(SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEUP'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEUP'), 
	CodigoAlfaHomologado = 'NEUP', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEUP'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad NEUP'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'NEUP'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'NEUP')
	AND CodigoExterno = '54'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad NEUP.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OFT') 
AND CodigoExterno = '58') 
BEGIN PRINT 'Insertando especialidad OFT' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'58', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OFT'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OFT'), 
	CodigoAlfaHomologado = 'OFT', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OFT'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad OFT'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'OFT'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OFT')
	AND CodigoExterno = '58'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad OFT.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONC') 
AND CodigoExterno = '59') 
BEGIN PRINT 'Insertando especialidad ONC' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'59', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONC'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONC'), 
	CodigoAlfaHomologado = 'ONC', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONC'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad ONC'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'ONC'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONC')
	AND CodigoExterno = '59'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad ONC.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONCP') 
AND CodigoExterno = '60') 
BEGIN PRINT 'Insertando especialidad ONCP' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'60', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONCP'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONCP'), 
	CodigoAlfaHomologado = 'ONCP', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONCP'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad ONCP'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'ONCP'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'ONCP')
	AND CodigoExterno = '60'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad ONCP.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OTO') 
AND CodigoExterno = '62') 
BEGIN PRINT 'Insertando especialidad OTO' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'62', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OTO'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OTO'), 
	CodigoAlfaHomologado = 'OTO', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OTO'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad OTO'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'OTO'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'OTO')
	AND CodigoExterno = '62'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad OTO.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PED') 
AND CodigoExterno = '64') 
BEGIN PRINT 'Insertando especialidad PED' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'64', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PED'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PED'), 
	CodigoAlfaHomologado = 'PED', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PED'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad PED'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'PED'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PED')
	AND CodigoExterno = '64'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad PED.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PRO') 
AND CodigoExterno = '65') 
BEGIN PRINT 'Insertando especialidad PRO' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'65', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PRO'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PRO'), 
	CodigoAlfaHomologado = 'PRO', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PRO'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad PRO'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'PRO'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'PRO')
	AND CodigoExterno = '65'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad PRO.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'REU') 
AND CodigoExterno = '69') 
BEGIN PRINT 'Insertando especialidad REU' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'69', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'REU'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'REU'), 
	CodigoAlfaHomologado = 'REU', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'REU'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad REU'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'REU'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'REU')
	AND CodigoExterno = '69'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad REU.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRA') 
AND CodigoExterno = '74') 
BEGIN PRINT 'Insertando especialidad TRA' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'74', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRA'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRA'), 
	CodigoAlfaHomologado = 'TRA', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRA'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad TRA'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'TRA'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRA')
	AND CodigoExterno = '74'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad TRA.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'URO') 
AND CodigoExterno = '75') 
BEGIN PRINT 'Insertando especialidad URO' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'75', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'URO'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'URO'), 
	CodigoAlfaHomologado = 'URO', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'URO'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad URO'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'URO'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'URO')
	AND CodigoExterno = '75'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad URO.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MNU') 
AND CodigoExterno = '79') 
BEGIN PRINT 'Insertando especialidad MNU' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'79', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MNU'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MNU'), 
	CodigoAlfaHomologado = 'MNU', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MNU'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad MNU'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'MNU'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MNU')
	AND CodigoExterno = '79'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad MNU.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'UROP') 
AND CodigoExterno = '77') 
BEGIN PRINT 'Insertando especialidad UROP' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'77', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'UROP'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'UROP'), 
	CodigoAlfaHomologado = 'UROP', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'UROP'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad UROP'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'UROP'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'UROP')
	AND CodigoExterno = '77'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad UROP.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FST') 
AND CodigoExterno = '84') 
BEGIN PRINT 'Insertando especialidad FST' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'84', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FST'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FST'), 
	CodigoAlfaHomologado = 'FST', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FST'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad FST'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'FST'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'FST')
	AND CodigoExterno = '84'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad FST.'



IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MGE') 
AND CodigoExterno = '87') 
BEGIN PRINT 'Insertando especialidad MGE' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'87', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MGE'),
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MGE'), 
	CodigoAlfaHomologado = 'MGE', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MGE'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad MGE'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'MGE'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'MGE')
	AND CodigoExterno = '87'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad MGE.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRAP') 
AND CodigoExterno = '96') 
BEGIN PRINT 'Insertando especialidad TRAP' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'96', 
	DescripcionExterna = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRAP'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRAP'), 
	CodigoAlfaHomologado = 'TRAP', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRAP'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad TRAP'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'TRAP'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'TRAP')
	AND CodigoExterno = '96'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad TRAP.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DERP') 
AND CodigoExterno = '25') 
BEGIN PRINT 'Insertando especialidad DERP' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'25', 
	DescripcionExterna =(SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DERP'), 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DERP'), 
	CodigoAlfaHomologado = 'DERP', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DERP'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad DERP'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'DERP'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'DERP')
	AND CodigoExterno = '25'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad DERP.'


IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 3 AND EntidadId = @EntidadId 
AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'VAS') 
AND CodigoExterno = '17') 
BEGIN PRINT 'Insertando especialidad VAS' 
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 3, 
	CodigoExterno = N'17', 
	DescripcionExterna = N'CIRUGIA VASCULAR ANGIOLOGIA', 
	CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'VAS'), 
	CodigoAlfaHomologado = 'VAS', 
	DescripcionHomologada = (SELECT a.[Nombre] FROM Saludsa.[Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'VAS'), 
	EstadoActivo = @EstadoActivo

END ELSE BEGIN PRINT 'Actualizando especialidad VAS'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo, CodigoAlfaHomologado = 'VAS'
	WHERE TematicaId = 3 AND EntidadId = @EntidadId 
	AND CodigoHomologado = (SELECT a.[Id] FROM [Catalogo].[EspecialidadMedica] a WHERE a.[CodigoAlfa] = 'VAS')
	AND CodigoExterno = '17'
END
IF @@ERROR <> 0
	PRINT 'Error creando Homologación de Especialidad VAS.'

----------------------------------------------------------------------------------------

-- Sucursales - Temática = 5
IF NOT EXISTS (SELECT 1 FROM Saludsa.Homologacion.Equivalencia WHERE TematicaId = 5 AND EntidadId = @EntidadId AND CodigoExterno = N'1')
BEGIN PRINT 'Insertando sucursal MEDIRECREO  C.C. EL RECREO'
INSERT INTO [Homologacion].[Equivalencia] (EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo)
SELECT 
	EntidadId = @EntidadId, 
	TematicaId = 5, 
	CodigoExterno = N'1', 
	DescripcionExterna = N'MEDIRECREO  C.C. EL RECREO', 
	CodigoHomologado = (SELECT (COALESCE(MAX(x.CodigoHomologado), 0) + 1) FROM [Homologacion].[Equivalencia] x WHERE x.TematicaId = 5), 
	CodigoAlfaHomologado = CONVERT(VARCHAR, @EntidadId) + '-' + CONVERT(VARCHAR, (SELECT a.[Id] FROM [Catalogo].[Ciudad] a WHERE a.[Nombre] = 'Quito')) + '-' + CONVERT(VARCHAR, (SELECT (COALESCE(MAX(x.CodigoHomologado), 0) + 1) FROM [Homologacion].[Equivalencia] x WHERE x.TematicaId = 5)),
	DescripcionHomologada = N'MEDIRECREO  C.C. EL RECREO', 
	EstadoActivo = @EstadoActivo 
END ELSE BEGIN PRINT 'Actualizando sucursal MEDIRECREO  C.C. EL RECREO'
	UPDATE [Homologacion].[Equivalencia]
	SET EstadoActivo = @EstadoActivo
	WHERE TematicaId = 5 AND EntidadId = @EntidadId AND CodigoExterno = N'1'
END
IF @@ERROR <> 0
PRINT 'Error creando Homologación de Sucursal MEDIRECREO  C.C. EL RECREO.'




-- Motivos de cancelación - Temática = 6
-- Insercián de catálogos de motivos de cancelación
IF EXISTS (SELECT 1 FROM [Saludsa].[dbo].[ADM_CATALOGO] WHERE Cat_Codigo = 'MOTCANCITA')
BEGIN IF EXISTS (SELECT 1 FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] 
WHERE Itc_Codigo = 'MC_MDRC_1')
BEGIN PRINT 'Item MC_MDRC_1 ya existe' 
END ELSE 
BEGIN PRINT 'Insertando ítem catálogo cancelación' 
INSERT INTO [Saludsa].[dbo].[ADM_ITEM_CATALOGO] (Itc_Nombre, Itc_Codigo, Itc_Descripcion, Itc_Estado, Itc_Padre, Cat_Id) 
VALUES(N'Motivo cancelación MEDIRECREO 1', N'MC_MDRC_1', N'Paciente no puede ir', N'A', NULL, 
(SELECT Cat_Id FROM [Saludsa].[dbo].[ADM_CATALOGO] WHERE Cat_Codigo = 'MOTCANCITA'))END 
END ELSE BEGIN PRINT 'Catálogo de cancelación no existe'END


IF EXISTS (SELECT 1 FROM [Saludsa].[dbo].[ADM_CATALOGO] WHERE Cat_Codigo = 'MOTCANCITA')
BEGIN IF EXISTS (SELECT 1 FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] 
WHERE Itc_Codigo = 'MC_MDRC_2')
BEGIN PRINT 'Item MC_MDRC_2 ya existe' 
END ELSE 
BEGIN PRINT 'Insertando ítem catálogo cancelación' 
INSERT INTO [Saludsa].[dbo].[ADM_ITEM_CATALOGO] (Itc_Nombre, Itc_Codigo, Itc_Descripcion, Itc_Estado, Itc_Padre, Cat_Id) 
VALUES(N'Motivo cancelación MEDIRECREO 2', N'MC_MDRC_2', N'Paciente ya tiene otra cita', N'A', NULL, 
(SELECT Cat_Id FROM [Saludsa].[dbo].[ADM_CATALOGO] WHERE Cat_Codigo = 'MOTCANCITA'))END 
END ELSE BEGIN PRINT 'Catálogo de cancelación no existe'END


IF EXISTS (SELECT 1 FROM [Saludsa].[dbo].[ADM_CATALOGO] WHERE Cat_Codigo = 'MOTCANCITA')
BEGIN IF EXISTS (SELECT 1 FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] 
WHERE Itc_Codigo = 'MC_MDRC_3')
BEGIN PRINT 'Item MC_MDRC_3 ya existe' 
END ELSE 
BEGIN PRINT 'Insertando ítem catálogo cancelación' 
INSERT INTO [Saludsa].[dbo].[ADM_ITEM_CATALOGO] (Itc_Nombre, Itc_Codigo, Itc_Descripcion, Itc_Estado, Itc_Padre, Cat_Id) 
VALUES(N'Motivo cancelación MEDIRECREO 3', N'MC_MDRC_3', N'Médico con permiso', N'A', NULL, 
(SELECT Cat_Id FROM [Saludsa].[dbo].[ADM_CATALOGO] WHERE Cat_Codigo = 'MOTCANCITA'))END 
END ELSE BEGIN PRINT 'Catálogo de cancelación no existe'END


IF EXISTS (SELECT 1 FROM [Saludsa].[dbo].[ADM_CATALOGO] WHERE Cat_Codigo = 'MOTCANCITA')
BEGIN IF EXISTS (SELECT 1 FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] 
WHERE Itc_Codigo = 'MC_MDRC_4')
BEGIN PRINT 'Item MC_MDRC_4 ya existe' 
END ELSE 
BEGIN PRINT 'Insertando ítem catálogo cancelación' 
INSERT INTO [Saludsa].[dbo].[ADM_ITEM_CATALOGO] (Itc_Nombre, Itc_Codigo, Itc_Descripcion, Itc_Estado, Itc_Padre, Cat_Id) 
VALUES(N'Motivo cancelación MEDIRECREO 4', N'MC_MDRC_4', N'Re agendamiento de Cita', N'A', NULL, 
(SELECT Cat_Id FROM [Saludsa].[dbo].[ADM_CATALOGO] WHERE Cat_Codigo = 'MOTCANCITA'))END 
END ELSE BEGIN PRINT 'Catálogo de cancelación no existe'END


IF EXISTS (SELECT 1 FROM [Saludsa].[dbo].[ADM_CATALOGO] WHERE Cat_Codigo = 'MOTCANCITA')
BEGIN IF EXISTS (SELECT 1 FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] 
WHERE Itc_Codigo = 'MC_MDRC_5')
BEGIN PRINT 'Item MC_MDRC_5 ya existe' 
END ELSE 
BEGIN PRINT 'Insertando ítem catálogo cancelación' 
INSERT INTO [Saludsa].[dbo].[ADM_ITEM_CATALOGO] (Itc_Nombre, Itc_Codigo, Itc_Descripcion, Itc_Estado, Itc_Padre, Cat_Id) 
VALUES(N'Motivo cancelación MEDIRECREO 5', N'MC_MDRC_5', N'Ya no quiere la Cita', N'A', NULL, 
(SELECT Cat_Id FROM [Saludsa].[dbo].[ADM_CATALOGO] WHERE Cat_Codigo = 'MOTCANCITA'))END 
END ELSE BEGIN PRINT 'Catálogo de cancelación no existe'END


IF EXISTS (SELECT 1 FROM [Saludsa].[dbo].[ADM_CATALOGO] WHERE Cat_Codigo = 'MOTCANCITA')
BEGIN IF EXISTS (SELECT 1 FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] 
WHERE Itc_Codigo = 'MC_MDRC_6')
BEGIN PRINT 'Item MC_MDRC_6 ya existe' 
END ELSE 
BEGIN PRINT 'Insertando ítem catálogo cancelación' 
INSERT INTO [Saludsa].[dbo].[ADM_ITEM_CATALOGO] (Itc_Nombre, Itc_Codigo, Itc_Descripcion, Itc_Estado, Itc_Padre, Cat_Id) 
VALUES(N'Motivo cancelación MEDIRECREO 6', N'MC_MDRC_6', N'No pude asistir a la cita', N'A', NULL, 
(SELECT Cat_Id FROM [Saludsa].[dbo].[ADM_CATALOGO] WHERE Cat_Codigo = 'MOTCANCITA'))END 
END ELSE BEGIN PRINT 'Catálogo de cancelación no existe'END

-- Insersión de homologación motivos de cancelación
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [Saludsa].[Homologacion].[Equivalencia] WHERE TematicaId = 6 AND CodigoHomologado = 
(SELECT Itc_Id FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] WHERE Itc_Codigo = 'MC_MDRC_1'))
BEGIN PRINT 'Insertando homologación de cancelación para MC_MDRC_1' 
INSERT INTO [Saludsa].[Homologacion].[Equivalencia](EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo) 
VALUES(@EntidadId, 6, N'1', N'Paciente no puede ir', (SELECT Itc_Id FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] WHERE Itc_Codigo = 'MC_MDRC_1'), N'', N'Paciente no puede ir', 1)
END ELSE 
BEGIN PRINT 'Ítem homologado MC_MDRC_1 ya existe' END


IF NOT EXISTS (SELECT 1 FROM [Saludsa].[Homologacion].[Equivalencia] WHERE TematicaId = 6 AND CodigoHomologado = 
(SELECT Itc_Id FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] WHERE Itc_Codigo = 'MC_MDRC_2'))
BEGIN PRINT 'Insertando homologación de cancelación para MC_MDRC_2' 
INSERT INTO [Saludsa].[Homologacion].[Equivalencia](EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo) 
VALUES(@EntidadId, 6, N'2', N'Paciente ya tiene otra cita', (SELECT Itc_Id FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] WHERE Itc_Codigo = 'MC_MDRC_2'), N'', N'Paciente ya tiene otra cita', 1)
END ELSE 
BEGIN PRINT 'Ítem homologado MC_MDRC_2 ya existe' END


IF NOT EXISTS (SELECT 1 FROM [Saludsa].[Homologacion].[Equivalencia] WHERE TematicaId = 6 AND CodigoHomologado = 
(SELECT Itc_Id FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] WHERE Itc_Codigo = 'MC_MDRC_3'))
BEGIN PRINT 'Insertando homologación de cancelación para MC_MDRC_3' 
INSERT INTO [Saludsa].[Homologacion].[Equivalencia](EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo) 
VALUES(@EntidadId, 6, N'3', N'Médico con permiso', (SELECT Itc_Id FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] WHERE Itc_Codigo = 'MC_MDRC_3'), N'', N'Médico con permiso', 1)
END ELSE 
BEGIN PRINT 'Ítem homologado MC_MDRC_3 ya existe' END


IF NOT EXISTS (SELECT 1 FROM [Saludsa].[Homologacion].[Equivalencia] WHERE TematicaId = 6 AND CodigoHomologado = 
(SELECT Itc_Id FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] WHERE Itc_Codigo = 'MC_MDRC_4'))
BEGIN PRINT 'Insertando homologación de cancelación para MC_MDRC_4' 
INSERT INTO [Saludsa].[Homologacion].[Equivalencia](EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo) 
VALUES(@EntidadId, 6, N'4', N'Re agendamiento de Cita', (SELECT Itc_Id FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] WHERE Itc_Codigo = 'MC_MDRC_4'), N'', N'Re agendamiento de Cita', 1)
END ELSE 
BEGIN PRINT 'Ítem homologado MC_MDRC_4 ya existe' END


IF NOT EXISTS (SELECT 1 FROM [Saludsa].[Homologacion].[Equivalencia] WHERE TematicaId = 6 AND CodigoHomologado = 
(SELECT Itc_Id FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] WHERE Itc_Codigo = 'MC_MDRC_5'))
BEGIN PRINT 'Insertando homologación de cancelación para MC_MDRC_5' 
INSERT INTO [Saludsa].[Homologacion].[Equivalencia](EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo) 
VALUES(@EntidadId, 6, N'5', N'Ya no quiere la Cita', (SELECT Itc_Id FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] WHERE Itc_Codigo = 'MC_MDRC_5'), N'', N'Ya no quiere la Cita', 1)
END ELSE 
BEGIN PRINT 'Ítem homologado MC_MDRC_5 ya existe' END


IF NOT EXISTS (SELECT 1 FROM [Saludsa].[Homologacion].[Equivalencia] WHERE TematicaId = 6 AND CodigoHomologado = 
(SELECT Itc_Id FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] WHERE Itc_Codigo = 'MC_MDRC_6'))
BEGIN PRINT 'Insertando homologación de cancelación para MC_MDRC_6' 
INSERT INTO [Saludsa].[Homologacion].[Equivalencia](EntidadId, TematicaId, CodigoExterno, DescripcionExterna, CodigoHomologado, CodigoAlfaHomologado, DescripcionHomologada, EstadoActivo) 
VALUES(@EntidadId, 6, N'6', N'No pude asistir a la cita', (SELECT Itc_Id FROM [Saludsa].[dbo].[ADM_ITEM_CATALOGO] WHERE Itc_Codigo = 'MC_MDRC_6'), N'', N'No pude asistir a la cita', 1)
END ELSE 
BEGIN PRINT 'Ítem homologado MC_MDRC_6 ya existe' END

/*---------------------------------------------------------------------------*/
COMMIT TRANSACTION

Finalizar:

GO

