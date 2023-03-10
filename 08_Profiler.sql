--Profiler: Live mitverfolgen was auf der Datenbank passiert
--Tools -> SQL Server Profiler

--Name: Dateiname
--Template: Tuning
--Save to File
--File Rollover
--Enable Stop Trace Time: 30min

--Events: SP:StmtStarting, SP:StmtStopping, SP:BatchStarted, SP:BatchCompleted, ...
--ColumnFilter: DatabaseName Like <Name>

SELECT * FROM KundenUmsatz; --Abfrage ist im Profiler sichtbar

--Tuning Advisor
--Tools -> Database Engine Tuning Advisor

--braucht ein .trc File vom Profiler
--Datenbank für Workload auswählen (tempdb)
--Datenbank auswählen für Tuning (Northwind) oder einzelne Tabellen

--Auswählen was optimiert werden soll (Indizes, filtered Indizes, Columnstore Indizes, Partitionen, ...)
--Start analysis

--Ergebnisse auswählen die implementiert werden sollen -> Select recommendation
--Action -> Apply recommendation