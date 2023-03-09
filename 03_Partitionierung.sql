USE Demo;

--Partitionierung
--Teilt Tabellen auf Partitionen auf anhand einer Spalte
--Braucht eine Funktion und ein Schema

--Partitionsfunktion
--Nimmt einen Wert als Input und gibt aus in welcher Partition dieser Wert liegen würde
--Benötigt ein Partitionsschema

CREATE PARTITION FUNCTION pfZahl(int) AS
RANGE LEFT FOR VALUES (100, 200); --Ranges festlegen von links (0-100, 101-200, 201+)

--Partitionsfunktion testen
SELECT $partition.pfZahl(50);
SELECT $partition.pfZahl(150);
SELECT $partition.pfZahl(250);

--Partitionsschema
--Legt fest welche File Gruppe welchen Datensatz bekommt anhand der Partitionsfunktion
--Benötigt eine Dateigruppe pro Bereich erstellen
CREATE PARTITION SCHEME schZahl AS
PARTITION pfZahl TO (Bereich1, Bereich2, Bereich3);

--Einzelne Bereiche auf die entsprechenden Dateigruppen zuordnen
--Jede Dateigruppe braucht ein File
--Es wird eine Dateigruppe mehr benötigt als Grenzen der Partitionsfunktion (oder eine Dateigruppe pro Bereich)

CREATE TABLE pTable (id int identity, test char(5000)) ON schZahl(id); --Hier mit ON <Schema>(<Spalte>) die Partitionierung aktivieren

INSERT INTO pTable
SELECT 'xy'
GO 20000

SELECT * FROM pTable;

SET STATISTICS time, io ON;

SELECT * FROM pTable WHERE id = 50;
--Logische Lesevorgänge: 100, CPU-Zeit = 0 ms, verstrichene Zeit = 0 ms
--50 kann nur in der untersten Partition sein

SELECT  * FROM pTable WHERE id = 150;
--Logische Lesevorgänge: 100, CPU-Zeit = 0 ms, verstrichene Zeit = 0 ms
--150 kann nur in der mittleren Partition sein

SELECT  * FROM pTable WHERE id = 5000;
--Logische Lesevorgänge: 19800, CPU-Zeit = 16 ms, verstrichene Zeit = 16 ms
--Große Partition wurde durchsucht, untere Partitionen wurden ausgelassen

--Partitionsfunktion neue Grenze hinzufügen
ALTER PARTITION SCHEME schZahl NEXT USED Bereich4; --Neue Dateigruppe muss zuerst hinzugefügt werden -----Bereich1-----Bereich2-----Bereich3-----Bereich4-----
ALTER PARTITION FUNCTION pfZahl() SPLIT RANGE(5000); -----100-----200-----5000-----

SELECT $partition.pfZahl(4000);
SELECT $partition.pfZahl(6000); --Partition 4

SELECT * FROM pTable WHERE id = 5000;
--Logische Lesevorgänge: 4800, CPU-Zeit = 16 ms, verstrichene Zeit = 6 ms
--Daten wurden von dieser Partition entfernt

SELECT * FROM pTable WHERE id = 5001;
--Logische Lesevorgänge: 15000, CPU-Zeit = 0 ms, verstrichene Zeit = 11 ms
--Daten wurden automatisch verschoben auf Partition 4

ALTER PARTITION FUNCTION pfZahl() MERGE RANGE(100); --Range entfernen -> -----200-----5000-----

SELECT $partition.pfZahl(50); --1
SELECT $partition.pfZahl(150); --auch 1

--Tabellenstruktur kopieren
SELECT TOP 0 *
INTO Archiv200 ON [Bereich2] --Tabelle muss auf der selben Dateigruppe liegen wie die Partition
FROM pTable;

ALTER TABLE pTable SWITCH PARTITION 1 TO Archiv200; --Datensätze aus Partition 1 in die Archivtabelle bewegen

SELECT * FROM pTable;
SELECT * FROM Archiv200;