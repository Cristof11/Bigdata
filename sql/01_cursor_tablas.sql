/* =====================================================================
   01_cursor_tablas.sql
   Parte 1 - Ejercicio de ETL con cursores.
   Crea: tabla de staging (valores originales, todo como texto),
         funciones de apoyo para limpieza de texto,
         tablas de destino (válidos / rechazados) y resumen de ejecución.
   ===================================================================== */
USE PersonasETL;
GO

/* ---------- 1. Staging: copia fiel del Excel (todo NVARCHAR, sin limpiar) ---------- */
DROP TABLE IF EXISTS cur.StagingPersonas;
CREATE TABLE cur.StagingPersonas (
    SourceRowId          NVARCHAR(20)  NULL,
    DocumentType         NVARCHAR(50)  NULL,
    DocumentNumber       NVARCHAR(50)  NULL,
    FirstName            NVARCHAR(100) NULL,
    MiddleName           NVARCHAR(100) NULL,
    LastName             NVARCHAR(100) NULL,
    SecondLastName       NVARCHAR(100) NULL,
    BirthDate            NVARCHAR(50)  NULL,
    ReportedAge          NVARCHAR(50)  NULL,
    Sex                  NVARCHAR(50)  NULL,
    MaritalStatus        NVARCHAR(50)  NULL,
    Email                NVARCHAR(200) NULL,
    Phone                NVARCHAR(50)  NULL,
    DepartmentCode       NVARCHAR(50)  NULL,
    DepartmentName       NVARCHAR(100) NULL,
    MunicipalityCode     NVARCHAR(50)  NULL,
    MunicipalityName     NVARCHAR(100) NULL,
    Zone                 NVARCHAR(50)  NULL,
    Address              NVARCHAR(200) NULL,
    HousingType          NVARCHAR(50)  NULL,
    SocioeconomicStratum NVARCHAR(50)  NULL,
    EducationLevel       NVARCHAR(50)  NULL,
    EmploymentStatus     NVARCHAR(50)  NULL,
    OccupationCode       NVARCHAR(50)  NULL,
    OccupationName       NVARCHAR(100) NULL,
    EmployerName         NVARCHAR(200) NULL,
    ContractType         NVARCHAR(50)  NULL,
    EmploymentStartDate  NVARCHAR(50)  NULL,
    MonthlyIncome        NVARCHAR(50)  NULL,
    MonthlyExpenses      NVARCHAR(50)  NULL,
    Dependents           NVARCHAR(50)  NULL,
    HouseholdSize        NVARCHAR(50)  NULL,
    HealthRegime         NVARCHAR(50)  NULL,
    Disability           NVARCHAR(50)  NULL,
    SurveyDate           NVARCHAR(50)  NULL,
    UpdatedAt            NVARCHAR(50)  NULL,
    SourceChannel        NVARCHAR(50)  NULL,
    FechaCargaStaging    DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME()
);
GO

/* ---------- 2. Funciones de apoyo ---------- */
-- Quita espacios al inicio/fin, colapsa espacios internos repetidos y convierte '' en NULL.
CREATE OR ALTER FUNCTION cur.fn_LimpiarTexto (@texto NVARCHAR(400))
RETURNS NVARCHAR(400)
AS
BEGIN
    DECLARE @t NVARCHAR(400) = REPLACE(REPLACE(@texto, NCHAR(160), N' '), NCHAR(9), N' ');
    SET @t = TRIM(@t);
    WHILE CHARINDEX(N'  ', @t) > 0
        SET @t = REPLACE(@t, N'  ', N' ');
    RETURN NULLIF(@t, N'');
END;
GO

-- Escritura tipo "Nombre Propio": primera letra de cada palabra en mayúscula.
CREATE OR ALTER FUNCTION cur.fn_NombrePropio (@texto NVARCHAR(400))
RETURNS NVARCHAR(400)
AS
BEGIN
    DECLARE @t NVARCHAR(400) = LOWER(cur.fn_LimpiarTexto(@texto));
    IF @t IS NULL RETURN NULL;
    DECLARE @i INT = 1, @n INT = LEN(@t), @resultado NVARCHAR(400) = N'', @anterior NCHAR(1) = N' ';
    WHILE @i <= @n
    BEGIN
        SET @resultado += CASE WHEN @anterior = N' ' THEN UPPER(SUBSTRING(@t, @i, 1))
                               ELSE SUBSTRING(@t, @i, 1) END;
        SET @anterior = SUBSTRING(@t, @i, 1);
        SET @i += 1;
    END;
    RETURN @resultado;
END;
GO

/* ---------- 3. Tablas de destino ---------- */
DROP TABLE IF EXISTS cur.PersonasValidas;
CREATE TABLE cur.PersonasValidas (
    SourceRowId          INT           NOT NULL PRIMARY KEY,
    TipoDocumento        NVARCHAR(5)   NOT NULL,
    NumeroDocumento      NVARCHAR(20)  NOT NULL,
    PrimerNombre         NVARCHAR(60)  NOT NULL,
    SegundoNombre        NVARCHAR(60)  NULL,
    PrimerApellido       NVARCHAR(60)  NOT NULL,
    SegundoApellido      NVARCHAR(60)  NULL,
    IngresoOriginal      NVARCHAR(50)  NULL,   -- evidencia "antes"
    GastoOriginal        NVARCHAR(50)  NULL,
    IngresoMensual       DECIMAL(18,2) NOT NULL,
    GastoMensual         DECIMAL(18,2) NOT NULL,
    BalanceMensual       DECIMAL(18,2) NOT NULL,   -- puede ser negativo (válido)
    FechaProceso         DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME()
);

DROP TABLE IF EXISTS cur.PersonasRechazadas;
CREATE TABLE cur.PersonasRechazadas (
    SourceRowId          INT           NOT NULL PRIMARY KEY,
    Motivo               NVARCHAR(500) NOT NULL,
    DocumentoOriginal    NVARCHAR(50)  NULL,
    PrimerNombreOriginal NVARCHAR(100) NULL,
    PrimerApellidoOriginal NVARCHAR(100) NULL,
    IngresoOriginal      NVARCHAR(50)  NULL,
    GastoOriginal        NVARCHAR(50)  NULL,
    FechaProceso         DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME()
);

DROP TABLE IF EXISTS cur.ResumenEjecucion;
CREATE TABLE cur.ResumenEjecucion (
    EjecucionId   INT IDENTITY(1,1) PRIMARY KEY,
    FechaEjecucion DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    Procesados    INT NOT NULL,
    Aceptados     INT NOT NULL,
    Rechazados    INT NOT NULL
);
GO
PRINT N'Tablas del ejercicio con cursor creadas.';
