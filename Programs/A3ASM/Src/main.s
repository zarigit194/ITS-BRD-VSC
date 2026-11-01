;************************************************
;* Beginn der globalen Daten *
;************************************************
                   AREA MyData, DATA, align = 2
Base
VariableA          DCW 0x1234
VariableB          DCW 0x4711

VariableC          DCD  0

MeinHalbwortFeld   DCW 0x22 , 0x3e , -52, 78 , 0x27 , 0x45

MeinWortFeld       DCD 0x12345678 , 0x9dca5986
                   DCD -872415232 , 1308622848
                   DCD 0x27000000
                   DCD 0x45000000

MeinTextFeld       DCB "ABab0123",0

                   EXPORT VariableA
                   EXPORT VariableB
                   EXPORT VariableC
                   EXPORT MeinHalbwortFeld
                   EXPORT MeinWortFeld
                   EXPORT MeinTextFeld

;***********************************************
;* Beginn des Programms *
;************************************************
    AREA |.text|, CODE, READONLY, ALIGN = 3
; ----- S t a r t des Hauptprogramms -----
                EXPORT main
                EXTERN initITSboard
main            PROC
                bl    initITSboard                 ; HW Initialisieren

; Laden von Konstanten in Register
; Anw-01: mov r0,#0x12 -> laedt die kleine Konstante 0x12 (= 18) in R0.
;   Kleine Konstanten passen direkt in das Maschinenwort des Befehls,
;   kein zusaetzlicher Speicherplatz noetig.
;   Disassembly: mov.w r0,#18 -> R0 = 0x00000012
                mov   r0,#0x12                      ; Anw-01
; Anw-02: mov r1,#-128 -> laedt -128 in R1.
;   Negative Zahlen werden im Zweierkomplement gespeichert:
;   128 = 0x00000080 -> invertieren 0xFFFFFF7F -> +1 = 0xFFFFFF80
;   R1 = 0xFFFFFF80
;   Untersuchung im Disassembly: der Assembler erzeugt mvn.w r1,#127
;   (mvn = move NOT: bitweise Invertierung von 0x7F = 0xFFFFFF80),
;   weil 0xFFFFFF80 nicht direkt als mov-Konstante kodierbar ist.
                mov   r1,#-128                      ; Anw-02
; Anw-03: ldr r2,=0x12345678 ist ein Pseudo-Befehl (Gleichheitszeichen).
;   Ein Befehl hat nur 16 oder 32 Bit, die Konstante allein braucht schon
;   32 Bit -> sie passt nicht in den Befehl.
;   Der Assembler legt die Konstante hinter dem Programmcode im
;   Literal-Pool ab (Adresse 0x08000230) und erzeugt stattdessen:
;       ldr r2,[pc,#56]   (laut Disassembly-View)
;   Rechnung: Befehl bei 0x080001F4, PC = Befehlsadresse + 4 = 0x080001F8,
;   0x080001F8 + 56 (0x38) = 0x08000230
;   Ergebnis: R2 = 0x12345678
                ldr   r2,=0x12345678                ; Anw-03

; Zugriff auf Variable
; Anw-04: Pseudo-Befehl: laedt die ADRESSE von VariableA in R0, nicht den
;   Wert! R0 = 0x2000000C (Variablen liegen im RAM ab 0x20000000).
;   Auf Variablen kann man nicht direkt zugreifen: erst die Adresse in ein
;   Register laden, dann ueber das Register lesen/schreiben.
;   Die Adresse liegt im Literal-Pool bei 0x08000234,
;   die CPU fuehrt aus: ldr r0,[pc,#60]
               ldr   r0,=VariableA                 ; Anw-04
; Anw-05: ldrh r1,[r0] -> laedt ein Halbwort (h = 16 Bit) von der Adresse,
;   die in R0 steht (0x2000000C). Die oberen 16 Bit werden mit 0 gefuellt.
;   Speicher: 34 12 (Little Endian) -> R1 = 0x00001234 = Wert von VariableA
;   Geladene Bits: 16
                ldrh  r1,[r0]                       ; Anw-05
; Anw-06: ldr r2,[r0] -> laedt 32 Bit (ein Wort) von Adresse 0x2000000C.
;   VariableA ist aber nur 16 Bit gross! Der Assembler prueft NICHT, ob
;   der Lade-/Speicherbefehl zur Variablengroesse passt.
;   Es werden 4 Bytes gelesen: 34 12 (VariableA) und 11 47 (VariableB).
;   Little Endian (niederwertigstes Byte an der kleinsten Adresse):
;   R2 = 0x47111234
                ldr   r2,[r0]                       ; Anw-06
; Anw-07: str r2,[r0,#VariableC-VariableA] -> SPEICHERN von 32 Bit aus R2.
;   Die Adresse wird als Differenz zu einer Basis angegeben:
;   VariableC - VariableA = 4 (berechnet der Assembler beim Uebersetzen),
;   im Disassembly steht daher: str r2,[r0,#4]
;   Zieladresse = R0 + 4 = 0x2000000C + 4 = 0x20000010 = VariableC
;   VariableC war 0 und ist danach 0x47111234 (32 Bit gespeichert).
;   Kontrolle im Debugger: x/1xw 0x20000010 -> 0x47111234
                str   r2,[r0,#VariableC-VariableA]  ; Anw-07

; Zugriff auf Felder (Speicherzellen)
; Anw-08: Pseudo-Befehl: laedt die Anfangsadresse von MeinHalbwortFeld
;   in R0 (R0 = 0x20000014). Ab hier wird R0 als Basisadresse fuer den
;   Zugriff auf die Feldelemente benutzt.
;   Feld: 6 Elemente, je 2 Byte (DCW) -> belegt 0x20000014 bis 0x2000001F
;   Element:  0      1      2      3      4      5
;   Adresse:  ..14   ..16   ..18   ..1A   ..1C   ..1E
;   Wert:     0x22   0x3E   -52    78     0x27   0x45
                ldr   r0,=MeinHalbwortFeld          ; Anw-08
; Anw-09: ldrh r1,[r0] -> laedt ein Halbwort (16 Bit) von der Adresse in R0
;   = Element 0 von MeinHalbwortFeld -> R1 = 0x00000022
;   Speicher (Little Endian): 22 00
                ldrh  r1,[r0]                       ; Anw-09
; Anw-10: ldrh r2,[r0,#2] -> laedt Halbwort von Adresse R0 + 2 = 0x20000016.
;   Jedes Element ist 2 Byte gross, also +2 = Element 1 -> R2 = 0x0000003E
;   R0 bleibt UNVERAENDERT (kein !), die +2 gelten nur fuer diesen Zugriff.
                ldrh  r2,[r0,#2]                    ; Anw-10
; Anw-11: mov r3,#10 -> laedt die Konstante 10 (dezimal = 0xA) in R3.
;   R3 dient in Anw-12 als Adressdifferenz in Bytes (Offset).
                mov   r3,#10                        ; Anw-11
; Anw-12: ldrh r4,[r0,r3] -> laedt Halbwort von Adresse R0 + R3.
;   Die Adressdifferenz steht hier in einem REGISTER statt als Konstante
;   und kann daher waehrend des Programmlaufs veraendert werden
;   (z.B. in einer Schleife).
;   Adresse = 0x20000014 + 10 = 0x2000001E
;   10 Bytes / 2 Bytes pro Element = Element 5 -> R4 = 0x00000045
                ldrh  r4,[r0,r3]                    ; Anw-12

; Anw-13: ldrh r5,[r0,#2]! -> Pre-Index mit Writeback (Ausrufezeichen !):
;   1. zuerst wird die Adresse berechnet UND in R0 gespeichert:
;      R0 = R0 + 2 = 0x20000014 + 2 = 0x20000016
;   2. dann wird von dieser neuen Adresse ein Halbwort geladen
;   -> R5 = Element 1 = 0x0000003E
;   Unterschied zu Anw-10: ohne ! bleibt R0 gleich, mit ! wird R0
;   veraendert. So kann man ein Feld Element fuer Element durchlaufen.
                ldrh  r5,[r0,#2]!                   ; Anw-13
; ---------------------------------------------------------------------
; UNTERSUCHUNG zu Anw-14: Was passiert mit ldrsh statt ldrh?
;   Frage: Element 2 ist im Code als -52 definiert, ldrh liefert aber
;          R6 = 0x0000FFCC = 65484. Wie bekommt man -52 ins Register?
;   Codeaenderung (temporaer): ldrh r6,[r0,#2]!  ->  ldrsh r6,[r0,#2]!
;   Beobachtung im Debugger:
;     ldrh  -> R6 = 0x0000FFCC = 65484 (obere 16 Bit mit 0 gefuellt)
;     ldrsh -> R6 = 0xFFFFFFCC = -52   (obere 16 Bit mit Bit 15 gefuellt)
;   Erklaerung: ldrsh = load register signed halfword. Das Vorzeichenbit
;     (Bit 15 = 1) wird auf die Bits 16-31 kopiert (Sign Extension).
;     So bleibt der Wert -52 auch im 32-Bit-Register korrekt.
;   Fazit: Fuer signed Halbwoerter ldrsh verwenden, fuer unsigned ldrh.
;   Danach wieder auf ldrh zurueckgestellt (Originalprogramm).
; ---------------------------------------------------------------------
; Anw-14: ldrh r6,[r0,#2]! -> wie Anw-13, ein Element weiter:
;   1. R0 = R0 + 2 = 0x20000018
;   2. Halbwort laden -> Element 2 = -52 = 0xFFCC (16 Bit Zweierkomplement)
;   R6 = 0x0000FFCC = 65484, NICHT -52!
;   Grund: ldrh laedt unsigned und fuellt die oberen 16 Bit mit Nullen.
;   Fuer vorzeichenrichtiges Laden muesste man ldrsh verwenden
;   (sign extension) -> R6 waere dann 0xFFFFFFCC = -52.
                ldrh  r6,[r0,#2]!                   ; Anw-14
; Anw-15: strh r6,[r0,#2]! -> SPEICHERN (str) eines Halbworts (h = 16 Bit)
;   mit Pre-Index und Writeback (!):
;   1. zuerst R0 = R0 + 2 = 0x2000001A
;   2. dann die unteren 16 Bit von R6 (0xFFCC) an diese Adresse schreiben
;   0x2000001A ist Element 3 von MeinHalbwortFeld (vorher 78 = 0x004E).
;   Element 3 wird mit 0xFFCC (-52) ueberschrieben, also mit dem Wert
;   von Element 2 -> Element 2 wurde nach Element 3 kopiert.
;   Kontrolle im Debugger: x/6xh 0x20000014
;   -> 0x0022 0x003e 0xffcc 0xffcc 0x0027 0x0045
                strh  r6,[r0,#2]!                   ; Anw-15

; Addition und Subtraktion von unsigned / signed Integer-Werten
; Anw-16: Pseudo-Befehl: laedt die ADRESSE von MeinWortFeld in R0
;   (R0 = 0x20000020), nicht den Inhalt. Die 32-Bit-Adresse passt nicht in
;   den Befehl -> der Assembler legt sie im Literal-Pool ab und erzeugt
;   ldr r0,[pc,#offset].
                ldr  r0,=MeinWortFeld               ; Anw-16
; Anw-17: ldr r1,[r0] -> laedt 32 Bit (ein Wort) von der Adresse in R0,
;   also Element 0 von MeinWortFeld -> R1 = 0x12345678.
;   Im Speicher steht es als Little Endian: 78 56 34 12
                ldr  r1,[r0]                        ; Anw-17
; Anw-18: ldr r2,[r0,#4] -> laedt 32 Bit von Adresse R0+4 = 0x20000024.
;   Jedes Element ist 4 Byte gross, also +4 = Element 1 -> R2 = 0x9DCA5986
;   (signed = -1647683194, unsigned = 2647284102)
                ldr  r2,[r0,#4]                     ; Anw-18
; Anw-19: adds r3,r1,r2 -> R3 = R1 + R2; das "s" setzt die Flags.
;   0x12345678 + 0x9DCA5986 = 0xAFFEAFFE
;   Flags: N=1 (Bit 31 = 1), Z=0, C=0, V=0  (xPSR = 0x81000000)
;   signed:   305419896 + (-1647683194) = -1342263298 -> OK
;             (positiv + negativ kann nie ueberlaufen -> V=0)
;   unsigned: 305419896 + 2647284102 = 2952703998 -> OK
;             (kein Uebertrag ueber Bit 31 hinaus -> C=0)
;   Merke: Die CPU rechnet fuer signed und unsigned mit DENSELBEN Bits.
;   Nur die Interpretation ist anders: signed -> V pruefen, unsigned -> C.
                adds r3,r1,r2                       ; Anw-19

; Anw-20: ldr r4,[r0,#8] -> Adresse R0+8 = 0x20000028, 8/4 = Element 2
;   R4 = 0xCC000000. Im Code als -872415232 definiert (signed);
;   unsigned interpretiert = 3422552064, da Bit 31 = 1.
                ldr  r4,[r0,#8]                     ; Anw-20
; Anw-21: ldr r5,[r0,#12] -> Adresse R0+12 = 0x2000002C, 12/4 = Element 3
;   R5 = 0x4E000000 = 1308622848 (signed = unsigned, da Bit 31 = 0)
                ldr  r5,[r0,#12]                    ; Anw-21
; Anw-22: subs r6,r4,r5 -> R6 = R4 - R5; das "s" setzt die Flags.
;   0xCC000000 - 0x4E000000 = 0x7E000000
;   Flags: N=0, Z=0, C=1, V=1  (xPSR = 0x31000000)
;   signed:   -872415232 - 1308622848 = -2181038080. Das ist kleiner als
;             -2147483648 (kleinste 32-Bit signed Zahl) -> Ueberlauf, V=1.
;             Register zeigt +2113929216 (negativ minus positiv ergibt
;             positiv -> unmoeglich) -> NICHT OK.
;   unsigned: 3422552064 - 1308622848 = 2113929216, kein Borrow (C=1)
;             -> OK.
                subs r6,r4,r5                       ; Anw-22

; Anw-23: ldr r7,[r0,#16] -> laedt 32 Bit von Adresse R0+16 = 0x20000030.
;   16 Bytes / 4 Bytes pro Element = Element 4 -> R7 = 0x27000000
                ldr  r7,[r0,#16]                    ; Anw-23
; Anw-24: ldr r8,[r0,#20] -> laedt 32 Bit von Adresse R0+20 = 0x20000034.
;   20 Bytes / 4 Bytes pro Element = Element 5 -> R8 = 0x45000000
                ldr  r8,[r0,#20]                    ; Anw-24
; Anw-25: subs r9,r7,r8 -> R9 = R7 - R8; das "s" setzt die Flags N,Z,C,V.
;   0x27000000 - 0x45000000 = 0xE2000000
;   Flags: N=1 (Bit 31 = 1), Z=0, C=0, V=0  (xPSR = 0x81000000)
;   signed:   654311424 - 1157627904 = -503316480 -> OK (V=0)
;   unsigned: kleine Zahl - grosse Zahl waere negativ; unsigned kann das
;             nicht darstellen -> Borrow (C=0). Register zeigt 3791650816
;             -> NICHT OK.
;   Merke: Bei Subtraktion auf ARM bedeutet C=1 "kein Borrow" (unsigned OK),
;          C=0 bedeutet "Borrow" (unsigned Ergebnis falsch).
                subs r9,r7,r8                       ; Anw-25

; Anw-26: b forever = unbedingter Sprung (branch) zum Label "forever",
;   also zu sich selbst -> Endlosschleife.
;   Grund: Auf dem Mikrocontroller gibt es kein Betriebssystem, zu dem
;   main zurueckkehren koennte. Ohne die Schleife wuerde die CPU den
;   Speicher hinter dem Programm als Befehle ausfuehren.
forever         b   forever                         ; Anw-26
                ENDP
                END