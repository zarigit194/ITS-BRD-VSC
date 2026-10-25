# Aufgabe 2 – Konstanten, Variablen und Operationen auf Daten

## Effekte der Zeilen Anw01 – Anw06

Speicher ab `&VariableA` (0x2000000C) zu Beginn: `EF BE 34 12`
(Little-Endian: das niederwertige Byte 0xEF steht auf der kleineren Adresse.)

| Zeile | Befehl | R0 | R2 | R3 | Speicher ab VariableA |
|---|---|---|---|---|---|
| Anw01 | `ldr R0,=VariableA` | 0x2000000C | – | – | EF BE 34 12 |
| Anw02 | `ldrb R2,[R0]` | 0x2000000C | 0x000000EF | – | EF BE 34 12 |
| Anw03 | `ldrb R3,[R0,#1]` | 0x2000000C | 0x000000EF | 0x000000BE | EF BE 34 12 |
| Anw04 | `lsl R2,#8` | 0x2000000C | 0x0000EF00 | 0x000000BE | EF BE 34 12 |
| Anw05 | `orr R2,R3` | 0x2000000C | 0x0000EFBE | 0x000000BE | EF BE 34 12 |
| Anw06 | `strh R2,[R0]` | 0x2000000C | 0x0000EFBE | 0x000000BE | **BE EF** 34 12 |

Die Zeilen tauschen die beiden Bytes von VariableA. Vorher steht
`EF BE` im Speicher (echter Wert 0xBEEF), danach `BE EF` –
"beef" ist lesbar, der echte Wert ist aber jetzt 0xEFBE.

## Unterschied LDR und MOV

- `MOV` schreibt einen Wert (Konstante oder Register) direkt in ein
  Register, ohne Speicherzugriff.
- `LDR` lädt einen Wert aus dem Speicher in ein Register.
  `ldr R0,=VariableA` lädt die Adresse von VariableA.

## Erweiterung VariableC ("affe")

Neue Variable: `VariableC DCW 0x0000` (Adresse 0x20000010).
R5 = 0xAFFE wird mit `strh` nach VariableC geschrieben (Speicher: `FE AF`)
und danach wie bei "beef" mit `ldrb`, `lsl`, `orr`, `strh` getauscht.

Ergebnis im Speicher: `AF FE` – 0xAF auf der kleineren Adresse,
0xFE auf der höheren Adresse. Der echte Wert ist 0xFEAF.

## Änderung ab Anw09 ("1234")

Vorher: 0x1234 + 0x30ED = 0x4321, im Speicher `21 43`.

Damit im Speicher `12 34` steht, muss der echte Wert 0x3412 sein
(Little-Endian). Einfachste Lösung: nur in Anw0B die Konstante ändern:
0x3412 - 0x1234 = 0x21DE, also `mov R7, #0x21DE`.

Ergebnis: 0x1234 + 0x21DE = 0x3412, im Speicher `12 34`.

## Probleme

- Das Skript `createNewProjectASM.bat` hat automatisch "ASM" an den
  Projektnamen angehängt (`A2ASM`). Der Ordner wurde manuell in `A2`
  umbenannt.
- Das Skript muss aus dem Ordner `bin` gestartet werden, sonst wird
  `createGenericProject.ps1` nicht gefunden.
- Die aktive Solution war noch `Aufgabe1ASM`; sie musste über
  CMSIS → "Open Solution in Workspace" auf A2 umgestellt werden.