/* =====================================================================
   03_cursor_etl.sql
   Parte 1 - ETL con cursor sobre SourceRowId 1..100.
   Pasos por registro:
     1. Limpieza de espacios y estandarización (tipo doc., nombres, apellidos)
     2. Identificación de faltantes: documento, primer nombre, primer apellido
     3. Conversión de MonthlyIncome / MonthlyExpenses a número
        (quita '$', espacios y '.' de miles; ',' decimal -> '.')
     4. Detección de faltantes, no numéricos y negativos
     5. Balance mensual = ingreso - gasto (un balance negativo ES válido)
     6. Inserción en cur.PersonasValidas o cur.PersonasRechazadas (con motivo)
   Regla: NUNCA se reemplaza un importe desconocido por 0.
   Instrucciones del cursor demostradas: DECLARE, OPEN, FETCH (lectura),
   WHILE @@FETCH_STATUS (recorrido), CLOSE, DEALLOCATE.
   ===================================================================== */
USE PersonasETL;
GO
SET NOCOUNT ON;

-- El proceso es repetible: se limpian los destinos antes de cada corrida
TRUNCATE TABLE cur.PersonasValidas;
TRUNCATE TABLE cur.PersonasRechazadas;

/* ---------- Variables de trabajo ---------- */
DECLARE @SourceRowId     INT,
        @TipoDoc         NVARCHAR(50),
        @NumDoc          NVARCHAR(50),
        @PrimerNombre    NVARCHAR(100),
        @SegundoNombre   NVARCHAR(100),
        @PrimerApellido  NVARCHAR(100),
        @SegundoApellido NVARCHAR(100),
        @IngresoTxt      NVARCHAR(50),
        @GastoTxt        NVARCHAR(50);

DECLARE @DocOriginal NVARCHAR(50), @NombreOriginal NVARCHAR(100), @ApellidoOriginal NVARCHAR(100),
        @Ingreso DECIMAL(18,2), @Gasto DECIMAL(18,2), @Texto NVARCHAR(50), @Motivo NVARCHAR(500);

DECLARE @Procesados INT = 0, @Aceptados INT = 0, @Rechazados INT = 0;

/* ---------- 1) DECLARACIÓN del cursor ---------- */
DECLARE cur_personas CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
    SELECT TRY_CONVERT(INT, SourceRowId),
           DocumentType, DocumentNumber,
           FirstName, MiddleName, LastName, SecondLastName,
           MonthlyIncome, MonthlyExpenses
    FROM   cur.StagingPersonas
    WHERE  TRY_CONVERT(INT, SourceRowId) BETWEEN 1 AND 100
    ORDER BY TRY_CONVERT(INT, SourceRowId);

/* ---------- 2) APERTURA ---------- */
OPEN cur_personas;

/* ---------- 3) LECTURA del primer registro ---------- */
FETCH NEXT FROM cur_personas
 INTO @SourceRowId, @TipoDoc, @NumDoc, @PrimerNombre, @SegundoNombre,
      @PrimerApellido, @SegundoApellido, @IngresoTxt, @GastoTxt;

/* ---------- 4) RECORRIDO ---------- */
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Procesados += 1;
    SET @Motivo  = N'';
    SET @Ingreso = NULL;
    SET @Gasto   = NULL;
    SET @DocOriginal = @NumDoc; SET @NombreOriginal = @PrimerNombre; SET @ApellidoOriginal = @PrimerApellido;

    -- 4.1 Limpieza de espacios y estandarización de escritura
    SET @TipoDoc         = UPPER(cur.fn_LimpiarTexto(@TipoDoc));          -- cc -> CC
    SET @NumDoc          = UPPER(cur.fn_LimpiarTexto(@NumDoc));
    SET @PrimerNombre    = cur.fn_NombrePropio(@PrimerNombre);            -- andrés -> Andrés
    SET @SegundoNombre   = cur.fn_NombrePropio(@SegundoNombre);
    SET @PrimerApellido  = cur.fn_NombrePropio(@PrimerApellido);          -- GARCÍA -> García
    SET @SegundoApellido = cur.fn_NombrePropio(@SegundoApellido);

    -- 4.2 Campos obligatorios ('SIN-DATO' equivale a no tener documento)
    IF @NumDoc IS NULL OR @NumDoc = N'SIN-DATO' SET @Motivo += N'Sin documento; ';
    IF @PrimerNombre   IS NULL                  SET @Motivo += N'Sin primer nombre; ';
    IF @PrimerApellido IS NULL                  SET @Motivo += N'Sin primer apellido; ';

    -- 4.3 Ingreso mensual: limpiar símbolos y separadores, luego convertir
    SET @Texto = cur.fn_LimpiarTexto(@IngresoTxt);
    IF @Texto IS NULL
        SET @Motivo += N'Ingreso faltante; ';
    ELSE
    BEGIN
        SET @Texto   = REPLACE(REPLACE(REPLACE(@Texto, N'$', N''), N' ', N''), N'.', N'');  -- '.' = miles
        SET @Texto   = REPLACE(@Texto, N',', N'.');                                         -- ',' = decimal
        SET @Ingreso = TRY_CONVERT(DECIMAL(18,2), @Texto);
        IF @Ingreso IS NULL     SET @Motivo += N'Ingreso no numérico; ';
        ELSE IF @Ingreso < 0    SET @Motivo += N'Ingreso negativo; ';
    END;

    -- 4.4 Gasto mensual: misma regla
    SET @Texto = cur.fn_LimpiarTexto(@GastoTxt);
    IF @Texto IS NULL
        SET @Motivo += N'Gasto faltante; ';
    ELSE
    BEGIN
        SET @Texto = REPLACE(REPLACE(REPLACE(@Texto, N'$', N''), N' ', N''), N'.', N'');
        SET @Texto = REPLACE(@Texto, N',', N'.');
        SET @Gasto = TRY_CONVERT(DECIMAL(18,2), @Texto);
        IF @Gasto IS NULL       SET @Motivo += N'Gasto no numérico; ';
        ELSE IF @Gasto < 0      SET @Motivo += N'Gasto negativo; ';
    END;

    -- 4.5 Destino: válido (con balance) o rechazado (con motivo)
    IF @Motivo = N''
    BEGIN
        INSERT INTO cur.PersonasValidas
              (SourceRowId, TipoDocumento, NumeroDocumento, PrimerNombre, SegundoNombre,
               PrimerApellido, SegundoApellido, IngresoOriginal, GastoOriginal,
               IngresoMensual, GastoMensual, BalanceMensual)
        VALUES (@SourceRowId, @TipoDoc, @NumDoc, @PrimerNombre, @SegundoNombre,
                @PrimerApellido, @SegundoApellido, @IngresoTxt, @GastoTxt,
                @Ingreso, @Gasto, @Ingreso - @Gasto);
        SET @Aceptados += 1;
    END
    ELSE
    BEGIN
        INSERT INTO cur.PersonasRechazadas
              (SourceRowId, Motivo, DocumentoOriginal, PrimerNombreOriginal,
               PrimerApellidoOriginal, IngresoOriginal, GastoOriginal)
        VALUES (@SourceRowId, LEFT(@Motivo, LEN(@Motivo) - 1),   -- quita el último ';'
                @DocOriginal, @NombreOriginal, @ApellidoOriginal, @IngresoTxt, @GastoTxt);
        SET @Rechazados += 1;
    END;

    -- Lectura del siguiente registro
    FETCH NEXT FROM cur_personas
     INTO @SourceRowId, @TipoDoc, @NumDoc, @PrimerNombre, @SegundoNombre,
          @PrimerApellido, @SegundoApellido, @IngresoTxt, @GastoTxt;
END;

/* ---------- 5) CIERRE y 6) LIBERACIÓN ---------- */
CLOSE cur_personas;
DEALLOCATE cur_personas;

/* ---------- Resultados ---------- */
INSERT INTO cur.ResumenEjecucion (Procesados, Aceptados, Rechazados)
VALUES (@Procesados, @Aceptados, @Rechazados);

SELECT @Procesados AS Procesados, @Aceptados AS Aceptados, @Rechazados AS Rechazados;
-- Esperado: Procesados 100 | Aceptados 78 | Rechazados 22

SELECT TOP (15) SourceRowId, TipoDocumento, NumeroDocumento, PrimerNombre, PrimerApellido,
       IngresoOriginal, GastoOriginal, IngresoMensual, GastoMensual, BalanceMensual
FROM cur.PersonasValidas ORDER BY SourceRowId;

SELECT SourceRowId, Motivo, DocumentoOriginal, PrimerNombreOriginal, IngresoOriginal, GastoOriginal
FROM cur.PersonasRechazadas ORDER BY SourceRowId;

-- Conteo por motivo (un registro puede tener varios motivos)
SELECT LTRIM(m.value) AS Motivo, COUNT(*) AS Registros
FROM cur.PersonasRechazadas r
CROSS APPLY STRING_SPLIT(r.Motivo, N';') m
GROUP BY LTRIM(m.value)
ORDER BY Registros DESC;

-- Evidencia: balances negativos aceptados (no son motivo de rechazo)
SELECT COUNT(*) AS AceptadosConBalanceNegativo   -- esperado: 30
FROM cur.PersonasValidas WHERE BalanceMensual < 0;
