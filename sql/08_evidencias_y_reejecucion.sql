/* =====================================================================
   08_evidencias_y_reejecucion.sql
   Ejecutar DESPUÉS de correr los paquetes SSIS (y otra vez tras la
   segunda ejecución). Produce las evidencias del informe:
     A. Conteos de aceptados, rechazados, revisión y duplicados
     B. Antes / después de registros de ejemplo
     C. Prueba de no duplicados tras la re-ejecución
   ===================================================================== */
USE PersonasETL;
GO

/* ---------- A. Conteos de la última ejecución del paquete A ---------- */
SELECT N'Leídas del Excel'          AS Concepto, COUNT(*) AS Registros FROM stg.PersonasRaw
UNION ALL SELECT N'Rechazadas',              COUNT(*) FROM etl.Rechazo
UNION ALL SELECT N'Descartadas por duplicado', COUNT(*) FROM etl.Duplicado
UNION ALL SELECT N'Enviadas a revisión',     COUNT(*) FROM etl.Revision
UNION ALL SELECT N'Válidas (depuradas)',     COUNT(*) FROM stg.PersonaDepurada
UNION ALL SELECT N'Filas con correcciones',  COUNT(*) FROM etl.LogCambio
UNION ALL SELECT N'Personas en el modelo',   COUNT(*) FROM dbo.Persona
UNION ALL SELECT N'Observaciones en el modelo', COUNT(*) FROM dbo.Observacion
UNION ALL SELECT N'Empleadores en el modelo',   COUNT(*) FROM dbo.Empleador;
-- Esperado: 1000 | 90 | 50 | 391 | 469 | 509 | 469 | 469 | 20

-- Motivos de rechazo y de revisión (una fila puede tener varios motivos)
SELECT N'Rechazo' AS Tipo, LTRIM(RTRIM(m.value)) AS Motivo, COUNT(*) AS Registros
FROM etl.Rechazo r CROSS APPLY STRING_SPLIT(r.Motivo, N';') m
WHERE LTRIM(RTRIM(m.value)) <> N'' GROUP BY LTRIM(RTRIM(m.value))
UNION ALL
SELECT N'Revisión', LTRIM(RTRIM(m.value)), COUNT(*)
FROM etl.Revision r CROSS APPLY STRING_SPLIT(r.Motivo, N';') m
WHERE LTRIM(RTRIM(m.value)) <> N'' GROUP BY LTRIM(RTRIM(m.value))
ORDER BY Tipo, Registros DESC;

-- Correcciones más frecuentes
SELECT LTRIM(RTRIM(m.value)) AS Correccion, COUNT(*) AS Registros
FROM etl.LogCambio l CROSS APPLY STRING_SPLIT(l.Cambios, N';') m
WHERE LTRIM(RTRIM(m.value)) <> N'' GROUP BY LTRIM(RTRIM(m.value)) ORDER BY Registros DESC;

/* ---------- B. Antes / después ---------- */
-- B1. Corrección: fila 4 (tipo de documento 'cc', teléfono con guion) y fila 18 (ingreso con $)
SELECT N'ANTES' AS Momento, r.SourceRowId, r.DocumentType, r.FirstName, r.LastName, r.Phone, r.MonthlyIncome, r.MonthlyExpenses, r.Disability
FROM stg.PersonasRaw r WHERE r.SourceRowId IN (N'4', N'18', N'22');
SELECT N'DESPUÉS' AS Momento, d.SourceRowId, d.TipoDocumento, d.PrimerNombre, d.PrimerApellido, d.Telefono, d.IngresoMensual, d.GastoMensual, d.Discapacidad
FROM stg.PersonaDepurada d WHERE d.SourceRowId IN (4, 18, 22);
SELECT SourceRowId, Cambios FROM etl.LogCambio WHERE SourceRowId IN (4, 18, 22);

-- B2. Rechazo: fila 2 (sin documento) y fila 33 (sin primer nombre)
SELECT SourceRowId, TipoDocumento, NumeroDocumento, PrimerNombre, Motivo
FROM etl.Rechazo WHERE SourceRowId IN (2, 33);

-- B3. Revisión: fila 5 (nacimiento 31/02/1990) y fila 13 (municipio/departamento incoherente, ingreso en letras)
SELECT SourceRowId, NumeroDocumento, BirthDateOriginal, MunicipioCodigo, IngresoOriginal, Motivo
FROM etl.Revision WHERE SourceRowId IN (5, 13);

-- B4. Duplicados: 801/951 (idénticos) y 826/976 (976 tiene ingreso corregido y UpdatedAt más reciente)
SELECT SourceRowId AS Descartado, SourceRowIdConservado AS Conservado, NumeroDocumento, FechaEncuesta,
       FechaActualizacion, IngresoMensual, Versiones, Motivo
FROM etl.Duplicado WHERE NumeroDocumento IN (N'SIM0000801', N'SIM0000826');
SELECT o.SourceRowId, p.NumeroDocumento, o.FechaEncuesta, o.IngresoMensual, o.FechaActualizacionOrigen
FROM dbo.Observacion o JOIN dbo.Persona p ON p.PersonaId = o.PersonaId
WHERE p.NumeroDocumento IN (N'SIM0000801', N'SIM0000826');
-- Esperado: se conserva 801 (primera aparición, copia idéntica) y 976 (ingreso 15.200.000, actualizado 18:45)

/* ---------- C. Re-ejecución: no deben existir duplicados ---------- */
SELECT N'Persona duplicada (tipo+número)' AS Prueba, COUNT(*) AS GruposDuplicados
FROM (SELECT TipoDocumento, NumeroDocumento FROM dbo.Persona GROUP BY TipoDocumento, NumeroDocumento HAVING COUNT(*) > 1) x
UNION ALL
SELECT N'Observación duplicada (persona+fecha)', COUNT(*)
FROM (SELECT PersonaId, FechaEncuesta FROM dbo.Observacion GROUP BY PersonaId, FechaEncuesta HAVING COUNT(*) > 1) x
UNION ALL
SELECT N'Hecho duplicado (persona+tiempo)', COUNT(*)
FROM (SELECT PersonaKey, TiempoKey FROM PersonasDW.dbo.FactObservacion GROUP BY PersonaKey, TiempoKey HAVING COUNT(*) > 1) x
UNION ALL
SELECT N'DimPersona duplicada', COUNT(*)
FROM (SELECT PersonaId FROM PersonasDW.dbo.DimPersona GROUP BY PersonaId HAVING COUNT(*) > 1) x;
-- Esperado: 0 en todas

-- Historial de ejecuciones: la 2.a corrida debe mostrar 0 insertadas
SELECT * FROM etl.EjecucionPaquete ORDER BY EjecucionId;
SELECT * FROM PersonasDW.dbo.EjecucionCarga ORDER BY EjecucionId;

-- Conteo de filas por tabla del DW
SELECT N'DimTiempo' AS Tabla, COUNT(*) AS Filas FROM PersonasDW.dbo.DimTiempo
UNION ALL SELECT N'DimUbicacion', COUNT(*) FROM PersonasDW.dbo.DimUbicacion
UNION ALL SELECT N'DimEducacion', COUNT(*) FROM PersonasDW.dbo.DimEducacion
UNION ALL SELECT N'DimSituacionLaboral', COUNT(*) FROM PersonasDW.dbo.DimSituacionLaboral
UNION ALL SELECT N'DimPersona', COUNT(*) FROM PersonasDW.dbo.DimPersona
UNION ALL SELECT N'FactObservacion', COUNT(*) FROM PersonasDW.dbo.FactObservacion;
-- Esperado: 295 | 10 | 7 | 5 | 469 | 469
