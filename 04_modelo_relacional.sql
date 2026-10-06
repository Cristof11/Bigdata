/* =====================================================================
   04_modelo_relacional.sql
   Parte 2 - Proceso A. Modelo relacional (MER) normalizado en 3FN,
   tablas de staging que usa el paquete SSIS y tablas de bitácora.

   Entidades del MER (esquema dbo):
     Departamento 1--N Municipio 1--N Observacion N--1 Persona
     NivelEducativo, SituacionLaboral, Ocupacion, Empleador 1--N Observacion
     TipoDocumento, Sexo 1--N Persona
     EstadoCivil, Zona, TipoVivienda, Estrato, TipoContrato, RegimenSalud,
     CondicionDiscapacidad, CanalOrigen 1--N Observacion
   Todas las categorías son tablas de catálogo referenciadas con clave
   foránea (3FN): la observación solo guarda el código.
   Persona     = clave natural (TipoDocumento, NumeroDocumento)
   Observacion = clave natural (PersonaId, FechaEncuesta)

   Nota: todas las columnas de texto son NVARCHAR para que coincidan con
   el tipo DT_WSTR que entrega el origen de Excel en SSIS (evita errores
   Unicode / no Unicode).
   ===================================================================== */
USE PersonasETL;
GO

/* Borrado en orden inverso de dependencias (permite re-ejecutar el script) */
DROP TABLE IF EXISTS dbo.Observacion;
DROP TABLE IF EXISTS dbo.Persona;
DROP TABLE IF EXISTS dbo.Empleador;
DROP TABLE IF EXISTS dbo.Ocupacion;
DROP TABLE IF EXISTS dbo.SituacionLaboral;
DROP TABLE IF EXISTS dbo.NivelEducativo;
DROP TABLE IF EXISTS dbo.Municipio;
DROP TABLE IF EXISTS dbo.Departamento;
DROP TABLE IF EXISTS dbo.TipoDocumento;
DROP TABLE IF EXISTS dbo.Sexo;
DROP TABLE IF EXISTS dbo.EstadoCivil;
DROP TABLE IF EXISTS dbo.Zona;
DROP TABLE IF EXISTS dbo.TipoVivienda;
DROP TABLE IF EXISTS dbo.Estrato;
DROP TABLE IF EXISTS dbo.TipoContrato;
DROP TABLE IF EXISTS dbo.RegimenSalud;
DROP TABLE IF EXISTS dbo.CondicionDiscapacidad;
DROP TABLE IF EXISTS dbo.CanalOrigen;
GO

/* ======================= CATÁLOGOS ======================= */
CREATE TABLE dbo.Departamento (
    DepartamentoCodigo NVARCHAR(3)  NOT NULL CONSTRAINT PK_Departamento PRIMARY KEY,
    Nombre             NVARCHAR(60) NOT NULL CONSTRAINT UQ_Departamento_Nombre UNIQUE
);

CREATE TABLE dbo.Municipio (
    MunicipioCodigo    NVARCHAR(4)  NOT NULL CONSTRAINT PK_Municipio PRIMARY KEY,
    Nombre             NVARCHAR(60) NOT NULL,
    DepartamentoCodigo NVARCHAR(3)  NOT NULL
        CONSTRAINT FK_Municipio_Departamento REFERENCES dbo.Departamento (DepartamentoCodigo)
);

CREATE TABLE dbo.NivelEducativo (
    NivelEducativoCodigo NVARCHAR(20) NOT NULL CONSTRAINT PK_NivelEducativo PRIMARY KEY,
    Nombre               NVARCHAR(40) NOT NULL,
    Orden                TINYINT      NOT NULL
);

CREATE TABLE dbo.SituacionLaboral (
    SituacionLaboralCodigo NVARCHAR(20) NOT NULL CONSTRAINT PK_SituacionLaboral PRIMARY KEY,
    Nombre                 NVARCHAR(40) NOT NULL
);

CREATE TABLE dbo.Ocupacion (
    OcupacionCodigo NVARCHAR(3)  NOT NULL CONSTRAINT PK_Ocupacion PRIMARY KEY,
    Nombre          NVARCHAR(60) NOT NULL
);

CREATE TABLE dbo.Empleador (
    EmpleadorId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Empleador PRIMARY KEY,
    Nombre      NVARCHAR(100) NOT NULL CONSTRAINT UQ_Empleador_Nombre UNIQUE
);

/* Catálogos de categorías (antes eran restricciones CHECK) */
CREATE TABLE dbo.TipoDocumento        (TipoDocumentoCodigo   NVARCHAR(2)  NOT NULL CONSTRAINT PK_TipoDocumento PRIMARY KEY, Nombre NVARCHAR(40) NOT NULL);
CREATE TABLE dbo.Sexo                 (SexoCodigo            NVARCHAR(2)  NOT NULL CONSTRAINT PK_Sexo PRIMARY KEY,          Nombre NVARCHAR(30) NOT NULL);
CREATE TABLE dbo.EstadoCivil          (EstadoCivilCodigo     NVARCHAR(15) NOT NULL CONSTRAINT PK_EstadoCivil PRIMARY KEY,   Nombre NVARCHAR(30) NOT NULL);
CREATE TABLE dbo.Zona                 (ZonaCodigo            NVARCHAR(10) NOT NULL CONSTRAINT PK_Zona PRIMARY KEY,          Nombre NVARCHAR(30) NOT NULL);
CREATE TABLE dbo.TipoVivienda         (TipoViviendaCodigo    NVARCHAR(15) NOT NULL CONSTRAINT PK_TipoVivienda PRIMARY KEY,  Nombre NVARCHAR(30) NOT NULL);
CREATE TABLE dbo.Estrato              (EstratoCodigo         INT          NOT NULL CONSTRAINT PK_Estrato PRIMARY KEY,       Nombre NVARCHAR(30) NOT NULL);
CREATE TABLE dbo.TipoContrato         (TipoContratoCodigo    NVARCHAR(15) NOT NULL CONSTRAINT PK_TipoContrato PRIMARY KEY,  Nombre NVARCHAR(40) NOT NULL);
CREATE TABLE dbo.RegimenSalud         (RegimenSaludCodigo    NVARCHAR(15) NOT NULL CONSTRAINT PK_RegimenSalud PRIMARY KEY,  Nombre NVARCHAR(30) NOT NULL);
CREATE TABLE dbo.CondicionDiscapacidad(DiscapacidadCodigo    NVARCHAR(2)  NOT NULL CONSTRAINT PK_CondicionDiscapacidad PRIMARY KEY, Nombre NVARCHAR(30) NOT NULL);
CREATE TABLE dbo.CanalOrigen          (CanalOrigenCodigo     NVARCHAR(12) NOT NULL CONSTRAINT PK_CanalOrigen PRIMARY KEY,   Nombre NVARCHAR(30) NOT NULL);

/* ======================= ENTIDADES PRINCIPALES ======================= */
CREATE TABLE dbo.Persona (
    PersonaId        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Persona PRIMARY KEY,
    TipoDocumento    NVARCHAR(2)   NOT NULL CONSTRAINT FK_Persona_TipoDocumento REFERENCES dbo.TipoDocumento (TipoDocumentoCodigo),
    NumeroDocumento  NVARCHAR(10)  NOT NULL,
    PrimerNombre     NVARCHAR(50)  NOT NULL,
    SegundoNombre    NVARCHAR(50)  NULL,
    PrimerApellido   NVARCHAR(50)  NOT NULL,
    SegundoApellido  NVARCHAR(50)  NULL,
    FechaNacimiento  DATE          NOT NULL,
    Sexo             NVARCHAR(2)   NULL CONSTRAINT FK_Persona_Sexo REFERENCES dbo.Sexo (SexoCodigo),
    Email            NVARCHAR(120) NULL,
    Telefono         NVARCHAR(10)  NULL,
    FechaCarga       DATETIME      NOT NULL CONSTRAINT DF_Persona_FechaCarga DEFAULT GETDATE(),
    CONSTRAINT UQ_Persona_Documento UNIQUE (TipoDocumento, NumeroDocumento)   -- clave de persona
);

CREATE TABLE dbo.Observacion (
    ObservacionId            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Observacion PRIMARY KEY,
    PersonaId                INT           NOT NULL CONSTRAINT FK_Observacion_Persona REFERENCES dbo.Persona (PersonaId),
    FechaEncuesta            DATE          NOT NULL,
    SourceRowId              INT           NOT NULL CONSTRAINT UQ_Observacion_SourceRowId UNIQUE,
    EdadReportada            INT           NOT NULL,
    EstadoCivil              NVARCHAR(15)  NOT NULL CONSTRAINT FK_Observacion_EstadoCivil REFERENCES dbo.EstadoCivil (EstadoCivilCodigo),
    MunicipioCodigo          NVARCHAR(4)   NOT NULL CONSTRAINT FK_Observacion_Municipio REFERENCES dbo.Municipio (MunicipioCodigo),
    Zona                     NVARCHAR(10)  NULL CONSTRAINT FK_Observacion_Zona REFERENCES dbo.Zona (ZonaCodigo),
    Direccion                NVARCHAR(120) NULL,
    TipoVivienda             NVARCHAR(15)  NOT NULL CONSTRAINT FK_Observacion_TipoVivienda REFERENCES dbo.TipoVivienda (TipoViviendaCodigo),
    Estrato                  INT           NULL CONSTRAINT FK_Observacion_Estrato REFERENCES dbo.Estrato (EstratoCodigo),
    NivelEducativoCodigo     NVARCHAR(20)  NOT NULL CONSTRAINT FK_Observacion_NivelEducativo REFERENCES dbo.NivelEducativo (NivelEducativoCodigo),
    SituacionLaboralCodigo   NVARCHAR(20)  NOT NULL CONSTRAINT FK_Observacion_SituacionLaboral REFERENCES dbo.SituacionLaboral (SituacionLaboralCodigo),
    OcupacionCodigo          NVARCHAR(3)   NULL CONSTRAINT FK_Observacion_Ocupacion REFERENCES dbo.Ocupacion (OcupacionCodigo),
    EmpleadorId              INT           NULL CONSTRAINT FK_Observacion_Empleador REFERENCES dbo.Empleador (EmpleadorId),
    TipoContrato             NVARCHAR(15)  NOT NULL CONSTRAINT FK_Observacion_TipoContrato REFERENCES dbo.TipoContrato (TipoContratoCodigo),
    FechaInicioEmpleo        DATE          NULL,
    IngresoMensual           DECIMAL(18,2) NOT NULL CONSTRAINT CK_Obs_Ingreso CHECK (IngresoMensual >= 0),
    GastoMensual             DECIMAL(18,2) NOT NULL CONSTRAINT CK_Obs_Gasto   CHECK (GastoMensual   >= 0),
    PersonasACargo           INT           NOT NULL CONSTRAINT CK_Obs_Cargo   CHECK (PersonasACargo >= 0),
    TamanoHogar              INT           NOT NULL CONSTRAINT CK_Obs_Hogar   CHECK (TamanoHogar    >= 1),
    RegimenSalud             NVARCHAR(15)  NULL CONSTRAINT FK_Observacion_RegimenSalud REFERENCES dbo.RegimenSalud (RegimenSaludCodigo),
    Discapacidad             NVARCHAR(2)   NOT NULL CONSTRAINT FK_Observacion_Discapacidad REFERENCES dbo.CondicionDiscapacidad (DiscapacidadCodigo),
    CanalOrigen              NVARCHAR(12)  NOT NULL CONSTRAINT FK_Observacion_CanalOrigen REFERENCES dbo.CanalOrigen (CanalOrigenCodigo),
    FechaActualizacionOrigen DATETIME      NOT NULL,
    FechaCarga               DATETIME      NOT NULL CONSTRAINT DF_Observacion_FechaCarga DEFAULT GETDATE(),
    CONSTRAINT UQ_Observacion_PersonaFecha UNIQUE (PersonaId, FechaEncuesta)   -- clave de observación
);
GO

/* ======================= DATOS DE CATÁLOGO =======================
   Construidos a partir del diagnóstico del Excel (combinación código-nombre
   predominante). Los códigos son internos del dataset (no DIVIPOLA).       */
INSERT INTO dbo.TipoDocumento VALUES (N'CC', N'Cédula de ciudadanía'), (N'CE', N'Cédula de extranjería'), (N'PA', N'Pasaporte');
INSERT INTO dbo.Sexo VALUES (N'M', N'Masculino'), (N'F', N'Femenino'), (N'ND', N'No definido');
INSERT INTO dbo.EstadoCivil VALUES (N'SOLTERO', N'Soltero(a)'), (N'CASADO', N'Casado(a)'), (N'UNION_LIBRE', N'Unión libre'), (N'DIVORCIADO', N'Divorciado(a)'), (N'VIUDO', N'Viudo(a)');
INSERT INTO dbo.Zona VALUES (N'URBANA', N'Urbana'), (N'RURAL', N'Rural');
INSERT INTO dbo.TipoVivienda VALUES (N'PROPIA', N'Propia'), (N'ARRENDADA', N'Arrendada'), (N'FAMILIAR', N'Familiar'), (N'OTRA', N'Otra');
INSERT INTO dbo.Estrato VALUES (1, N'Bajo-bajo'), (2, N'Bajo'), (3, N'Medio-bajo'), (4, N'Medio'), (5, N'Medio-alto'), (6, N'Alto');
INSERT INTO dbo.TipoContrato VALUES (N'FIJO', N'Término fijo'), (N'INDEFINIDO', N'Término indefinido'), (N'SERVICIOS', N'Prestación de servicios'), (N'NO_APLICA', N'No aplica');
INSERT INTO dbo.RegimenSalud VALUES (N'CONTRIBUTIVO', N'Contributivo'), (N'SUBSIDIADO', N'Subsidiado'), (N'ESPECIAL', N'Especial'), (N'NO_AFILIADO', N'No afiliado');
INSERT INTO dbo.CondicionDiscapacidad VALUES (N'SI', N'Sí'), (N'NO', N'No'), (N'ND', N'No definido');
INSERT INTO dbo.CanalOrigen VALUES (N'WEB', N'Web'), (N'TELEFONO', N'Teléfono'), (N'PRESENCIAL', N'Presencial'), (N'FAX', N'Fax');

INSERT INTO dbo.Departamento (DepartamentoCodigo, Nombre) VALUES
 (N'D01', N'CUNDINAMARCA'), (N'D02', N'BOGOTÁ D.C.'), (N'D03', N'ANTIOQUIA'),
 (N'D04', N'BOYACÁ'), (N'D05', N'VALLE DEL CAUCA');

INSERT INTO dbo.Municipio (MunicipioCodigo, Nombre, DepartamentoCodigo) VALUES
 (N'M001', N'CHÍA', N'D01'), (N'M002', N'CAJICÁ', N'D01'), (N'M003', N'ZIPAQUIRÁ', N'D01'),
 (N'M004', N'SOACHA', N'D01'), (N'M005', N'BOGOTÁ D.C.', N'D02'), (N'M006', N'MEDELLÍN', N'D03'),
 (N'M007', N'ENVIGADO', N'D03'), (N'M008', N'TUNJA', N'D04'), (N'M009', N'DUITAMA', N'D04'),
 (N'M010', N'CALI', N'D05');
 -- M999 'MUNICIPIO DESCONOCIDO' NO se incluye: no es una ubicación real; esos registros van a revisión.

INSERT INTO dbo.NivelEducativo (NivelEducativoCodigo, Nombre, Orden) VALUES
 (N'NINGUNO', N'Ninguno', 0), (N'PRIMARIA', N'Primaria', 1), (N'SECUNDARIA', N'Secundaria', 2),
 (N'TECNICO', N'Técnico', 3), (N'TECNOLOGO', N'Tecnólogo', 4), (N'UNIVERSITARIO', N'Universitario', 5),
 (N'POSGRADO', N'Posgrado', 6);

INSERT INTO dbo.SituacionLaboral (SituacionLaboralCodigo, Nombre) VALUES
 (N'EMPLEADO', N'Empleado'), (N'INDEPENDIENTE', N'Independiente'), (N'DESEMPLEADO', N'Desempleado'),
 (N'ESTUDIANTE', N'Estudiante'), (N'PENSIONADO', N'Pensionado');

INSERT INTO dbo.Ocupacion (OcupacionCodigo, Nombre) VALUES
 (N'O01', N'DOCENTE'), (N'O02', N'DESARROLLADOR'), (N'O03', N'COMERCIANTE'),
 (N'O04', N'AUXILIAR ADMINISTRATIVO'), (N'O05', N'CONDUCTOR'), (N'O06', N'TÉCNICO DE SOPORTE'),
 (N'O07', N'CONTADOR'), (N'O08', N'OPERARIO'), (N'O99', N'SIN CLASIFICAR');
GO

/* ======================= STAGING DEL PAQUETE SSIS ======================= */
-- Copia fiel del Excel (evidencia "antes"); se vacía al iniciar cada ejecución.
DROP TABLE IF EXISTS stg.PersonasRaw;
SELECT TOP (0) * INTO stg.PersonasRaw FROM cur.StagingPersonas;   -- mismas 37 columnas en NVARCHAR
ALTER TABLE stg.PersonasRaw DROP COLUMN FechaCargaStaging;
GO

-- Registros ya validados y sin duplicados, tipados (salida del primer flujo de datos)
DROP TABLE IF EXISTS stg.PersonaDepurada;
CREATE TABLE stg.PersonaDepurada (
    SourceRowId              INT           NOT NULL,
    TipoDocumento            NVARCHAR(2)   NOT NULL,
    NumeroDocumento          NVARCHAR(10)  NOT NULL,
    PrimerNombre             NVARCHAR(50)  NOT NULL,
    SegundoNombre            NVARCHAR(50)  NULL,
    PrimerApellido           NVARCHAR(50)  NOT NULL,
    SegundoApellido          NVARCHAR(50)  NULL,
    FechaNacimiento          DATE          NOT NULL,
    Sexo                     NVARCHAR(2)   NULL,
    Email                    NVARCHAR(120) NULL,
    Telefono                 NVARCHAR(10)  NULL,
    FechaEncuesta            DATE          NOT NULL,
    EdadReportada            INT           NOT NULL,
    EstadoCivil              NVARCHAR(15)  NOT NULL,
    MunicipioCodigo          NVARCHAR(4)   NOT NULL,
    Zona                     NVARCHAR(10)  NULL,
    Direccion                NVARCHAR(120) NULL,
    TipoVivienda             NVARCHAR(15)  NOT NULL,
    Estrato                  INT           NULL,
    NivelEducativoCodigo     NVARCHAR(20)  NOT NULL,
    SituacionLaboralCodigo   NVARCHAR(20)  NOT NULL,
    OcupacionCodigo          NVARCHAR(3)   NULL,
    Empleador                NVARCHAR(100) NULL,
    TipoContrato             NVARCHAR(15)  NOT NULL,
    FechaInicioEmpleo        DATE          NULL,
    IngresoMensual           DECIMAL(18,2) NOT NULL,
    GastoMensual             DECIMAL(18,2) NOT NULL,
    PersonasACargo           INT           NOT NULL,
    TamanoHogar              INT           NOT NULL,
    RegimenSalud             NVARCHAR(15)  NULL,
    Discapacidad             NVARCHAR(2)   NOT NULL,
    CanalOrigen              NVARCHAR(12)  NOT NULL,
    FechaActualizacionOrigen DATETIME      NOT NULL
);
GO

/* ======================= BITÁCORAS (esquema etl) ======================= */
DROP TABLE IF EXISTS etl.LogCambio;
CREATE TABLE etl.LogCambio (
    LogCambioId  INT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId  INT            NOT NULL,
    Cambios      NVARCHAR(1000) NOT NULL,        -- lista de correcciones aplicadas a la fila
    FechaRegistro DATETIME      NOT NULL DEFAULT GETDATE()
);

DROP TABLE IF EXISTS etl.Rechazo;
CREATE TABLE etl.Rechazo (
    RechazoId       INT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId     INT            NOT NULL,
    TipoDocumento   NVARCHAR(50)   NULL,
    NumeroDocumento NVARCHAR(50)   NULL,
    PrimerNombre    NVARCHAR(50)   NULL,
    SurveyDateOriginal NVARCHAR(50) NULL,
    Motivo          NVARCHAR(500)  NOT NULL,
    FechaRegistro   DATETIME       NOT NULL DEFAULT GETDATE()
);

DROP TABLE IF EXISTS etl.Duplicado;
CREATE TABLE etl.Duplicado (
    DuplicadoId          INT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId          INT           NOT NULL,     -- registro descartado
    SourceRowIdConservado INT          NOT NULL,     -- registro que se conserva
    TipoDocumento        NVARCHAR(2)   NOT NULL,
    NumeroDocumento      NVARCHAR(10)  NOT NULL,
    FechaEncuesta        DATE          NOT NULL,
    FechaActualizacion   DATETIME      NULL,
    IngresoMensual       DECIMAL(18,2) NULL,
    Versiones            INT           NOT NULL,
    Motivo               NVARCHAR(300) NOT NULL,
    FechaRegistro        DATETIME      NOT NULL DEFAULT GETDATE()
);

DROP TABLE IF EXISTS etl.Revision;
CREATE TABLE etl.Revision (
    RevisionId       INT IDENTITY(1,1) PRIMARY KEY,
    SourceRowId      INT            NOT NULL,
    TipoDocumento    NVARCHAR(2)    NOT NULL,
    NumeroDocumento  NVARCHAR(10)   NOT NULL,
    FechaEncuesta    DATE           NOT NULL,
    BirthDateOriginal NVARCHAR(50)  NULL,
    MunicipioCodigo  NVARCHAR(4)    NULL,
    IngresoOriginal  NVARCHAR(50)   NULL,
    GastoOriginal    NVARCHAR(50)   NULL,
    Motivo           NVARCHAR(1000) NOT NULL,
    FechaRegistro    DATETIME       NOT NULL DEFAULT GETDATE()
);

-- Historial de ejecuciones (NO se vacía): demuestra que la 2.a corrida inserta 0 filas
DROP TABLE IF EXISTS etl.EjecucionPaquete;
CREATE TABLE etl.EjecucionPaquete (
    EjecucionId     INT IDENTITY(1,1) PRIMARY KEY,
    Paquete         NVARCHAR(50) NOT NULL,
    FechaEjecucion  DATETIME     NOT NULL DEFAULT GETDATE(),
    FilasLeidas     INT NULL,
    Rechazadas      INT NULL,
    Duplicadas      INT NULL,
    EnRevision      INT NULL,
    Validas         INT NULL,
    InsertadasTabla1 INT NULL,   -- A: personas nuevas      | B: dimensiones nuevas (suma)
    InsertadasTabla2 INT NULL    -- A: observaciones nuevas | B: hechos nuevos
);
GO
PRINT N'Modelo relacional, staging y bitácoras creados.';
