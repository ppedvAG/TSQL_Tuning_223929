/*
	Normalerweise:
	1. Jede Zelle sollte genau einen Wert haben
	2. Jeder Datensatz sollte einen Prim�rschl�ssel haben
	3. Keine Beziehungen zwischen nicht Schl�ssel-Spalten

	Redundanz verringern (Daten nicht doppelt speichern)
	- Beziehungen zwischen Tabellen
	PK -- Beziehung -- FK

	Kundentabelle: 1 Mio. DS
	Bestellungen: 100 Mio. DS
	Bestellungen -> Beziehung -> Kunden
*/

/*
	Seiten:
	8192 Byte gesamt (8KB) pro Seite
	132 Byte f�r Management Daten
	8060 Byte f�r tats�chliche Daten

	Max. 700 Datens�tze pro Seite
	Keine Seiten�bergriffe f�r Datens�tze
	Leerer Raum kann existieren (sollte m�glichst verringert werden)

	Seiten werden 1:1 geladen -> Redundanz verringern -> Seitenanzahl verringern
*/

CREATE DATABASE Demo;
USE Demo;

CREATE TABLE T1 (id int identity, test char(4100)); --Absichtlich ineffiziente Tabelle

INSERT INTO T1
SELECT 'xy'
GO 20000 --GO <Zahl>: f�hrt einen Befehl X-Mal aus

--DBCC: Database Console Commands
DBCC showcontig('T1');

--Wie gro� ist die Tabelle tats�chlich?
--20000 Datens�tze * 4100 Byte pro DS = ~80MB, .mdf hat aber 200MB
--C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA

CREATE TABLE T2 (id int identity, test varchar(MAX));

INSERT INTO T2
SELECT 'xy'
GO 20000

DBCC showcontig('T2');
--Bytes frei 496, Seitendichte 93.87%
--Durch 700 Datens�tze "nur" 93.87%

--Gibt verschiedene Page-Daten �ber die Tabellen zur�ck
SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED');

SELECT OBJECT_ID('T1'); --ID �ber einen Namen holen
SELECT OBJECT_NAME(581577110); --Namen �ber eine ID holen

SELECT OBJECT_NAME(object_id), *
FROM sys.dm_db_index_physical_stats(DB_ID(), 0, -1, 0, 'DETAILED')
WHERE object_id = OBJECT_ID('T1');


--Northwind anschauen

USE Northwind;

DBCC showcontig('Customers');
--Customers Tabelle
--97% F�llgrad -> gut
--alle Spalten mit n -> Unicode, brauchen doppelt soviel Speicherplatz -> mehr Seiten -> weniger Performance
--CustomerID ist ein nchar(5) -> 10 Byte pro Datensatz, k�nnte ein char(5) sein -> 5 Byte pro Datensatz
--Bei Country, Phone, Fax das gleiche
--> Weniger Seite, schneller Tabelle

--nvarchar -> varchar (teilweise)

--INFORMATION_SCHEMA: Gibt verschiedene Informationen �ber die Datenbank zur�ck
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Orders';

--Zeigt die Ausf�hrungszeiten und Lesevorg�nge aller Abfragen an
SET STATISTICS time, io ON;

USE Demo;

SELECT * FROM T1;
--Logische Lesevorg�nge: 20000, CPU-Zeit = 156 ms, verstrichene Zeit = 720 ms
--Logische Lesevorg�nge reduzieren > Gesamtzeit > CPU-Zeit
--Lesevorg�nge reduzieren ergibt die anderen beiden Faktoren automatisch

SELECT * FROM T2;
--Logische Lesevorg�nge: 50, CPU-Zeit = 0 ms, verstrichene Zeit = 117 ms
--weniger Lesevorg�nge -> weniger Gesamtzeit

SELECT * FROM T1 WHERE id = 100;
--Logische Lesevorg�nge: 20000, CPU-Zeit = 31 ms, verstrichene Zeit = 24 ms
--Nicht relevante Datens�tze �berspringen

SELECT TOP 1 * FROM T1 WHERE id = 100;
--Logische Lesevorg�nge: 100, CPU-Zeit = 0 ms, verstrichene Zeit = 0 ms
--Durch TOP 1 wird beim ersten Datensatz aufgeh�rt

CREATE TABLE T3 (id int identity unique, test varchar(max));

INSERT INTO T3
SELECT 'xy'
GO 20000

SELECT * FROM T3 WHERE id = 100;
--Auch bei UNIQUE h�rt die Datenbank beim ersten Datensatz auf

--Seiten reduzieren
--Bessere Datentypen, Redesign (mehr Tabellen und Beziehungen)
--Bessere Verteilung der Daten, andere Schl�ssel, ...

--1 Mio. Seiten * 2DS / Seite: 500000 Seiten -> 4GB
--1 Mio. Seiten * 50DS / Seite: 12500 Seiten -> 110MB

SET STATISTICS time, io OFF;

CREATE TABLE T4 (id int identity, test nvarchar(MAX));

INSERT INTO T4
SELECT 'xy'
GO 20000

DBCC showcontig('T2'); --50 Seiten
DBCC showcontig('T4'); --55 Seiten durch nvarchar

--Northwind
--CustomerID = nchar(5) -> char(5)
--varchar(50) -> standardm��ig 4B
--nvarchar(50) -> standardm��ig 8B
--text -> deprecated seit 2005

--float: 4B bei kleinen Zahlen, 8B bei gro�en Zahlen
--decimal(X, Y): je weniger Platz desto weniger Bytes

--money: 8B
--smallmoney: 4B

--tinyint: 1B, smallint: 2B, int: 4B, bigint: 8B

USE Northwind;

SET STATISTICS time, io ON;

--Alle Datens�tze aus dem Jahr 1997
SELECT * FROM Orders WHERE YEAR(OrderDate) = 1997; --86ms, sollte am langsamsten sein weil Funktion
SELECT * FROM Orders WHERE OrderDate >= '19970101' AND OrderDate <= '19971231'; --83ms, normalerweise schnellste
SELECT * FROM Orders WHERE OrderDate BETWEEN '19970101' AND '19971231'; --82ms, etwas langsamer als > und <