USE Demo;

/*
	Heap: Tabelle in unsortierter Form (alle Daten)

	Non-Clustered Index (NCIX):
	Baumstruktur (von oben nach unten)
	Maximal 1000 Stück pro Tabelle
	Sollte auf häufig angewandte SQL-Statements angepasst werden
	Auch auf Spalten die häufig mit WHERE gesucht werden

	Clustered Index (CIX):
	Maximal einer pro Tabelle
	Bietet sich einer ID Spalte an
	Wird automatisch sortiert (bei INSERT wird der Datensatz automatisch an der richtigen Stelle eingefügt)
	Sollte vermieden werden auf sehr großen Tabellen oder auf Tabellen mit vielen INSERTs -> viele Sortierungen, kostet Performance

	Table Scan: Suche die ganz Tabelle
	Index Scan: Durchsuche den Index
	Index Seek: bestimmte Daten im Index suchen (beste)
*/

USE Northwind;

--Clustered Index
SELECT * FROM Orders; --Clustered Index Scan (Kosten: 0.0182)
SELECT * FROM Orders WHERE OrderID = 10248; --Clustered Index Seek (Kosten: 0.00328)
INSERT INTO Customers (CustomerID, CompanyName) VALUES ('PPEDV', 'ppedv AG'); --Clustered Index Insert (Kosten: 0.05 da Sortierung)
DELETE FROM Customers WHERE CustomerID = 'PPEDV'; --Index Seek um den Datensatz zu finden und danach Clustered Index Delete (hohe Kosten dank Sortierung)

USE Demo;

SELECT * INTO Orders FROM Northwind.dbo.Orders; --Kopieren von Orders Tabelle ohne Indizes
SELECT * FROM Orders WHERE OrderID = 10248; --Table Scan (Kosten: 0.0182)
ALTER TABLE Orders ADD CONSTRAINT PK_Orders PRIMARY KEY(OrderID); --Constraint fügt automatisch Clustered Index hinzu

SET STATISTICS time, io ON;

SELECT * INTO KU2 FROM KundenUmsatz; --Neue Tabelle anlegen um Kompression zu entfernen

SELECT * FROM KU2;
--Logische Lesevorgänge: 41328, CPU-Zeit = 4657 ms, verstrichene Zeit = 24114 ms

ALTER TABLE KU2 ADD ID INT IDENTITY PRIMARY KEY; --ID hinzufügen, Clustered Index automatisch

SELECT * FROM KU2; --Logische Lesevorgänge: 41960 -> Index Scan

SELECT OBJECT_NAME(object_id), * --Indizes + Ebenen anschauen
FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED');

SELECT * FROM KU2 WHERE ID = 50; --Clustered Index Seek, logische Lesevorgänge: 3

SELECT * FROM KU2 WHERE ID = 50;
--Ohne Index: Table Scan, aber schnell weil Identity
--Logische Lesevorgänge: 41887

--Index Key Columns: Spalten nach denen Indiziert wrid (generell die Spalten nach denen gesucht wird z.B. WHERE)
--Included Columns: Spalten die im SELECT noch extra geholt werden

SELECT * FROM KU2 WHERE Freight > 100;
--Index Seek über den NCIX_Freight Index
--Logische Lesevorgänge: 12071, CPU-Zeit = 2437 ms, verstrichene Zeit = 20281 ms, Kosten: 9.36
--Logische Lesevorgänge: 41887, CPU-Zeit = 1360 ms, verstrichene Zeit = 7346 ms, Kosten: 32.24

SELECT ID, birthdate FROM KU2 WHERE freight > 50;
--Auch über NCIX_Freight gegangen
--Logische Lesevorgänge: 21897, CPU-Zeit = 1016 ms, verstrichene Zeit = 9797 ms, Kosten: 16.5
--Logische Lesevorgänge: 2412, CPU-Zeit = 172 ms, verstrichene Zeit = 2476 ms, Kosten: 2.4
--Bei beiden Indizes schaut die Datenbank selbstständig welcher schneller ist

SELECT CompanyName, birthdate FROM KU2 WHERE freight > 1000;
--Key Lookup: Datensätze innerhalb einer Seite anschauen und die Spalten dazuholen (Index + Lookup schneller als Table Scan)
--Logische Lesevorgänge: 2061, CPU-Zeit = 16 ms, verstrichene Zeit = 107 ms, Kosten: 6.8 (NCIX_Freight_ID_Birthdate)
--Logische Lesevorgänge: 41887, CPU-Zeit = 201 ms, verstrichene Zeit = 177 ms, Kosten: 31.5 (ohne Index)
--Logische Lesevorgänge: 19, CPU-Zeit = 0 ms, verstrichene Zeit = 124 ms, Kosten: 0.02 (CompanyName zum Index hinzugefügt)

SELECT * FROM KU2; --Table Scan, da ein Teil von einem Index langsamer ist als einfach alle Daten anzuschauen

SELECT * FROM KU2 WHERE freight > 500; --Table Scan, da Lookup wesentlich mehr kosten würde

SELECT * FROM KU2 WHERE ID > 50 AND CustomerID LIKE 'A%'; --Index Seek
SELECT * FROM KU2 WHERE ID > 50 AND CustomerID LIKE 'A%'; --Table Scan -> Reihenfolge der Spalten im Index ist relevant
SELECT * FROM KU2 WHERE CustomerID LIKE 'A%' AND ID > 50; --Table Scan
SELECT * FROM KU2 WHERE CustomerID LIKE 'A%' AND ID > 50; --Index Seek nach Änderung der Reihenfolge im Index

--Filtered Index
--Index mit WHERE Bedingung, wird nur verwendet wenn im WHERE der Abfrage die Prädikate im Index berücksichtigt werden

SELECT * FROM KU2 WHERE ID > 50 AND CustomerID LIKE 'A%'; --Index Seek
SELECT * FROM KU2 WHERE ID > 25 AND CustomerID LIKE 'A%'; --Table Scan, da das korrekte WHERE nicht berücksichtigt wurde

--Im Plan wird hin und wieder vorgeschlagen, einen Index zu erstellen (Grüner Text)

--Indizierte View
GO
CREATE VIEW ixDemo --WITH SCHEMABINDING möglich
AS
SELECT Country, COUNT(*) AS Anzahl
FROM KU2
GROUP BY Country;
GO

SELECT * FROM ixDemo; --Table Scan

--WITH SCHEMABINDING: View wird an Tabelle gebunden -> Tabellenstruktur kann nicht geändert werden solange die View existiert
--Fehlermeldung wenn die originale Tabelle verändert wird
GO
ALTER VIEW ixDemo WITH SCHEMABINDING
AS
SELECT Country, COUNT_BIG(*) AS Anzahl --COUNT_BIG() statt COUNT() benutzen
FROM dbo.KU2 --Hier Name mit dbo. angeben
GROUP BY Country;
GO

--Jetzt kann ich einen Index erstellen (dank SCHEMABINDING)
SELECT * FROM ixDemo; --Index Scan
SELECT * FROM ixDemo WHERE Country LIKE 'A%'; --Index Seek

--Index von der View wurde auf die Tabelle übernommen
SELECT Country, COUNT(*) AS Anzahl
FROM KU2
GROUP BY Country;

GO
CREATE VIEW ixDemo2 WITH SCHEMABINDING
AS
SELECT freight FROM dbo.KU2;
GO

--Indizes von der Tabelle sind auch in der View dabei
SELECT * FROM ixDemo2 WHERE freight > 50;

--Columnstore Index
--Speichert Spalten als "eigene Tabelle"
--kann genau eine oder mehrere (wenige) Spalten sehr effizient durchsuchen
--Teilt die ausgewählte(n) Spalte(n) in der Tabelle auf 2^20 große Teile auf und speichert diese Teile in die "eigene Tabelle"
--Rest: Deltastore

SELECT *
INTO KUColumnStore
FROM KU2;

ALTER TABLE KUColumnStore DROP COLUMN ID;

INSERT INTO KUColumnStore
SELECT * FROM KUColumnStore
GO 3

SELECT COUNT(*) FROM KUColumnStore;

--ColumnStore auf CompanyName
--8 Mio. DS -> 2^20 große Teile -> 8 Stück
SELECT COUNT(*) / POWER(2, 20) FROM KUColumnStore; --Anzahl Teile
--Extra Tabelle: | CN1 | CN2 | CN3 | CN4 | CN5 | CN6 | CN7 | CN8 |
--Deltastore Separat

SELECT CompanyName FROM KUColumnStore; --kein Index -> Table Scan
--Logische Lesevorgänge: 335067, CPU-Zeit = 9203 ms, verstrichene Zeit = 75761 ms, Kosten = 246

SELECT CompanyName FROM KUColumnStore; --normaler NCIX -> Index Scan
--Logische Lesevorgänge: 58661, CPU-Zeit = 10484 ms, verstrichene Zeit = 106218 ms, Kosten: 52.8

SELECT CompanyName FROM KUColumnStore; --Columnstore Index (Non-Clustered)
--Logische LOB-Lesevorgänge: 8320, CPU-Zeit = 6922 ms, verstrichene Zeit = 69098 ms, Kosten: 0.97

--Datenbank wählt bei mehreren Indizes aus welcher am schnellsten ist

--Welche Indizes sollten existieren?
--Indizes auf Views und Prozeduren die oft gebraucht werden anpassen
--Spalten die oft angegriffen werden (im WHERE, oder generell bei sehr großen Tabellen mit dem ColumnStore)

--Index auf Abfrage anpassen
GO
CREATE PROC p_Test
AS
SELECT LastName, YEAR(OrderDate), MONTH(OrderDate), SUM(UnitPrice * Quantity)
FROM KU2
WHERE Country = 'UK'
GROUP BY LastName, YEAR(OrderDate), MONTH(OrderDate)
ORDER BY 1, 2, 3;
GO

EXEC p_Test;
--Logische Lesevorgänge: 41887, CPU-Zeit = 641 ms, verstrichene Zeit = 263 ms, Kosten: 31.33333 (kein Index)
--Logische Lesevorgänge: 490, CPU-Zeit = 62 ms, verstrichene Zeit = 190 ms, Kosten: 0.48 (angepasster Index)

--Indizes warten
--Indizes werden über Zeit veraltet (durch INSERT, UPDATE, DELETE)
--Index aktualisieren
--2 Möglichkeiten
	--Reorganize: Index neu sortieren ohne Neuaufbau (bei kleineren Tabellen)
	--Rebuild: Von Grund auf neu aufbauen
--Bei Aktualisierung die Fragmentierung möglichst verringern

SELECT OBJECT_NAME(object_id), *
FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED')
WHERE index_level = 0;