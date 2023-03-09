/*
	Dateigruppen:
	[PRIMARY]: Hauptgruppe -> enthält alle Systemdatenbanken, Tabellen sind standardmäßig auf PRIMARY, kann nicht entfernt werden (.mdf)
	Nebengruppen: Datenbankobjekte können auf Nebengruppen gelegt werden (.ndf)
*/

USE Demo;

--Neue Filegroup erstellen: Rechtsklick auf die Datenbank -> Properties -> Filegroups -> Add Filegroup
CREATE TABLE FG1 (id int identity, test char(4100)) ON [AKTIV]; --Tabelle auf Dateigruppe legen mit ON <Name>

--File erstellen: Rechtsklick auf Datenbank -> Properties -> Files -> Add File
--Name festlegen, Dateigruppe festlegen, Pfad festlegen, Dateiname festlegen mit .ndf Endung

INSERT INTO FG1
SELECT 'xy'
GO 20000 --Neues File wurde jetzt beschrieben

ALTER DATABASE Demo ADD FILE
(
	NAME='Test',
	FILENAME='C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Test.ndf',
	SIZE=8MB,
	FILEGROWTH=64MB
);

--Wie bewegt man eine Tabelle auf eine andere Filegroup?
--Tabelle auf der anderen Seite erstellen und Daten bewegen
CREATE TABLE Test (id int identity) ON [Aktiv];

INSERT INTO Test
SELECT * FROM FG1;

DROP TABLE FG1;

--Salamitaktik
--Aufteilung von großen Tabellen auf mehrere kleine Tabellen
--Zusammenbauen mit indizierter Sicht

CREATE TABLE Umsatz
(
	Datum date,
	Umsatz float
)

DECLARE @i int = 0;
WHILE @i < 100000
BEGIN
	INSERT INTO Umsatz VALUES
	(DATEADD(DAY, FLOOR(RAND()*1096), '20190101'), RAND() * 1000);
	SET @i += 1;
END

SELECT * FROM Umsatz ORDER BY Datum;

SET STATISTICS TIME, IO OFF;

/*
	Pläne:
	Zeigen den Ablauf einer Abfrage an
	Aktivieren mit Include Actual Execution Plan (Strg + M)
	Wichtige Werte:
	- Estimated Operator Cost: Kosten des Teils der Abfrage
	- Number of Rows Read: Gelesene Zeilen -> reduzieren umd Performance zu erhöhen
*/

SELECT * FROM Umsatz WHERE YEAR(Datum) = 2019; --100000 Rows gelesen obwohl nur 33357 relevante Rows dabei sind

DBCC showcontig('Umsatz');

--Teiltabellen erstellen und Daten bewegen
CREATE TABLE Umsatz2019
(
	Datum date,
	Umsatz float
);

INSERT INTO Umsatz2019
SELECT * FROM Umsatz WHERE YEAR(Datum) = 2019;

CREATE TABLE Umsatz2020
(
	Datum date,
	Umsatz float
);

INSERT INTO Umsatz2020
SELECT * FROM Umsatz WHERE YEAR(Datum) = 2020;

CREATE TABLE Umsatz2021
(
	Datum date,
	Umsatz float
);

INSERT INTO Umsatz2021
SELECT * FROM Umsatz WHERE YEAR(Datum) = 2021;

DROP TABLE Umsatz;

--Indizierte Sicht
--View die über CHECK-Constraints nur auf die benötigten unterliegenden Tabellen zugreift

GO

CREATE VIEW UmsatzGesamt
AS
	SELECT * FROM Umsatz2019
	UNION ALL
	SELECT * FROM Umsatz2020
	UNION ALL
	SELECT * FROM Umsatz2021
GO

SELECT * FROM UmsatzGesamt WHERE YEAR(Datum) = 2019; --28% Scan auf alle Tabellen (bringt nix, 2019 kann nur in einer Tabelle sein)

--CHECK-Constraints
ALTER TABLE Umsatz2019 ADD CONSTRAINT CHK_Year2019 CHECK (YEAR(Datum) = 2019);
ALTER TABLE Umsatz2020 ADD CONSTRAINT CHK_Year2020 CHECK (YEAR(Datum) = 2020);
ALTER TABLE Umsatz2021 ADD CONSTRAINT CHK_Year2021 CHECK (YEAR(Datum) = 2021);

SELECT * FROM UmsatzGesamt WHERE YEAR(Datum) = 2019;