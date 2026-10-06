/* =====================================================================
   09_normalizacion_catalogos.sql
   Corrección del docente: las categorías de Persona y Observacion
   (tipo de documento, sexo, estado civil, zona, tipo de vivienda, estrato,
   tipo de contrato, régimen de salud, discapacidad y canal) pasan de
   restricciones CHECK a TABLAS DE CATÁLOGO con clave foránea (3FN).

   Este script se ejecuta sobre la base YA CARGADA: no borra datos.
   1. Crea y llena los 10 catálogos.
   2. Verifica que no haya valores huérfanos (debe dar 0).
   3. Quita las restricciones CHECK y crea las claves foráneas.
   La observación sigue guardando el código, ahora como FK al catálogo,
   por lo que los paquetes SSIS no necesitan cambios para esta parte.
   (El script 04 ya incluye estos catálogos para instalaciones nuevas.)
   ===================================================================== */
USE PersonasETL;
GO

/* ---------- 1. Catálogos ---------- */
IF OBJECT_ID(N'dbo.TipoDocumento') IS NULL
    CREATE TABLE dbo.TipoDocumento (TipoDocumentoCodigo NVARCHAR(2) NOT NULL CONSTRAINT PK_TipoDocumento PRIMARY KEY, Nombre NVARCHAR(40) NOT NULL);
IF OBJECT_ID(N'dbo.Sexo') IS NULL
    CREATE TABLE dbo.Sexo (SexoCodigo NVARCHAR(2) NOT NULL CONSTRAINT PK_Sexo PRIMARY KEY, Nombre NVARCHAR(30) NOT NULL);
IF OBJECT_ID(N'dbo.EstadoCivil') IS NULL
    CREATE TABLE dbo.EstadoCivil (EstadoCivilCodigo NVARCHAR(15) NOT NULL CONSTRAINT PK_EstadoCivil PRIMARY KEY, Nombre NVARCHAR(30) NOT NULL);
IF OBJECT_ID(N'dbo.Zona') IS NULL
    CREATE TABLE dbo.Zona (ZonaCodigo NVARCHAR(10) NOT NULL CONSTRAINT PK_Zona PRIMARY KEY, Nombre NVARCHAR(30) NOT NULL);
IF OBJECT_ID(N'dbo.TipoVivienda') IS NULL
    CREATE TABLE dbo.TipoVivienda (TipoViviendaCodigo NVARCHAR(15) NOT NULL CONSTRAINT PK_TipoVivienda PRIMARY KEY, Nombre NVARCHAR(30) NOT NULL);
IF OBJECT_ID(N'dbo.Estrato') IS NULL
    CREATE TABLE dbo.Estrato (EstratoCodigo INT NOT NULL CONSTRAINT PK_Estrato PRIMARY KEY, Nombre NVARCHAR(30) NOT NULL);
IF OBJECT_ID(N'dbo.TipoContrato') IS NULL
    CREATE TABLE dbo.TipoContrato (TipoContratoCodigo NVARCHAR(15) NOT NULL CONSTRAINT PK_TipoContrato PRIMARY KEY, Nombre NVARCHAR(40) NOT NULL);
IF OBJECT_ID(N'dbo.RegimenSalud') IS NULL
    CREATE TABLE dbo.RegimenSalud (RegimenSaludCodigo NVARCHAR(15) NOT NULL CONSTRAINT PK_RegimenSalud PRIMARY KEY, Nombre NVARCHAR(30) NOT NULL);
IF OBJECT_ID(N'dbo.CondicionDiscapacidad') IS NULL
    CREATE TABLE dbo.CondicionDiscapacidad (DiscapacidadCodigo NVARCHAR(2) NOT NULL CONSTRAINT PK_CondicionDiscapacidad PRIMARY KEY, Nombre NVARCHAR(30) NOT NULL);
IF OBJECT_ID(N'dbo.CanalOrigen') IS NULL
    CREATE TABLE dbo.CanalOrigen (CanalOrigenCodigo NVARCHAR(12) NOT NULL CONSTRAINT PK_CanalOrigen PRIMARY KEY, Nombre NVARCHAR(30) NOT NULL);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.TipoDocumento) INSERT INTO dbo.TipoDocumento VALUES (N'CC', N'Cédula de ciudadanía'), (N'CE', N'Cédula de extranjería'), (N'PA', N'Pasaporte');
IF NOT EXISTS (SELECT 1 FROM dbo.Sexo) INSERT INTO dbo.Sexo VALUES (N'M', N'Masculino'), (N'F', N'Femenino'), (N'ND', N'No definido');
IF NOT EXISTS (SELECT 1 FROM dbo.EstadoCivil) INSERT INTO dbo.EstadoCivil VALUES (N'SOLTERO', N'Soltero(a)'), (N'CASADO', N'Casado(a)'), (N'UNION_LIBRE', N'Unión libre'), (N'DIVORCIADO', N'Divorciado(a)'), (N'VIUDO', N'Viudo(a)');
IF NOT EXISTS (SELECT 1 FROM dbo.Zona) INSERT INTO dbo.Zona VALUES (N'URBANA', N'Urbana'), (N'RURAL', N'Rural');
IF NOT EXISTS (SELECT 1 FROM dbo.TipoVivienda) INSERT INTO dbo.TipoVivienda VALUES (N'PROPIA', N'Propia'), (N'ARRENDADA', N'Arrendada'), (N'FAMILIAR', N'Familiar'), (N'OTRA', N'Otra');
IF NOT EXISTS (SELECT 1 FROM dbo.Estrato) INSERT INTO dbo.Estrato VALUES (1, N'Bajo-bajo'), (2, N'Bajo'), (3, N'Medio-bajo'), (4, N'Medio'), (5, N'Medio-alto'), (6, N'Alto');
IF NOT EXISTS (SELECT 1 FROM dbo.TipoContrato) INSERT INTO dbo.TipoContrato VALUES (N'FIJO', N'Término fijo'), (N'INDEFINIDO', N'Término indefinido'), (N'SERVICIOS', N'Prestación de servicios'), (N'NO_APLICA', N'No aplica');
IF NOT EXISTS (SELECT 1 FROM dbo.RegimenSalud) INSERT INTO dbo.RegimenSalud VALUES (N'CONTRIBUTIVO', N'Contributivo'), (N'SUBSIDIADO', N'Subsidiado'), (N'ESPECIAL', N'Especial'), (N'NO_AFILIADO', N'No afiliado');
IF NOT EXISTS (SELECT 1 FROM dbo.CondicionDiscapacidad) INSERT INTO dbo.CondicionDiscapacidad VALUES (N'SI', N'Sí'), (N'NO', N'No'), (N'ND', N'No definido');
IF NOT EXISTS (SELECT 1 FROM dbo.CanalOrigen) INSERT INTO dbo.CanalOrigen VALUES (N'WEB', N'Web'), (N'TELEFONO', N'Teléfono'), (N'PRESENCIAL', N'Presencial'), (N'FAX', N'Fax');
GO

/* ---------- 2. Verificación de huérfanos (todas las filas deben dar 0) ---------- */
SELECT N'Persona.TipoDocumento' AS Columna, COUNT(*) AS ValoresSinCatalogo FROM dbo.Persona x WHERE x.TipoDocumento IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.TipoDocumento c WHERE c.TipoDocumentoCodigo = x.TipoDocumento)
UNION ALL SELECT N'Persona.Sexo' AS Columna, COUNT(*) AS ValoresSinCatalogo FROM dbo.Persona x WHERE x.Sexo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Sexo c WHERE c.SexoCodigo = x.Sexo)
UNION ALL SELECT N'Observacion.EstadoCivil' AS Columna, COUNT(*) AS ValoresSinCatalogo FROM dbo.Observacion x WHERE x.EstadoCivil IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.EstadoCivil c WHERE c.EstadoCivilCodigo = x.EstadoCivil)
UNION ALL SELECT N'Observacion.Zona' AS Columna, COUNT(*) AS ValoresSinCatalogo FROM dbo.Observacion x WHERE x.Zona IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Zona c WHERE c.ZonaCodigo = x.Zona)
UNION ALL SELECT N'Observacion.TipoVivienda' AS Columna, COUNT(*) AS ValoresSinCatalogo FROM dbo.Observacion x WHERE x.TipoVivienda IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.TipoVivienda c WHERE c.TipoViviendaCodigo = x.TipoVivienda)
UNION ALL SELECT N'Observacion.Estrato' AS Columna, COUNT(*) AS ValoresSinCatalogo FROM dbo.Observacion x WHERE x.Estrato IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Estrato c WHERE c.EstratoCodigo = x.Estrato)
UNION ALL SELECT N'Observacion.TipoContrato' AS Columna, COUNT(*) AS ValoresSinCatalogo FROM dbo.Observacion x WHERE x.TipoContrato IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.TipoContrato c WHERE c.TipoContratoCodigo = x.TipoContrato)
UNION ALL SELECT N'Observacion.RegimenSalud' AS Columna, COUNT(*) AS ValoresSinCatalogo FROM dbo.Observacion x WHERE x.RegimenSalud IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.RegimenSalud c WHERE c.RegimenSaludCodigo = x.RegimenSalud)
UNION ALL SELECT N'Observacion.Discapacidad' AS Columna, COUNT(*) AS ValoresSinCatalogo FROM dbo.Observacion x WHERE x.Discapacidad IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.CondicionDiscapacidad c WHERE c.DiscapacidadCodigo = x.Discapacidad)
UNION ALL SELECT N'Observacion.CanalOrigen' AS Columna, COUNT(*) AS ValoresSinCatalogo FROM dbo.Observacion x WHERE x.CanalOrigen IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.CanalOrigen c WHERE c.CanalOrigenCodigo = x.CanalOrigen);
GO

/* ---------- 3. CHECK -> FOREIGN KEY ---------- */
IF OBJECT_ID(N'dbo.CK_Persona_TipoDoc', N'C') IS NOT NULL ALTER TABLE dbo.Persona DROP CONSTRAINT CK_Persona_TipoDoc;
IF OBJECT_ID(N'dbo.FK_Persona_TipoDocumento', N'F') IS NULL ALTER TABLE dbo.Persona WITH CHECK ADD CONSTRAINT FK_Persona_TipoDocumento FOREIGN KEY (TipoDocumento) REFERENCES dbo.TipoDocumento (TipoDocumentoCodigo);
IF OBJECT_ID(N'dbo.CK_Persona_Sexo', N'C') IS NOT NULL ALTER TABLE dbo.Persona DROP CONSTRAINT CK_Persona_Sexo;
IF OBJECT_ID(N'dbo.FK_Persona_Sexo', N'F') IS NULL ALTER TABLE dbo.Persona WITH CHECK ADD CONSTRAINT FK_Persona_Sexo FOREIGN KEY (Sexo) REFERENCES dbo.Sexo (SexoCodigo);
IF OBJECT_ID(N'dbo.CK_Obs_EstadoCivil', N'C') IS NOT NULL ALTER TABLE dbo.Observacion DROP CONSTRAINT CK_Obs_EstadoCivil;
IF OBJECT_ID(N'dbo.FK_Observacion_EstadoCivil', N'F') IS NULL ALTER TABLE dbo.Observacion WITH CHECK ADD CONSTRAINT FK_Observacion_EstadoCivil FOREIGN KEY (EstadoCivil) REFERENCES dbo.EstadoCivil (EstadoCivilCodigo);
IF OBJECT_ID(N'dbo.CK_Obs_Zona', N'C') IS NOT NULL ALTER TABLE dbo.Observacion DROP CONSTRAINT CK_Obs_Zona;
IF OBJECT_ID(N'dbo.FK_Observacion_Zona', N'F') IS NULL ALTER TABLE dbo.Observacion WITH CHECK ADD CONSTRAINT FK_Observacion_Zona FOREIGN KEY (Zona) REFERENCES dbo.Zona (ZonaCodigo);
IF OBJECT_ID(N'dbo.CK_Obs_Vivienda', N'C') IS NOT NULL ALTER TABLE dbo.Observacion DROP CONSTRAINT CK_Obs_Vivienda;
IF OBJECT_ID(N'dbo.FK_Observacion_TipoVivienda', N'F') IS NULL ALTER TABLE dbo.Observacion WITH CHECK ADD CONSTRAINT FK_Observacion_TipoVivienda FOREIGN KEY (TipoVivienda) REFERENCES dbo.TipoVivienda (TipoViviendaCodigo);
IF OBJECT_ID(N'dbo.CK_Obs_Estrato', N'C') IS NOT NULL ALTER TABLE dbo.Observacion DROP CONSTRAINT CK_Obs_Estrato;
IF OBJECT_ID(N'dbo.FK_Observacion_Estrato', N'F') IS NULL ALTER TABLE dbo.Observacion WITH CHECK ADD CONSTRAINT FK_Observacion_Estrato FOREIGN KEY (Estrato) REFERENCES dbo.Estrato (EstratoCodigo);
IF OBJECT_ID(N'dbo.CK_Obs_Contrato', N'C') IS NOT NULL ALTER TABLE dbo.Observacion DROP CONSTRAINT CK_Obs_Contrato;
IF OBJECT_ID(N'dbo.FK_Observacion_TipoContrato', N'F') IS NULL ALTER TABLE dbo.Observacion WITH CHECK ADD CONSTRAINT FK_Observacion_TipoContrato FOREIGN KEY (TipoContrato) REFERENCES dbo.TipoContrato (TipoContratoCodigo);
IF OBJECT_ID(N'dbo.CK_Obs_Salud', N'C') IS NOT NULL ALTER TABLE dbo.Observacion DROP CONSTRAINT CK_Obs_Salud;
IF OBJECT_ID(N'dbo.FK_Observacion_RegimenSalud', N'F') IS NULL ALTER TABLE dbo.Observacion WITH CHECK ADD CONSTRAINT FK_Observacion_RegimenSalud FOREIGN KEY (RegimenSalud) REFERENCES dbo.RegimenSalud (RegimenSaludCodigo);
IF OBJECT_ID(N'dbo.CK_Obs_Discapacidad', N'C') IS NOT NULL ALTER TABLE dbo.Observacion DROP CONSTRAINT CK_Obs_Discapacidad;
IF OBJECT_ID(N'dbo.FK_Observacion_Discapacidad', N'F') IS NULL ALTER TABLE dbo.Observacion WITH CHECK ADD CONSTRAINT FK_Observacion_Discapacidad FOREIGN KEY (Discapacidad) REFERENCES dbo.CondicionDiscapacidad (DiscapacidadCodigo);
IF OBJECT_ID(N'dbo.CK_Obs_Canal', N'C') IS NOT NULL ALTER TABLE dbo.Observacion DROP CONSTRAINT CK_Obs_Canal;
IF OBJECT_ID(N'dbo.FK_Observacion_CanalOrigen', N'F') IS NULL ALTER TABLE dbo.Observacion WITH CHECK ADD CONSTRAINT FK_Observacion_CanalOrigen FOREIGN KEY (CanalOrigen) REFERENCES dbo.CanalOrigen (CanalOrigenCodigo);
GO

/* ---------- 4. Evidencia ---------- */
-- Claves foráneas de Persona y Observacion (deben aparecer las 10 nuevas)
SELECT OBJECT_NAME(fk.parent_object_id) AS Tabla, fk.name AS ClaveForanea,
       OBJECT_NAME(fk.referenced_object_id) AS Catalogo
FROM sys.foreign_keys fk
WHERE OBJECT_NAME(fk.parent_object_id) IN (N'Persona', N'Observacion')
ORDER BY Tabla, Catalogo;

-- Filas de cada catálogo y cuántas observaciones/personas lo usan
SELECT N'TipoDocumento' AS Catalogo, (SELECT COUNT(*) FROM dbo.TipoDocumento) AS Filas, (SELECT COUNT(*) FROM dbo.Persona WHERE TipoDocumento IS NOT NULL) AS RegistrosQueLoUsan
UNION ALL SELECT N'Sexo' AS Catalogo, (SELECT COUNT(*) FROM dbo.Sexo) AS Filas, (SELECT COUNT(*) FROM dbo.Persona WHERE Sexo IS NOT NULL) AS RegistrosQueLoUsan
UNION ALL SELECT N'EstadoCivil' AS Catalogo, (SELECT COUNT(*) FROM dbo.EstadoCivil) AS Filas, (SELECT COUNT(*) FROM dbo.Observacion WHERE EstadoCivil IS NOT NULL) AS RegistrosQueLoUsan
UNION ALL SELECT N'Zona' AS Catalogo, (SELECT COUNT(*) FROM dbo.Zona) AS Filas, (SELECT COUNT(*) FROM dbo.Observacion WHERE Zona IS NOT NULL) AS RegistrosQueLoUsan
UNION ALL SELECT N'TipoVivienda' AS Catalogo, (SELECT COUNT(*) FROM dbo.TipoVivienda) AS Filas, (SELECT COUNT(*) FROM dbo.Observacion WHERE TipoVivienda IS NOT NULL) AS RegistrosQueLoUsan
UNION ALL SELECT N'Estrato' AS Catalogo, (SELECT COUNT(*) FROM dbo.Estrato) AS Filas, (SELECT COUNT(*) FROM dbo.Observacion WHERE Estrato IS NOT NULL) AS RegistrosQueLoUsan
UNION ALL SELECT N'TipoContrato' AS Catalogo, (SELECT COUNT(*) FROM dbo.TipoContrato) AS Filas, (SELECT COUNT(*) FROM dbo.Observacion WHERE TipoContrato IS NOT NULL) AS RegistrosQueLoUsan
UNION ALL SELECT N'RegimenSalud' AS Catalogo, (SELECT COUNT(*) FROM dbo.RegimenSalud) AS Filas, (SELECT COUNT(*) FROM dbo.Observacion WHERE RegimenSalud IS NOT NULL) AS RegistrosQueLoUsan
UNION ALL SELECT N'CondicionDiscapacidad' AS Catalogo, (SELECT COUNT(*) FROM dbo.CondicionDiscapacidad) AS Filas, (SELECT COUNT(*) FROM dbo.Observacion WHERE Discapacidad IS NOT NULL) AS RegistrosQueLoUsan
UNION ALL SELECT N'CanalOrigen' AS Catalogo, (SELECT COUNT(*) FROM dbo.CanalOrigen) AS Filas, (SELECT COUNT(*) FROM dbo.Observacion WHERE CanalOrigen IS NOT NULL) AS RegistrosQueLoUsan;

-- Ejemplo de consulta con el catálogo: observaciones por tipo de vivienda
SELECT tv.Nombre AS TipoVivienda, COUNT(*) AS Observaciones
FROM dbo.Observacion o JOIN dbo.TipoVivienda tv ON tv.TipoViviendaCodigo = o.TipoVivienda
GROUP BY tv.Nombre ORDER BY Observaciones DESC;
