-- Check Database Status for Health Check
SET HEADING OFF FEEDBACK OFF

SELECT 'Database is ' || status FROM v$instance;

EXIT;
