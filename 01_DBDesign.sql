/*
	Normalerweise:
	1. Jede Zelle sollte genau einen Wert haben
	2. Jeder Datensatz sollte einen Primärschlüssel haben
	3. Keine Beziehungen zwischen nicht Schlüssel-Spalten

	Redundanz verringern (Daten nicht doppelt speichern)
	- Beziehungen zwischen Tabellen
	PK -- Beziehung -- FK

	Kundentabelle: 1 Mio. DS
	Bestellungen: 100 Mio. DS
	Bestellungen -> Beziehung -> Kunden
*/

