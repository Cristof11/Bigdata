# Big Data: ETL con cursores y SSIS (Excel → relacional → DW estrella)

**BIG DATA 701N SIS BD-A** · Universidad de Cundinamarca, Extensión Chía · Septiembre 2026  
**Creadores de oportunidades:** Cristian Mauricio Muñoz, Jeison Crishtofer Rojas, Julieth Alvarado Meriño  
**Gestor del conocimiento y aprendizaje:** Edison Gustavo Cañon

- 📄 Informe técnico: [`docs/Informe_ETL_SSIS.pdf`](docs/Informe_ETL_SSIS.pdf)
- 🎥 [Video de demostración](https://mailunicundiedu-my.sharepoint.com/:f:/g/personal/jcrishtoferrojas_ucundinamarca_edu_co/IgDmpseIN7EkTrw3OSSi0X1wAYaHwb4vUWs2wdqgOY01dtI?e=k7bPAD)

Actividad: procesos ETL con **cursores en SQL Server 2025** y **paquetes SSIS** sobre 1.000 registros de personas (`PersonasETLActividad4.xlsx`).

## Estructura
```
sql/
  00_crear_bases.sql               Bases PersonasETL y PersonasDW + esquemas
  01_cursor_tablas.sql             Staging, funciones de limpieza, destinos del cursor
  02_cursor_cargar_staging.sql     1.000 filas del Excel, valores originales sin modificar
  03_cursor_etl.sql                Cursor (SourceRowId 1-100) → válidos / rechazados
  04_modelo_relacional.sql         MER en 3FN + 15 catálogos con FK + staging y bitácoras de SSIS
  05_modelo_dw.sql                 Bodega en esquema estrella
  06_consultas_dw_y_validacion.sql 4 consultas + verificación DW frente a relacional
  07_diagnostico_inicial.sql       Faltantes, formatos, inválidos y duplicados
  08_evidencias_y_reejecucion.sql  Conteos, antes/después y prueba de no duplicados
  09_normalizacion_catalogos.sql   Categorías como tablas de catálogo con FK (sobre la base ya cargada)
  10_verificar_staging.sql         Verifica stg.PersonasRaw (el Excel sin cambios) y el recorrido al modelo
ssis/
  ProyectoETL_Personas/            Proyecto SSIS (PaqueteA_Excel_Relacional, PaqueteB_Relacional_DW)
  expresiones_paquetes.txt         Expresiones de los Derived Column listas para copiar
docs/
  Informe_ETL_SSIS.pdf             Informe técnico (normas APA)
GUIA_PASO_A_PASO.md                Instalación, construcción y ejecución
```

## Orden de ejecución
1. SSMS: `00` → `01` → `02` → `03` (cursor) → `07` (diagnóstico) → `04` → `05`
2. Visual Studio: `PaqueteA_Excel_Relacional.dtsx` y después `PaqueteB_Relacional_DW.dtsx`
3. SSMS: `06` (consultas y verificación), `08` (evidencias) y `10` (staging)
   (`09` solo se usa para migrar una base creada con la versión anterior del `04`)
4. Segunda ejecución de A y B, y otra vez `08`, para demostrar que no se generan duplicados

## Resultados esperados
| Proceso | Resultado |
|---|---|
| Cursor (1-100) | 100 procesados · 78 aceptados · 22 rechazados |
| Paquete A | DFT 0: 1000 filas del Excel a `stg.PersonasRaw` · DFT 1: 1000 leídos del staging · 90 rechazados · 50 duplicados descartados · 391 a revisión · 469 válidos |
| Modelo relacional | 469 personas · 469 observaciones · 20 empleadores |
| Paquete B | DimTiempo 295 · DimUbicacion 10 · DimEducacion 7 · DimSituacionLaboral 5 · DimPersona 469 · FactObservacion 469 |
| 2.ª ejecución | 0 filas nuevas en Persona, Observacion, dimensiones y hechos |
