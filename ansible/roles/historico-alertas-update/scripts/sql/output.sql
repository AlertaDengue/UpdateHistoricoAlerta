-- Check the current database connection details
SELECT current_setting('server_version') AS server_version,
       current_setting('port') AS port,
       current_setting('max_connections') AS max_connections,
       current_database() AS current_database;

-- Check the maximum Epidemiological week for different diseases
SELECT 'Dengue' AS disease, max("SE") AS max_epidemiological_week FROM "Municipio"."Historico_alerta";
SELECT 'Chikungunya' AS disease, max("SE") AS max_epidemiological_week FROM "Municipio"."Historico_alerta_chik";
SELECT 'Zika' AS disease, max("SE") AS max_epidemiological_week FROM "Municipio"."Historico_alerta_zika";
