USE Demo;

--MAXDOP
--Maximum Degree of Parallelism
--Festlegen wie sehr eine Abfrage parallelisiert wird (wieviele Prozessorkerne werden für eine Abfrage verwendet)
--Datenbank parallelisiert von alleine

--MAXDOP konfigurierbar auf 3 Ebenen: Server, DB, Query
--Query > DB > Server

--ab einem Kostenschwellwert (Estimated Operator Cost) von 5 (standardmäßig) wird parallelisiert

SELECT freight, birthdate FROM KundenUmsatz WHERE freight > 1000;
--Im Plan sichtbar mit 2 schwarzen Pfeilen im gelben Kreis auf der Abfrage
--Number of Executions bei Abfragen rechts: Anzahl Kerne verwendet
--Bei SELECT ganz links: Anzahl Kerne gesamt verwendet (z.B. bei UNION)

SET STATISTICS time, io ON;

SELECT freight, birthdate
FROM KundenUmsatz
WHERE freight > 1000
OPTION (MAXDOP 8); --OPTION(MAXDOP <Anzahl>)
--MAXDOP 1: CPU-Zeit = 125 ms, verstrichene Zeit = 135 ms
--MAXDOP 2: CPU-Zeit = 187 ms, verstrichene Zeit = 116 ms
--MAXDOP 4: CPU-Zeit = 188 ms, verstrichene Zeit = 80 ms
--MAXDOP 8: CPU-Zeit = 237 ms, verstrichene Zeit = 112 ms

SELECT *, YEAR(OrderDate), CONCAT_WS(' ', FirstName, LastName)
FROM KundenUmsatz
WHERE Country IN(SELECT Country FROM KundenUmsatz WHERE Country LIKE 'A%');
--MAXDOP 8: CPU-Zeit = 1077 ms, verstrichene Zeit = 1397 ms

SELECT *, YEAR(OrderDate), CONCAT_WS(' ', FirstName, LastName)
FROM KundenUmsatz
WHERE Country IN(SELECT Country FROM KundenUmsatz WHERE Country LIKE 'A%')
OPTION(MAXDOP 4);
--MAXDOP 4: CPU-Zeit = 1188 ms, verstrichene Zeit = 1377 ms

SELECT *, YEAR(OrderDate), CONCAT_WS(' ', FirstName, LastName)
FROM KundenUmsatz
WHERE Country IN(SELECT Country FROM KundenUmsatz WHERE Country LIKE 'A%')
OPTION(MAXDOP 2);
--MAXDOP 2: CPU-Zeit = 1312 ms, verstrichene Zeit = 2047 ms

SELECT *, YEAR(OrderDate), CONCAT_WS(' ', FirstName, LastName)
FROM KundenUmsatz
WHERE Country IN(SELECT Country FROM KundenUmsatz WHERE Country LIKE 'A%')
OPTION(MAXDOP 1);
--MAXDOP 1: CPU-Zeit = 875 ms, verstrichene Zeit = 1369 ms