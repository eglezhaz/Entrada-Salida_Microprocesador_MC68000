
        ORG     $1000              *Dirección de inicio del programa

START:
        JSR     INIT               *Llamamos a la subrutina de inicialización

BUCLE:
        BRA     BUCLE              *Bucle infinito para mantener el programa activo


*Subrutina INIT – inicializa buffers, DUART e interrupciones

INIT:
        JSR     INI_BUFS           *Inicializa punteros de buffers (de bib_aux.s)

       *Configuración del canal A (entrada)
        MOVE.B  #$13,MR1A
        MOVE.B  #$07,MR2A
        MOVE.B  #$05,CRA

       *Configuración del canal B (salida)
        MOVE.B  #$13,MR1B
        MOVE.B  #$07,MR2B
        MOVE.B  #$05,CRB

       *Configuración de reloj
        MOVE.B  #$88,ACR

       *Vector de interrupción
        MOVE.B  #$50,IVR

       *Habilitación de interrupciones RXA y TXB
        MOVE.B  #$05,IMR

       *Asociamos el vector #50 a la rutina RTI
        LEA     RTI,A0
        MOVE.L  A0,$0140

        RTS


PRINT:
        MOVEM.L D0-D1/A0,-(A7)       * Guardamos registros usados

PRINT_LOOP:
         MOVE.B  (A0)+,D1            * Tomamos el siguiente carácter
         CMPI.B  #0,D1               * ¿Es el final de la cadena?
         BEQ     FIN_PRINT           * Si sí, salimos

         MOVE.L  #.PRNT_B,D0         * Buffer de salida canal B
         JSR     ESCCAR              * Insertamos el carácter

         BRA     PRINT_LOOP          * Repetimos con el siguiente

FIN_PRINT:
        MOVEM.L (A7)+,D0-D1/A0       * Restauramos registros
        RTS


SCAN:
        MOVEM.L D0-D1/A0,-(A7)      * Guardamos registros usados

SCAN_LOOP:
         MOVE.L  #.SCAN_A,D0        * Seleccionamos el buffer de entrada A
         JSR     LEECAR             * Intentamos sacar un carácter
         CMPI.L  #-1,D0
         BEQ     SCAN_LOOP          * Si buffer vacío, seguimos esperando

         CMPI.B  #10,D0             * ¿Es salto de línea (LF)?
         BEQ     FIN_SCAN           * Si sí, terminamos

         MOVE.B  D0,(A0)+           * Guardamos el carácter leído en la cadena
         BRA     SCAN_LOOP          * Seguimos leyendo

FIN_SCAN:
         MOVE.B  #0,(A0)            * Terminamos la cadena con 0 (nulo)
         MOVEM.L (A7)+,D0-D1/A0
         RTS



RTI:
        MOVEM.L D0-D1/A0,-(A7)     * Guardamos registros usados

         MOVE.B  SRA,D0
         ANDI.B  #1,D0
         BEQ     SIGUIENTE

         MOVE.B  RXA,D1
         MOVE.L  #.SCAN_A,D0
         JSR     ESCCAR

SIGUIENTE:
         MOVE.B  SRB,D0
         ANDI.B  #4,D0
         BEQ     FINRTI

         MOVE.L  #.PRNT_B,D0
         JSR     LEECAR
         CMPI.L  #-1,D0
         BEQ     FINRTI

         MOVE.B  D0,TXB

FINRTI:
        MOVEM.L (A7)+,D0-D1/A0
        RTE

*Tabla de etiquetas DUART

DUART_BASE   EQU     $EFFC00

MR1A         EQU     DUART_BASE + $00
SRA          EQU     DUART_BASE + $01
RXA          EQU     DUART_BASE + $02
TXA          EQU     DUART_BASE + $03
CRA          EQU     DUART_BASE + $03
MR2A         EQU     DUART_BASE + $04

MR1B         EQU     DUART_BASE + $08
SRB          EQU     DUART_BASE + $09
RXB          EQU     DUART_BASE + $0A
TXB          EQU     DUART_BASE + $0B
CRB          EQU     DUART_BASE + $0B
MR2B         EQU     DUART_BASE + $0C

ACR          EQU     DUART_BASE + $10
IMR          EQU     DUART_BASE + $0F
IVR          EQU     DUART_BASE + $13


       INCLUDE bib_aux.s



