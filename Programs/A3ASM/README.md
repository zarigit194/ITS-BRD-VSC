# GTP Praktikumsaufgabe Woche 3 - Einfuehrung Assembler

## Abgegebene Dateien
- `Src/main.s` - Assembler-Programm main_w3.s mit Kommentaren zur Semantik
  jeder Anweisung (Kommentar jeweils VOR der Anweisung) und dokumentierter
  Untersuchung
- `GT_A3_Speicher.xlsx` - Speicherinhalt ab VariableA (0x2000000C),
  Variablen farbig markiert
- `GT_Aufgabe_Woche_3_formular.pdf` - ausgefuelltes Formular (Abschnitte 1-4)

## Stand der Bearbeitung
Alle Teilaufgaben wurden bearbeitet:
- [x] Projekt A3 angelegt, Programm uebersetzt und auf dem ITS-Board ausgefuehrt
- [x] Belegung von Hauptspeicher und Registern mit dem Debugger ermittelt
      (Registeransicht, Disassembly-View, GDB-Befehle x/... und p/x $xpsr)
- [x] Formular ausgefuellt
- [x] Semantik aller Anweisungen (Anw-01 bis Anw-26) als Kommentar beschrieben
- [x] Excel-Tabelle mit dem Speicherinhalt gefuellt
      (Zustand am Programmende, Aenderungen durch Anw-07 und Anw-15 vermerkt)

## Untersuchungen (siehe Kommentare in main.s)
- Anw-02: Assembler erzeugt `mvn.w r1,#127` statt `mov` (Disassembly-View)
- Anw-03: Literal-Pool-Adresse 0x08000230, CPU fuehrt `ldr r2,[pc,#56]` aus
- Anw-14: `ldrsh` statt `ldrh` getestet -> Sign Extension (R6 = 0xFFFFFFCC = -52)

## Nicht geloeste Aufgaben
Keine.