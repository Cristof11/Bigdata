/* =====================================================================
   07_diagnostico_inicial.sql
   Diagnóstico de calidad de los 1.000 registros ANTES de transformar.
   Se ejecuta sobre la copia fiel del Excel (cur.StagingPersonas, cargada
   con 02_cursor_cargar_staging.sql). Solo lectura: no modifica nada.
   ===================================================================== */
USE PersonasETL;
GO

/* 1. Valores faltantes (NULL o vacío) por columna relevante */
SELECT Columna, Faltantes FROM (VALUES
 (N'DocumentNumber (vacío o SIN-DATO)', (SELECT COUNT(*) FROM cur.StagingPersonas WHERE NULLIF(TRIM(DocumentNumber),N'') IS NULL OR DocumentNumber = N'SIN-DATO')),
 (N'FirstName',       (SELECT COUNT(*) FROM cur.StagingPersonas WHERE NULLIF(TRIM(FirstName),N'') IS NULL)),
 (N'MiddleName',      (SELECT COUNT(*) FROM cur.StagingPersonas WHERE NULLIF(TRIM(MiddleName),N'') IS NULL)),
 (N'LastName',        (SELECT COUNT(*) FROM cur.StagingPersonas WHERE NULLIF(TRIM(LastName),N'') IS NULL)),
 (N'SecondLastName',  (SELECT COUNT(*) FROM cur.StagingPersonas WHERE NULLIF(TRIM(SecondLastName),N'') IS NULL)),
 (N'MonthlyExpenses', (SELECT COUNT(*) FROM cur.StagingPersonas WHERE NULLIF(TRIM(MonthlyExpenses),N'') IS NULL)),
 (N'OccupationCode',  (SELECT COUNT(*) FROM cur.StagingPersonas WHERE NULLIF(TRIM(OccupationCode),N'') IS NULL)),
 (N'EmployerName',    (SELECT COUNT(*) FROM cur.StagingPersonas WHERE NULLIF(TRIM(EmployerName),N'') IS NULL)),
 (N'EmploymentStartDate', (SELECT COUNT(*) FROM cur.StagingPersonas WHERE NULLIF(TRIM(EmploymentStartDate),N'') IS NULL)),
 (N'HealthRegime (NULL/sin dato/N/A)', (SELECT COUNT(*) FROM cur.StagingPersonas WHERE UPPER(HealthRegime) IN (N'NULL',N'SIN DATO',N'N/A')))
) AS d(Columna, Faltantes)
ORDER BY Faltantes DESC;

/* 2. Formatos inconsistentes */
SELECT N'DocumentType en minúscula' AS Hallazgo, COUNT(*) AS Registros FROM cur.StagingPersonas WHERE DocumentType COLLATE Latin1_General_CS_AS <> UPPER(DocumentType)
UNION ALL SELECT N'FirstName en minúscula', COUNT(*) FROM cur.StagingPersonas WHERE FirstName COLLATE Latin1_General_CS_AS = LOWER(FirstName) AND FirstName <> N''
UNION ALL SELECT N'LastName en MAYÚSCULA', COUNT(*) FROM cur.StagingPersonas WHERE LastName COLLATE Latin1_General_CS_AS = UPPER(LastName)
UNION ALL SELECT N'MaritalStatus en minúscula', COUNT(*) FROM cur.StagingPersonas WHERE MaritalStatus COLLATE Latin1_General_CS_AS <> UPPER(MaritalStatus)
UNION ALL SELECT N'EducationLevel en minúscula', COUNT(*) FROM cur.StagingPersonas WHERE EducationLevel COLLATE Latin1_General_CS_AS <> UPPER(EducationLevel)
UNION ALL SELECT N'MunicipalityName en minúscula/sin tilde', COUNT(*) FROM cur.StagingPersonas WHERE MunicipalityName COLLATE Latin1_General_CS_AS <> UPPER(MunicipalityName)
UNION ALL SELECT N'BirthDate con formato dd/mm/aaaa', COUNT(*) FROM cur.StagingPersonas WHERE BirthDate LIKE N'__/__/____'
UNION ALL SELECT N'Phone con guion', COUNT(*) FROM cur.StagingPersonas WHERE Phone LIKE N'%-%'
UNION ALL SELECT N'MonthlyIncome con $ y separadores', COUNT(*) FROM cur.StagingPersonas WHERE MonthlyIncome LIKE N'%$%'
UNION ALL SELECT N'MonthlyExpenses con coma decimal', COUNT(*) FROM cur.StagingPersonas WHERE MonthlyExpenses LIKE N'%,%'
UNION ALL SELECT N'Disability como 0/1/sí/no', COUNT(*) FROM cur.StagingPersonas WHERE Disability COLLATE Latin1_General_CS_AS IN (N'0',N'1',N'sí',N'no');

/* 3. Datos inválidos */
SELECT N'Documento sin formato SIM+7 dígitos' AS Hallazgo, COUNT(*) AS Registros FROM cur.StagingPersonas WHERE ISNULL(DocumentNumber,N'') NOT LIKE N'SIM[0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
UNION ALL SELECT N'BirthDate inexistente (ej. 31/02)', COUNT(*) FROM cur.StagingPersonas WHERE COALESCE(TRY_CONVERT(DATE, BirthDate, 23), TRY_CONVERT(DATE, BirthDate, 103)) IS NULL
UNION ALL SELECT N'BirthDate futura', COUNT(*) FROM cur.StagingPersonas WHERE TRY_CONVERT(DATE, BirthDate, 23) > CAST(GETDATE() AS DATE)
UNION ALL SELECT N'SurveyDate inválida', COUNT(*) FROM cur.StagingPersonas WHERE TRY_CONVERT(DATE, SurveyDate, 23) IS NULL
UNION ALL SELECT N'UpdatedAt anterior a SurveyDate', COUNT(*) FROM cur.StagingPersonas WHERE TRY_CONVERT(DATE, UpdatedAt) < TRY_CONVERT(DATE, SurveyDate, 23)
UNION ALL SELECT N'EmploymentStartDate posterior a SurveyDate', COUNT(*) FROM cur.StagingPersonas WHERE TRY_CONVERT(DATE, EmploymentStartDate, 23) > TRY_CONVERT(DATE, SurveyDate, 23)
UNION ALL SELECT N'Email sin @', COUNT(*) FROM cur.StagingPersonas WHERE Email NOT LIKE N'%@%.%'
UNION ALL SELECT N'Teléfono de longitud inválida', COUNT(*) FROM cur.StagingPersonas WHERE LEN(REPLACE(Phone,N'-',N'')) <> 10
UNION ALL SELECT N'Sex fuera de M/F/ND', COUNT(*) FROM cur.StagingPersonas WHERE Sex NOT IN (N'M',N'F',N'ND')
UNION ALL SELECT N'Zone fuera de URBANA/RURAL', COUNT(*) FROM cur.StagingPersonas WHERE Zone NOT IN (N'URBANA',N'RURAL')
UNION ALL SELECT N'Estrato fuera de 1-6', COUNT(*) FROM cur.StagingPersonas WHERE SocioeconomicStratum NOT IN (N'1',N'2',N'3',N'4',N'5',N'6')
UNION ALL SELECT N'MonthlyIncome no numérico', COUNT(*) FROM cur.StagingPersonas WHERE TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(REPLACE(REPLACE(MonthlyIncome,N'$',N''),N' ',N''),N'.',N''),N',',N'.')) IS NULL
UNION ALL SELECT N'MonthlyIncome negativo', COUNT(*) FROM cur.StagingPersonas WHERE TRY_CONVERT(DECIMAL(18,2), MonthlyIncome) < 0
UNION ALL SELECT N'Dependents no entero o negativo', COUNT(*) FROM cur.StagingPersonas WHERE TRY_CONVERT(INT, Dependents) IS NULL OR TRY_CONVERT(INT, Dependents) < 0
UNION ALL SELECT N'HouseholdSize = 0', COUNT(*) FROM cur.StagingPersonas WHERE TRY_CONVERT(INT, HouseholdSize) < 1
UNION ALL SELECT N'Municipio desconocido (M999)', COUNT(*) FROM cur.StagingPersonas WHERE MunicipalityCode = N'M999'
UNION ALL SELECT N'EMPLEADO con contrato NO_APLICA', COUNT(*) FROM cur.StagingPersonas WHERE EmploymentStatus = N'EMPLEADO' AND ContractType = N'NO_APLICA'
UNION ALL SELECT N'EMPLEADO sin ocupación', COUNT(*) FROM cur.StagingPersonas WHERE EmploymentStatus = N'EMPLEADO' AND NULLIF(OccupationCode,N'') IS NULL;

/* 4. Coherencia municipio - departamento (combinaciones en el Excel) */
SELECT MunicipalityCode, UPPER(MunicipalityName) AS MunicipalityName, DepartmentCode, DepartmentName, COUNT(*) AS Registros
FROM cur.StagingPersonas
GROUP BY MunicipalityCode, UPPER(MunicipalityName), DepartmentCode, DepartmentName
ORDER BY MunicipalityCode, Registros DESC;

/* 5. Edad reportada vs. edad calculada (nacimiento -> encuesta) */
SELECT ABS(DATEDIFF(YEAR, TRY_CONVERT(DATE, BirthDate, 23), TRY_CONVERT(DATE, SurveyDate, 23)) - TRY_CONVERT(INT, ReportedAge)) AS DiferenciaAnios,
       COUNT(*) AS Registros
FROM cur.StagingPersonas
WHERE TRY_CONVERT(DATE, BirthDate, 23) IS NOT NULL AND TRY_CONVERT(DATE, SurveyDate, 23) IS NOT NULL
GROUP BY ABS(DATEDIFF(YEAR, TRY_CONVERT(DATE, BirthDate, 23), TRY_CONVERT(DATE, SurveyDate, 23)) - TRY_CONVERT(INT, ReportedAge))
ORDER BY DiferenciaAnios;

/* 6. Duplicados: clave de persona (tipo+número) y de observación (persona+fecha) */
SELECT N'Personas con más de un registro' AS Hallazgo, COUNT(*) AS Grupos FROM (
    SELECT UPPER(DocumentType) t, DocumentNumber FROM cur.StagingPersonas
    WHERE DocumentNumber LIKE N'SIM%' GROUP BY UPPER(DocumentType), DocumentNumber HAVING COUNT(*) > 1) x
UNION ALL
SELECT N'Observaciones duplicadas (persona + SurveyDate)', COUNT(*) FROM (
    SELECT UPPER(DocumentType) t, DocumentNumber, SurveyDate FROM cur.StagingPersonas
    WHERE DocumentNumber LIKE N'SIM%' GROUP BY UPPER(DocumentType), DocumentNumber, SurveyDate HAVING COUNT(*) > 1) x;

-- Detalle de los pares duplicados: ¿son idénticos o versiones distintas?
SELECT a.SourceRowId AS FilaA, b.SourceRowId AS FilaB, a.DocumentNumber, a.SurveyDate,
       a.MonthlyIncome AS IngresoA, b.MonthlyIncome AS IngresoB, a.UpdatedAt AS ActualizadoA, b.UpdatedAt AS ActualizadoB,
       CASE WHEN a.MonthlyIncome = b.MonthlyIncome AND a.UpdatedAt = b.UpdatedAt THEN N'Idéntico' ELSE N'Versión distinta' END AS Tipo
FROM cur.StagingPersonas a
JOIN cur.StagingPersonas b
  ON UPPER(a.DocumentType) = UPPER(b.DocumentType) AND a.DocumentNumber = b.DocumentNumber
 AND a.SurveyDate = b.SurveyDate AND TRY_CONVERT(INT, a.SourceRowId) < TRY_CONVERT(INT, b.SourceRowId)
WHERE a.DocumentNumber LIKE N'SIM%'
ORDER BY TRY_CONVERT(INT, a.SourceRowId);
