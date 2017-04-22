ORG 0000H
JMP INIT

ORG 0003H ;INTERRUPCION PARA SEND
JMP EXT0

ORG 000BH	;TIMER PARA DELAY
JMP TIM0

ORG 0013H ;INTERRUPCION DEL TECLADO MATRICIAL
JMP EXT1


/*RENOMBRAMIENTOS*/
RS EQU P3.5
RW	EQU P3.6
E	EQU	P3.7
DBUS EQU P2
KEY EQU P0
ALT EQU P3.4
	
/*VARIABLES*/
WAIT50 EQU 40H		;BANDERA 
CUENTA200 EQU 41H	;VARIABLE PARA CONTAR 200 VECES
AAUX EQU 42H		;AUXILIAR PARA ALMACENAR A
ASCII EQU 43H		;ALMACENA EL VALOR ASCII CUANDO SE PRESIONA ALT
AAUX_2 EQU 44H		;AUXILIAR 2 PARA ALMACENAR A
CURSOR_POS EQU R0	;GUARDA LA POSICION DEL CURSOR(de 80H a 8F y de C0 a CF)
AAUX_3 EQU 45H		;AUXILIAR PARA ACUMULADOR
AAUX_4 EQU 46H		;AUXILIAR PARA ACUMULADOR
LCD_LLENO EQU 47H	;BANDERA PARA INDICAR QUE LA PANTALLA ESTA LLENA
ASCII_COUNT EQU 48H	
SEND_POS EQU R1		;POSICION EN MEMORIA DEL DATO QUE SE ESTA ENVIANDO
ACTUAL_POS EQU 49H	;ES IGUAL A LA POSICION DEL CURSOR
	
INIT:
	MOV IE, #10000111B
	MOV IP, #00000010B
	MOV TCON, #00000101B
	MOV SCON, #01000010B
	MOV TMOD, #00100010B
	MOV TH0, #-250
	MOV TL0, #-250	
	MOV TH1, #(-3)
	MOV TL1, #(-3)

	MOV DPTR, #1000H
	MOV CURSOR_POS, #80H
	ACALL DELAY_50MS		
	
	SETB E
	CLR RS
	CLR RW
	
	
	ACALL INIT_DISPLAY		
		
	
	
	JMP $




TIM0:	
	 MOV AAUX_3, A
	 JB WAIT50, WAITING50 
	 
	 WAITING50: 
	 
	 MOV A, CUENTA200	;CARGA EL ACUMULADOR CON LA CUENTA ACTUAL
	 INC A				
	 CJNE A, #0C8H, FIN	;VERIFICA SI LA CUENTA YA LLEGO A 200
	 
	 MOV A, #00H	;SI LA CUENTA ES 200 LA BORRA PARA VOLVER A CONTAR
	 CLR WAIT50		;LIMPIA LA BANDERA DE CONTEO PARA INDICAR QUE YA TERMINO EL DELAY
	 
	 FIN:
	 MOV CUENTA200, A ;GUARDA LA CUENTA 
	 MOV A, AAUX_3	 
		 
	 RETI



EXT1:
	 MOV AAUX, A	
	 
	 MOV A, KEY			;TOMA EL NUMERO DEL TECLADO
	 JB ALT, SI_ALT	 
	 
	 NO_ALT:
		JNB LCD_LLENO, NO_LLENO1
		ACALL BORRAR_PANTALLA
		
		NO_LLENO1:
		ACALL HEX_ASCII	;CONVIERTE EL NUMERO A ASCII
		MOV DBUS, A		;PONE EL NUMERO EN EL BUS DE DATOS	 
		ACALL ESCRIBE_DATO	;ESCRIBE EL NUMERO EN EL DISPLAY
		ACALL CHECK_LINE
		JMP FIN_EXT1
		
	SI_ALT:
		MOV AAUX_2, A
		MOV A, ASCII
		SWAP A
		
		ANL A, #0F0H
		ORL A, AAUX_2 
		
		MOV ASCII, A		
		
		JNB ASCII_COUNT, SUMAR_ACOUNT
		JB ASCII_COUNT, ASCII_LISTO
		
		SUMAR_ACOUNT:
		SETB ASCII_COUNT
		JMP MANDAR_ASCII
		
		ASCII_LISTO:
		CLR ASCII_COUNT
		
		MANDAR_ASCII:
		JNB LCD_LLENO, NO_LLENO2
		ACALL BORRAR_PANTALLA
		
		NO_LLENO2:
		MOV DBUS, ASCII
		ACALL ESCRIBE_DATO
		ACALL CHECK_LINE
		MOV ASCII, #00H
	 
	FIN_EXT1:
	 MOV A, AAUX
	 RETI
	 



EXT0:	
	ACALL SEND_ALL
	
	RETI
	

/*SUBRUTINAS*/
DELAY_50MS:
	
	SETB TR0
	SETB WAIT50
	SETB TF0	
	
	JB WAIT50, $
	CLR TR0
	RET


INIT_DISPLAY:
	MOV DBUS, #38H
	ACALL EXECUTE_E
	
	MOV DBUS, #38H
	ACALL EXECUTE_E
	
	MOV DBUS, #01H
	ACALL EXECUTE_E
	
	MOV DBUS, #0FH
	ACALL EXECUTE_E	
	
	RET


EXECUTE_E:
	CPL E
	;ACALL DELAY_50MS
	CPL E
	ACALL DELAY_50MS
	RET

ESCRIBE_DATO:
	SETB RS
	ACALL EXECUTE_E
	CLR RS
	MOV @CURSOR_POS, DBUS
	RET

HEX_ASCII:
	MOVC A, @A + DPTR
	RET

SALTO_LINEA:
	MOV CURSOR_POS, #0C0H
	MOV DBUS, #0C0H
	ACALL EXECUTE_E
	RET

BORRAR_PANTALLA:
	MOV CURSOR_POS, #80H
	CLR LCD_LLENO
	MOV DBUS, #01H
	ACALL EXECUTE_E
	RET

CHECK_LINE:
		INC CURSOR_POS
	PRIMERA:
		CJNE CURSOR_POS, #90H, SEGUNDA
		ACALL SALTO_LINEA
		JMP FIN_CHECK_LINE
	SEGUNDA:
		CJNE CURSOR_POS, #0D0H, FIN_CHECK_LINE		
		SETB LCD_LLENO
	FIN_CHECK_LINE:		
		RET

SEND_ALL:
	SETB TI
	SETB TR1
	MOV A, #80H
	MOV ACTUAL_POS, CURSOR_POS 
	INC ACTUAL_POS
	
	ENVIA:
		JNB TI, $	
		
		CJNE A, #90H, NO_SALTO
		SALTO:
		MOV A, #0C0H
		
		NO_SALTO:
		MOV SEND_POS, A
		CPL TI	
		MOV SBUF, @SEND_POS
		INC A
		CJNE A, ACTUAL_POS, ENVIA	
		
	FIN_SEND: 
	SETB TI
	CLR TR1
	RET
	
ORG 1000H
	
DB '0'
DB '1'
DB '2'
DB '3'
DB '4'
DB '5'
DB '6'
DB '7'
DB '8'
DB '9'
DB 'A'
DB 'B'
DB 'C'
DB 'D'
DB 'E'
DB 'F'
	
END
