/* =====================================================================
   10_verificar_staging.sql
   Verifica las tablas de staging donde queda el Excel tal como llegó:
     - stg.PersonasRaw     : cargada por el paquete SSIS A (DFT 0 Excel a staging)
     - cur.StagingPersonas : usada por el ejercicio con cursor
   Solo lectura.
   ===================================================================== */
USE PersonasETL;
GO

-- 1. Cantidad de filas: deben ser 1000 en ambas (las mismas del Excel)
SELECT N'stg.PersonasRaw'     AS TablaStaging, COUNT(*) AS Filas,
       MIN(TRY_CONVERT(INT, SourceRowId)) AS PrimeraFila, MAX(TRY_CONVERT(INT, SourceRowId)) AS UltimaFila
FROM stg.PersonasRaw
UNION ALL
SELECT N'cur.StagingPersonas', COUNT(*), MIN(TRY_CONVERT(INT, SourceRowId)), MAX(TRY_CONVERT(INT, SourceRowId))
FROM cur.StagingPersonas;

-- 2. Estructura: 37 columnas de texto (NVARCHAR), igual que el Excel
SELECT COLUMN_NAME AS Columna, DATA_TYPE AS Tipo, CHARACTER_MAXIMUM_LENGTH AS Longitud
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = N'stg' AND TABLE_NAME = N'PersonasRaw'
ORDER BY ORDINAL_POSITION;

-- 3. Muestra de los datos SIN limpiar (valores originales del Excel)
SELECT TOP (25) SourceRowId, DocumentType, DocumentNumber, FirstName, LastName, BirthDate,
       Phone, Email, MunicipalityCode, MunicipalityName, MonthlyIncome, MonthlyExpenses,
       Dependents, Disability, SurveyDate
FROM stg.PersonasRaw
ORDER BY TRY_CONVERT(INT, SourceRowId);

-- 4. Las dos copias del Excel son idénticas (debe dar 0 diferencias)
SELECT COUNT(*) AS FilasDistintasEntreStagings
FROM (
    SELECT SourceRowId, DocumentType, DocumentNumber, FirstName, LastName, MonthlyIncome, MonthlyExpenses, SurveyDate, UpdatedAt FROM stg.PersonasRaw
    EXCEPT
    SELECT SourceRowId, DocumentType, DocumentNumber, FirstName, LastName, MonthlyIncome, MonthlyExpenses, SurveyDate, UpdatedAt FROM cur.StagingPersonas
) d;

-- 5. Recorrido del dato: Excel -> staging -> modelo relacional
SELECT N'1. Staging (Excel sin cambios)' AS Etapa, COUNT(*) AS Filas FROM stg.PersonasRaw
UNION ALL SELECT N'2. Staging depurado (válidos)', COUNT(*) FROM stg.PersonaDepurada
UNION ALL SELECT N'3. Modelo: Persona', COUNT(*) FROM dbo.Persona
UNION ALL SELECT N'3. Modelo: Observacion', COUNT(*) FROM dbo.Observacion;
-- Esperado: 1000 | 469 | 469 | 469
