--Query Store
--Erstellt Statistiken während dem Normalbetrieb
--Speichert Abfragen (Zeit, benötige Leistung, ...)

--Rechtsklick auf Datenbank -> Properties -> Query Store -> Operation Mode: Read/Write
--Neuer Ordner auf der Datenbank (Query Store) mit vorgegebenen Statistiken

--Erstmal Einstellungen vornehmen -> Zeitintervall erhöhen von einer Stunde
--Links Bar-Chart mit Abfragen -> hier Metriken einstellen (z.B. Duration, Avg)

--Rechts: Pläne pro Query, können bestimmte Pläne erzwungen werden

USE Demo;

SELECT Txt.query_text_id, Txt.query_sql_text, Pl.plan_id, Qry.*  
FROM sys.query_store_plan AS Pl 
JOIN sys.query_store_query AS Qry ON Pl.query_id = Qry.query_id  
JOIN sys.query_store_query_text AS Txt ON Qry.query_text_id = Txt.query_text_id;

EXEC sys.sp_query_store_remove_query 13; --Queries löschen

SELECT UseCounts, Cacheobjtype, Objtype, TEXT, query_plan
FROM sys.dm_exec_cached_plans 
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
CROSS APPLY sys.dm_exec_query_plan(plan_handle)