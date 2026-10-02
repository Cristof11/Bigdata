/* =====================================================================
   06_consultas_dw_y_validacion.sql
   Las 4 consultas analíticas sobre el DW y su verificación contra el
   modelo relacional (PersonasETL). Cada verificación debe devolver 0
   diferencias.
   ===================================================================== */
USE PersonasDW;
GO

/* ---------- Q1. Personas distintas por municipio ---------- */
SELECT u.DepartamentoNombre, u.MunicipioNombre,
       COUNT(DISTINCT f.PersonaKey) AS PersonasDistintas
FROM dbo.FactObservacion f
JOIN dbo.DimUbicacion u ON u.UbicacionKey = f.UbicacionKey
GROUP BY u.DepartamentoNombre, u.MunicipioNombre
ORDER BY u.DepartamentoNombre, u.MunicipioNombre;

/* ---------- Q2. Ingreso promedio por nivel educativo ---------- */
SELECT e.NivelEducativoNombre,
       CAST(AVG(f.IngresoMensual) AS DECIMAL(18,2)) AS IngresoPromedio,
       SUM(f.CantidadObservaciones)                 AS Observaciones
FROM dbo.FactObservacion f
JOIN dbo.DimEducacion e ON e.EducacionKey = f.EducacionKey
GROUP BY e.NivelEducativoNombre, e.Orden
ORDER BY e.Orden;

/* ---------- Q3. Balance promedio por situación laboral ---------- */
SELECT s.SituacionLaboralNombre,
       CAST(AVG(f.BalanceMensual) AS DECIMAL(18,2)) AS BalancePromedio,
       SUM(f.CantidadObservaciones)                 AS Observaciones
FROM dbo.FactObservacion f
JOIN dbo.DimSituacionLaboral s ON s.SituacionLaboralKey = f.SituacionLaboralKey
GROUP BY s.SituacionLaboralNombre
ORDER BY BalancePromedio DESC;

/* ---------- Q4. Cantidad de observaciones por año y mes ---------- */
SELECT t.Anio, t.Mes, t.NombreMes,
       SUM(f.CantidadObservaciones) AS Observaciones
FROM dbo.FactObservacion f
JOIN dbo.DimTiempo t ON t.TiempoKey = f.TiempoKey
GROUP BY t.Anio, t.Mes, t.NombreMes
ORDER BY t.Anio, t.Mes;
GO

/* =====================================================================
   VERIFICACIÓN: DW vs. modelo relacional
   Se calcula cada consulta en ambos modelos y se cruzan con FULL JOIN.
   Resultado esperado de cada bloque: Diferencias = 0
   ===================================================================== */

-- V1: personas distintas por municipio
WITH dw AS (
    SELECT u.MunicipioCodigo, COUNT(DISTINCT f.PersonaKey) AS Valor
    FROM dbo.FactObservacion f JOIN dbo.DimUbicacion u ON u.UbicacionKey = f.UbicacionKey
    GROUP BY u.MunicipioCodigo),
rel AS (
    SELECT o.MunicipioCodigo, COUNT(DISTINCT o.PersonaId) AS Valor
    FROM PersonasETL.dbo.Observacion o
    GROUP BY o.MunicipioCodigo)
SELECT N'Q1 Personas por municipio' AS Verificacion, COUNT(*) AS Diferencias
FROM dw FULL JOIN rel ON rel.MunicipioCodigo = dw.MunicipioCodigo
WHERE dw.Valor IS NULL OR rel.Valor IS NULL OR dw.Valor <> rel.Valor;

-- V2: ingreso promedio por nivel educativo
WITH dw AS (
    SELECT e.NivelEducativoCodigo AS Codigo, CAST(AVG(f.IngresoMensual) AS DECIMAL(18,2)) AS Valor
    FROM dbo.FactObservacion f JOIN dbo.DimEducacion e ON e.EducacionKey = f.EducacionKey
    GROUP BY e.NivelEducativoCodigo),
rel AS (
    SELECT o.NivelEducativoCodigo AS Codigo, CAST(AVG(o.IngresoMensual) AS DECIMAL(18,2)) AS Valor
    FROM PersonasETL.dbo.Observacion o GROUP BY o.NivelEducativoCodigo)
SELECT N'Q2 Ingreso por educación' AS Verificacion, COUNT(*) AS Diferencias
FROM dw FULL JOIN rel ON rel.Codigo = dw.Codigo
WHERE dw.Valor IS NULL OR rel.Valor IS NULL OR dw.Valor <> rel.Valor;

-- V3: balance promedio por situación laboral
WITH dw AS (
    SELECT s.SituacionLaboralCodigo AS Codigo, CAST(AVG(f.BalanceMensual) AS DECIMAL(18,2)) AS Valor
    FROM dbo.FactObservacion f JOIN dbo.DimSituacionLaboral s ON s.SituacionLaboralKey = f.SituacionLaboralKey
    GROUP BY s.SituacionLaboralCodigo),
rel AS (
    SELECT o.SituacionLaboralCodigo AS Codigo,
           CAST(AVG(o.IngresoMensual - o.GastoMensual) AS DECIMAL(18,2)) AS Valor
    FROM PersonasETL.dbo.Observacion o GROUP BY o.SituacionLaboralCodigo)
SELECT N'Q3 Balance por situación' AS Verificacion, COUNT(*) AS Diferencias
FROM dw FULL JOIN rel ON rel.Codigo = dw.Codigo
WHERE dw.Valor IS NULL OR rel.Valor IS NULL OR dw.Valor <> rel.Valor;

-- V4: observaciones por año y mes
WITH dw AS (
    SELECT t.Anio, t.Mes, SUM(f.CantidadObservaciones) AS Valor
    FROM dbo.FactObservacion f JOIN dbo.DimTiempo t ON t.TiempoKey = f.TiempoKey
    GROUP BY t.Anio, t.Mes),
rel AS (
    SELECT YEAR(o.FechaEncuesta) AS Anio, MONTH(o.FechaEncuesta) AS Mes, COUNT(*) AS Valor
    FROM PersonasETL.dbo.Observacion o GROUP BY YEAR(o.FechaEncuesta), MONTH(o.FechaEncuesta))
SELECT N'Q4 Observaciones por año-mes' AS Verificacion, COUNT(*) AS Diferencias
FROM dw FULL JOIN rel ON rel.Anio = dw.Anio AND rel.Mes = dw.Mes
WHERE dw.Valor IS NULL OR rel.Valor IS NULL OR dw.Valor <> rel.Valor;

-- V5: totales generales
SELECT N'DW' AS Modelo, COUNT(*) AS Observaciones, COUNT(DISTINCT PersonaKey) AS Personas,
       SUM(IngresoMensual) AS TotalIngreso, SUM(GastoMensual) AS TotalGasto, SUM(BalanceMensual) AS TotalBalance
FROM dbo.FactObservacion
UNION ALL
SELECT N'Relacional', COUNT(*), COUNT(DISTINCT PersonaId),
       SUM(IngresoMensual), SUM(GastoMensual), SUM(IngresoMensual - GastoMensual)
FROM PersonasETL.dbo.Observacion;
-- Esperado en ambas filas: 469 | 469 | 3640800000.00 | 2896600011.00 | 744199989.00
