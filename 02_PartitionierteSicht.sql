CREATE TABLE Umsatz2019
(
	ID int identity primary key,
	Datum date,
	Umsatz float,
	Jahr smallint
	CONSTRAINT CHK_Year2019 CHECK (Jahr=2019)
);

INSERT INTO Umsatz2019
SELECT *, 2019 FROM Umsatz WHERE YEAR(Datum) = 2019;

CREATE TABLE Umsatz2020
(
	ID int identity primary key,
	Datum date,
	Umsatz float,
	Jahr smallint
	CONSTRAINT CHK_Year2020 CHECK (Jahr=2020)
);

INSERT INTO Umsatz2020
SELECT *, 2020 FROM Umsatz WHERE YEAR(Datum) = 2020;

CREATE TABLE Umsatz2021
(
	ID int identity primary key,
	Datum date,
	Umsatz float,
	Jahr smallint
	CONSTRAINT CHK_Year2021 CHECK (Jahr=2021)
);

INSERT INTO Umsatz2021
SELECT *, 2021 FROM Umsatz WHERE YEAR(Datum) = 2021;

--Indizierte Sicht
--View die über CHECK-Constraints nur auf die benötigten unterliegenden Tabellen zugreift

CREATE VIEW UmsatzGesamt
AS
	SELECT * FROM Umsatz2019
	UNION ALL --UNION filtert Duplikate, UNION ALL filtert keine Duplikate
	SELECT * FROM Umsatz2020
	UNION ALL
	SELECT * FROM Umsatz2021
GO

SELECT * FROM UmsatzGesamt WHERE Jahr = 2020;
SELECT * FROM UmsatzGesamt WHERE Jahr = 2020 OR Jahr = 2021;

INSERT INTO UmsatzGesamt VALUES
('20210101', 111, 2021);