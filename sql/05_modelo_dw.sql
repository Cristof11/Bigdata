/* =====================================================================
   05_modelo_dw.sql
   Parte 2 - Proceso B. Bodega de datos PersonasDW en esquema ESTRELLA.

   Granularidad de FactObservacion: una fila por persona y fecha de encuesta.
   Dimensiones: DimTiempo, DimUbicacion, DimEducacion, DimSituacionLaboral,
                DimPersona (necesaria para contar personas distintas).
   Medidas: IngresoMensual, GastoMensual, BalanceMensual, CantidadObservaciones.
   Claves sustitutas: IDENTITY en cada dimensión (DimTiempo usa AAAAMMDD).
   ===================================================================== */
USE PersonasDW;
GO

DROP TABLE IF EXISTS dbo.FactObservacion;
DROP TABLE IF EXISTS dbo.DimPersona;
DROP TABLE IF EXISTS dbo.DimTiempo;
DROP TABLE IF EXISTS dbo.DimUbicacion;
DROP TABLE IF EXISTS dbo.DimEducacion;
DROP TABLE IF EXISTS dbo.DimSituacionLaboral;
DROP TABLE IF EXISTS dbo.EjecucionCarga;
GO

CREATE TABLE dbo.DimTiempo (
    TiempoKey  INT          NOT NULL CONSTRAINT PK_DimTiempo PRIMARY KEY,   -- AAAAMMDD
    Fecha      DATE         NOT NULL CONSTRAINT UQ_DimTiempo_Fecha UNIQUE,
    Anio       INT          NOT NULL,
    Trimestre  INT          NOT NULL,
    Mes        INT          NOT NULL,
    NombreMes  NVARCHAR(15) NOT NULL,
    Dia        INT          NOT NULL
);

CREATE TABLE dbo.DimUbicacion (
    UbicacionKey       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimUbicacion PRIMARY KEY,
    MunicipioCodigo    NVARCHAR(4)  NOT NULL CONSTRAINT UQ_DimUbicacion_Codigo UNIQUE,  -- clave natural
    MunicipioNombre    NVARCHAR(60) NOT NULL,
    DepartamentoCodigo NVARCHAR(3)  NOT NULL,
    DepartamentoNombre NVARCHAR(60) NOT NULL
);

CREATE TABLE dbo.DimEducacion (
    EducacionKey         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimEducacion PRIMARY KEY,
    NivelEducativoCodigo NVARCHAR(20) NOT NULL CONSTRAINT UQ_DimEducacion_Codigo UNIQUE,
    NivelEducativoNombre NVARCHAR(40) NOT NULL,
    Orden                INT          NOT NULL
);

CREATE TABLE dbo.DimSituacionLaboral (
    SituacionLaboralKey    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimSituacionLaboral PRIMARY KEY,
    SituacionLaboralCodigo NVARCHAR(20) NOT NULL CONSTRAINT UQ_DimSituacion_Codigo UNIQUE,
    SituacionLaboralNombre NVARCHAR(40) NOT NULL
);

CREATE TABLE dbo.DimPersona (
    PersonaKey      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimPersona PRIMARY KEY,
    PersonaId       INT           NOT NULL CONSTRAINT UQ_DimPersona_PersonaId UNIQUE,  -- clave del modelo relacional
    TipoDocumento   NVARCHAR(2)   NOT NULL,
    NumeroDocumento NVARCHAR(10)  NOT NULL,
    NombreCompleto  NVARCHAR(220) NOT NULL,
    Sexo            NVARCHAR(2)   NULL,
    FechaNacimiento DATE          NOT NULL
);

CREATE TABLE dbo.FactObservacion (
    PersonaKey            INT NOT NULL CONSTRAINT FK_Fact_Persona   REFERENCES dbo.DimPersona (PersonaKey),
    TiempoKey             INT NOT NULL CONSTRAINT FK_Fact_Tiempo    REFERENCES dbo.DimTiempo (TiempoKey),
    UbicacionKey          INT NOT NULL CONSTRAINT FK_Fact_Ubicacion REFERENCES dbo.DimUbicacion (UbicacionKey),
    EducacionKey          INT NOT NULL CONSTRAINT FK_Fact_Educacion REFERENCES dbo.DimEducacion (EducacionKey),
    SituacionLaboralKey   INT NOT NULL CONSTRAINT FK_Fact_Situacion REFERENCES dbo.DimSituacionLaboral (SituacionLaboralKey),
    ObservacionId         INT NOT NULL CONSTRAINT UQ_Fact_ObservacionId UNIQUE,   -- dimensión degenerada (trazabilidad)
    IngresoMensual        DECIMAL(18,2) NOT NULL,
    GastoMensual          DECIMAL(18,2) NOT NULL,
    BalanceMensual        DECIMAL(18,2) NOT NULL,
    CantidadObservaciones INT NOT NULL,
    CONSTRAINT PK_FactObservacion PRIMARY KEY (PersonaKey, TiempoKey)   -- granularidad
);

-- Historial de ejecuciones del paquete B
CREATE TABLE dbo.EjecucionCarga (
    EjecucionId        INT IDENTITY(1,1) PRIMARY KEY,
    FechaEjecucion     DATETIME NOT NULL DEFAULT GETDATE(),
    DimTiempoNuevas    INT NOT NULL,
    DimUbicacionNuevas INT NOT NULL,
    DimEducacionNuevas INT NOT NULL,
    DimSituacionNuevas INT NOT NULL,
    DimPersonaNuevas   INT NOT NULL,
    HechosLeidos       INT NOT NULL,
    HechosNuevos       INT NOT NULL
);
GO
PRINT N'Bodega de datos (estrella) creada.';
