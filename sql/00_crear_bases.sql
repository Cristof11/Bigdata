/* =====================================================================
   00_crear_bases.sql
   Crea las dos bases de datos del trabajo y sus esquemas.
     - PersonasETL : staging, cursor, modelo relacional (MER) y bitácoras
     - PersonasDW  : bodega de datos en esquema estrella
   Ejecutar en SSMS conectado a la instancia de SQL Server 2025.
   ===================================================================== */
USE master;
GO
IF DB_ID(N'PersonasETL') IS NULL CREATE DATABASE PersonasETL;
GO
IF DB_ID(N'PersonasDW') IS NULL CREATE DATABASE PersonasDW;
GO

USE PersonasETL;
GO
IF SCHEMA_ID(N'cur') IS NULL EXEC (N'CREATE SCHEMA cur');   -- ejercicio con cursores
GO
IF SCHEMA_ID(N'stg') IS NULL EXEC (N'CREATE SCHEMA stg');   -- staging de SSIS
GO
IF SCHEMA_ID(N'etl') IS NULL EXEC (N'CREATE SCHEMA etl');   -- bitácoras: rechazos, revisión, duplicados, cambios
GO
PRINT N'Bases y esquemas listos.';
