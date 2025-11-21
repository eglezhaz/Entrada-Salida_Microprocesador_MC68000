*Inicializa el SP y el PC
**************************
        ORG     $0
        DC.L    $8000           * Pila
*        DC.L    INICIO          * PC

        ORG     $400

* Definici�n de equivalencias
*********************************

MR1A    EQU     $effc01       * de modo A (escritura)
MR2A    EQU     $effc01       * de modo A (2� escritura)
SRA     EQU     $effc03       * de estado A (lectura)
CSRA    EQU     $effc03       * de seleccion de reloj A (escritura)
CRA     EQU     $effc05       * de control A (escritura)
TBA     EQU     $effc07       * buffer transmision A (escritura)
RBA     EQU     $effc07       * buffer recepcion A  (lectura)
ACR     EQU     $effc09       * de control auxiliar
IMR     EQU     $effc0B       * de mascara de interrupcion A (escritura)
ISR     EQU     $effc0B       * de estado de interrupcion A (lectura)
MR1B    EQU     $effc11       * de modo B (escritura)
MR2B    EQU     $effc11       * de modo B (2� escritura)
CRB     EQU     $effc15       * de control A (escritura)
TBB     EQU     $effc17       * buffer transmision B (escritura)
RBB     EQU     $effc17       * buffer recepcion B (lectura)
SRB     EQU     $effc13       * de estado B (lectura)
CSRB    EQU     $effc13       * de seleccion de reloj B (escritura)

*RXA     EQU     $effc03
*TXB     EQU     $effc09

CR      EQU     $0D           * Carriage Return
LF      EQU     $0A           * Line Feed
FLAGT   EQU     2             * Flag de transmisi�n
FLAGR   EQU     0             * Flag de recepci�n
*FLAGR_B   EQU 4           * Bit de RXRDY B (bit 4)
*FLAGT_B   EQU 5           * Bit de TXRDY B (bit 5)


*IVR     EQU     $EFFC0B
IVR     EQU     $EFFC19

IMRCOPIA:  DC.B    0
EVEN 	DS.W	1 



**************************** INIT *************************************************************
       * ORG $1400
INIT:
        * ---- Reinicio MR1 en canal A ----
        MOVE.B  #%00010000,CRA            * Reset puntero de modo A
        MOVE.B  #%00000011,MR1A           * 8 bits, sin paridad
        MOVE.B  #%00000000,MR2A           * Sin bits de parada extra, eco desactivado

        * ---- Reinicio MR1 en canal B ----
        MOVE.B  #%00010000,CRB
        MOVE.B  #%00000011,MR1B
        MOVE.B  #%00000000,MR2B

        * ---- Velocidad y reloj (ambos canales) ----
        MOVE.B  #%00000000,ACR            * Fuente de reloj = cristal
        MOVE.B  #%11001100,CSRA           * Velocidad 38400 bps en canal A
        MOVE.B  #%11001100,CSRB           * Velocidad 38400 bps en canal B

        * ---- Habilitar recepción y transmisión ----
        MOVE.B  #%00010101,CRA            * RX y TX activados en canal A
        MOVE.B  #%00010101,CRB            * RX y TX activados en canal B

        * ---- Vector de interrupción nivel 4 ----
        MOVE.B  #%01000000,IVR            * Vector 0x40 (puede usar 0x50 si lo prefieres)
        LEA     RTI,A0                    * Dirección de la rutina RTI
        MOVE.L  A0,$0100                  * Asociar vector a rutina

        * ---- Interrupciones permitidas inicialmente ----
        * Solo habilitamos RX de A y B por ahora
        MOVE.B  #%00100010,IMRCOPIA       * RXA = bit 0, RXB = bit 4
        MOVE.B  IMRCOPIA,IMR              * Aplicamos máscara en DUART

        * ---- Inicializar buffers circulares ----
        BSR     INI_BUFS

        RTS

**************************** PRINT ************************************************************


PRINT: 	LINK  	A6,#-4                 * Crear el marco de pila 

   	MOVEM.L A0-A5/D1-D7,-(A7) 
       	MOVE.L 	8(A6),A0         * Buffer en A0
       	MOVE.L 	#0,D1
       	MOVE.W 	12(A6),D1        * Descriptor en D1
       	MOVE.L 	#0,D2
       	MOVE.W 	14(A6),D2        * Tamaño en D2

	MOVE.L 	#0,D6		*contador
	
       	CMP.W  	#0,D2                    * si el tamaño es 0 terminamos
       	BEQ    	PRINT_FIN
       	CMP.W  	#0,D1            * vemos el desciptor
       	BEQ 	PRINT_LOOP_A         * Linea A
       	CMP.W 	#1,D1
       	BEQ  	PR_LOOP_B         * Linea B
                        
	MOVE.L	#-1,D0    * en otro caso, D0 = -1
       	BRA   	PRINT_FIN


PRINT_ERROR:
        MOVE.L #-1,D0
        BRA PRINT_FIN

* ============================
* Bucle para canal A
* ============================
PRINT_LOOP_A:
        TST.W D2
        BEQ ACTIVA_TXA

PRINT_NEXT_A:
        MOVE.B (A0)+,D3
        MOVE.L #2,D4
        MOVE.B D3,D5
        MOVE.L D5,D5
        MOVE.L D4,D0
        MOVE.L D5,D1
        BSR ESCCAR

        CMP.L #-1,D0
        BEQ ACTIVA_TXA

        ADDQ.L #1,D6
        SUBQ.W #1,D2
        BNE PRINT_NEXT_A

ACTIVA_TXA:
        CMP.L #0,D6
        BEQ PRINT_FIN

        MOVE.B IMRCOPIA,D7
        BSET #0,D7
        MOVE.B D7,IMRCOPIA
        MOVE.B D7,IMR
        BRA PRINT_FIN

* ============================
* Bucle para canal B
* ============================
PR_LOOP_B:
        TST.W D2
        BEQ ACT_TXB

PR_NEXT_B:
        MOVE.B (A0)+,D3
        MOVE.L #3,D4
        MOVE.B D3,D5
        MOVE.L D5,D5
        MOVE.L D4,D0
        MOVE.L D5,D1
        BSR ESCCAR

        CMP.L #-1,D0
        BEQ ACT_TXB

        ADDQ.L #1,D6
        SUBQ.W #1,D2
        BNE PR_NEXT_B

ACT_TXB:
        CMP.L #0,D6
        BEQ PRINT_FIN

        MOVE.B IMRCOPIA,D7
        BSET #4,D7
        MOVE.B D7,IMRCOPIA
        MOVE.B D7,IMR

PRINT_FIN:
        MOVE.L D6,D0                        * Resultado: caracteres insertados
        MOVEM.L (A7)+,A0-A5/D1-D7
        UNLK A6
        RTS



 **************************** SCAN ****************************



SCAN            LINK     A6,#-4           

	     MOVEM.L A0-A5/D1-D7,-(A7)

	                MOVE.L   8(A6),A1         * A1 contiene el tamaño del buffer
                        MOVE.L   #0,D3
                        MOVE.W   12(A6),D3        * D3, 0 o 1 para el descriptor
                        MOVE.L   #0,D4
                        MOVE.W   14(A6),D4        * D4 tamaño maximo a escanear

			MOVE.L	#0,D6		* num de caracteres escaneados
                        
			CMP.W    #0,D4                    * si tam 0 vamos al final  
                        BEQ      SCAN_FIN
                        CMP.W    #0,D3            
                        BEQ      SCAN_LOOP_A             * linea A
                        CMP.W    #1,D3
                        BEQ      SC_LOOP_B             * linea B
                        MOVE.L   #-1,D0    * ERROR no entro en A ni en B
                        BRA      SCAN_ERROR

SCAN_ERROR:
        MOVE.L  #-1,D0               * Descriptor inválido
        BRA     SCAN_FIN

SCAN_LOOP_A:
        TST.L   D4
        BEQ     SET_RESULT

SCAN_NEXT_A:
        MOVE.L  #0,D0                * D0 = 0 → identificador buffer A (entrada)
        BSR     LEECAR              * Leer carácter del buffer circular (D0 = char o -1)
        CMP.L   #-1,D0
        BEQ     SET_RESULT         * Si buffer vacío, esperar (loop hasta que llegue algo)
        MOVE.B  D0,(A1)+            * Volcar carácter leído al buffer de usuario
        ADDQ.L  #1,D6
        SUBQ.L  #1,D4
        BNE     SCAN_NEXT_A         * Repetir mientras queden caracteres por leer
        BRA     SET_RESULT

SC_LOOP_B:
        TST.L   D4
        BEQ     SET_RESULT

SC_NEXT_B:
        MOVE.L  #1,D0                * D0 = 1 → identificador buffer B (entrada)
        BSR     LEECAR
        CMP.L   #-1,D0
        BEQ     SET_RESULT
        MOVE.B  D0,(A1)+
        ADDQ.L  #1,D6
        SUBQ.L  #1,D4
        BNE     SC_NEXT_B
	BRA 	SET_RESULT

SET_RESULT:
        MOVE.L  D6,D0                * D0 ← número total de caracteres leídos

SCAN_FIN:
        MOVEM.L (A7)+,D1-D6/A0-A1
        UNLK    A6
        RTS






**************************** RTI ***********************************************************
       * ORG     $4400

RTI:    MOVEM.L D0-D2/D7/A0-A4,-(A7)    * Salvar registros usados (D0-D2, D7, A0-A4)

RTI_LOOP:
        MOVE.B  ISR,D0                 * Leer registro de estado de interrupción
        AND.B   IMRCOPIA,D0            * Filtrar solo las interrupciones habilitadas

        * --- Recepción por línea A (bit 1) ---
        BTST    #1,D0
        BNE     RXA_HANDLER

        * --- Recepción por línea B (bit 5) ---
        BTST    #5,D0
        BNE     RXB_HANDLER

        * --- Transmisión por línea A (bit 0) ---
        BTST    #0,D0
        BNE     TXA_HANDLER

        * --- Transmisión por línea B (bit 4) ---
        BTST    #4,D0
        BNE     TXB_HANDLER

        BRA     RTI_END               * Si no hay ninguna IRQ pendiente, finalizar

* --- RECEPCIÓN A ---
RXA_HANDLER:
        MOVE.B  RBA,D1               * Leer carácter recibido en A
        MOVE.L  #0,D0                * D0 = 0 → identificador de buffer A (entrada)
        JSR     ESCCAR               * Procesar/almacenar carácter en buffer circular
        CMP.L   #-1,D0
        BNE     RTI_LOOP             * Si éxito (carácter almacenado), volver a comprobar más IRQs

        * Buffer de entrada lleno: descartar carácter leyendo de nuevo
        MOVE.B  RBA,D2               * Leer nuevamente de RBA para limpiar la interrupción
        BRA     RTI_LOOP

* --- RECEPCIÓN B ---
RXB_HANDLER:
        MOVE.B  RBB,D1
        MOVE.L  #1,D0                * D0 = 1 → buffer B (entrada)
        JSR     ESCCAR
        CMP.L   #-1,D0
        BNE     RTI_LOOP

        MOVE.B  RBB,D2               * Leer nuevamente de RBB para limpiar la interrupción
        BRA     RTI_LOOP

* --- TRANSMISIÓN A ---
TXA_HANDLER:
        MOVE.L  #2,D0                * D0 = 2 → buffer A (salida)
        JSR     LEECAR              * Obtener siguiente carácter a enviar (o -1 si vacío)
        CMP.L   #-1,D0
        BEQ     DESACTIVAR_TXA      * Si no hay caracter (-1), desactivar interrupción TXA

        MOVE.B  D0,TBA              * Enviar siguiente carácter por canal A
        BRA     RTI_LOOP

DESACTIVAR_TXA:
        MOVE.B  IMRCOPIA,D1
        BCLR    #0,D1               * Desactivar bit 0 (TXRDY A) en copia de máscara
        MOVE.B  D1,IMRCOPIA
        MOVE.B  D1,IMR              * Actualizar IMR real para deshabilitar IRQ TX A
        BRA     RTI_LOOP
	*BRA	RTI_END

* --- TRANSMISIÓN B ---
TXB_HANDLER:
        MOVE.L  #3,D0               * D0 = 3 → buffer B (salida)
        JSR     LEECAR
        CMP.L   #-1,D0
        BEQ     DESACT_TXB      * Si no hay caracter, desactivar interrupción TXB

        MOVE.B  D0,TBB              * Enviar siguiente carácter por canal B
        BRA     RTI_LOOP

DESACT_TXB:
        MOVE.B  IMRCOPIA,D1
        BCLR    #4,D1               * Desactivar bit 4 (TXRDY B) en copia de máscara
        MOVE.B  D1,IMRCOPIA
        MOVE.B  D1,IMR              * Actualizar IMR real para deshabilitar IRQ TX B
        BRA     RTI_LOOP

* --- Fin de la rutina de interrupción ---
RTI_END:
        MOVEM.L (A7)+,D0-D2/D7/A0-A4   * Restaurar registros salvados
        RTE                            * Retornar de la excepción (volver al programa)


***************************************************************************

INCLUDE bib_aux.s


