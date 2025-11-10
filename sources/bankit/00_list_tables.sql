-- Elenco tabelle/viste in SQLite
SELECT 
  name AS table_name,
  type AS table_type
FROM sqlite_master
WHERE type IN ('table','view')
  AND name NOT LIKE 'sqlite_%'
ORDER BY name;
