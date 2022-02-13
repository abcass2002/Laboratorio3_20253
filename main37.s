;Archivo: Prelab2_20253
;Dispositivo: PIC16F887
;Autor: Abner Casasola
;Compilador: pic-as (v2.35) MPLAB v6.00
;
;Programa: contadores y display7seg
;Creado: 9 de febrero de 2022
;Ultima actualizacion: 12 de febrero de 2022
; Archivo: main.s
PROCESSOR 16F887

; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
// config statements should precede project file includes.
#include <xc.inc>
  
// Variables a utiliza
// Vector de reset
PSECT resVect, class = CODE, abs, delta = 2
ORG 00h ; 0000h
resetVec:
    PAGESEL main
    goto main
// Configuracion de microcontrolador
PSECT code, delta = 2, abs
ORG 100h
tabla:
    CLRF PCLATH
    BSF PCLATH, 0
    ANDLW 0x0f
    ADDWF PCL 
    RETLW   00111111B	;0
    RETLW   00000110B	;1
    RETLW   01011011B	;2
    RETLW   01001111B	;3
    RETLW   01100110B	;4
    RETLW   01101101B	;5
    RETLW   01111101B	;6
    RETLW   00000111B	;7
    RETLW   01111111B	;8
    RETLW   01101111B	;9
    RETLW   01110111B	;A
    RETLW   01111100B	;B
    RETLW   00111001B	;C
    RETLW   01011110B	;D
    RETLW   01111001B	;E
    RETLW   01110001B	;F
;Main
main:
    CALL    config_io
    CALL    config_clk
    CALL    config_TM0
    banksel PORTE
    CALL    loop
    CALL    loop2
config_io:
    //Control de pines y bancos
    BSF STATUS, 5 ;Banco 11
    BSF STATUS, 6
    CLRF ANSEL    ;Puerto A digital
    CLRF ANSELH   ;Puerto B digital
    BCF STATUS, 6 ;Banco 01
    BSF TRISE, 0  ;Puerto E0 entrada
    BSF TRISE, 1  ;Puerto E1 entrada
    CLRF TRISB   ;Puerto B, C, D, A como salida
    CLRF TRISD
    CLRF TRISC 
    CLRF TRISA
    BCF STATUS, 5 ; Banco 00
    CLRF PORTC   
    CLRF PORTB   
    CLRF TRISD
    CLRF TRISA
    return
 CONTROL_TM0:
    MOVLW   156     ;100ms
    MOVWF   TMR0
    BCF	    T0IF
    return
    
config_clk:
    banksel OSCCON
    BCF     IRCF2    
    BSF     IRCF1
    BCF     IRCF0
    BSF     SCS      
    return
    //Reloj interno a 256KHz
config_TM0:
    banksel TRISD
    BCF     T0CS    ;Reloj interno
    BCF	    PSA	    ;Configurano prescaler
    BSF	    PS2
    BCF	    PS1
    BSF	    PS0  
    //Prescaler 101 o 1:64
    banksel PORTD
    call    CONTROL_TM0
    return  
;------Loop principal que llama a subrutinas------------
loop:
    CALL comparador
    CALL contador1
    CALL loop2
    GOTO loop
loop2:
    BTFSS   T0IF
    goto    $-1
    CALL    CONTROL_TM0
    INCF    PORTD
    CALL    CONTROL4_bits
    return
    
;------Contador1 con salida en puerto B-----------------
contador1:
    BTFSC PORTE, 0 ;El primer boton no esta esta siendo presionado
    nop            ;salto
    BTFSS PORTE, 0 ;El primer boton esta esta siendo presionado
    call INC_C1    ;Si el boton 1 esta siendo presionado llamar a la subrutina
    BTFSC PORTE, 1
    nop
    BTFSS PORTE, 1
    call DEC_C1
    return
;-----Incrementar valor del contador1-------------------
  INC_C1:
    BTFSS PORTE, 0 ;si el boton sigue estando presionado se repetira la instruccion hasta que deje de ser presionado
    goto $-1
    INCF PORTB ;Cuando se deje de presionar se le incrementa el valor al puerto
    MOVF PORTB, W
    CALL tabla
    MOVWF PORTC
    COMF PORTC,F
    BTFSC PORTB, 4
    CLRF PORTB
    return
;-----Decrementar valor del contador1-------------------
  DEC_C1:
    BTFSS PORTE, 1
    goto $-1
    DECF PORTB ;Cuando se deje de presionar se le incrementa el valor al puerto
    MOVF PORTB, W
    CALL tabla
    MOVWF PORTC
    COMF PORTC,F
    BTFSS PORTB, 7
    return  
    CALL CONTROLRESTA
  CONTROLRESTA:
    CLRF PORTB
    movlw 15
    movwf PORTB
    return
  CONTROL4_bits:
    BTFSC PORTD, 3
    BTFSS PORTD, 1
    return
    CLRF  PORTD
    INCF PORTA
    BTFSS PORTA, 4
    return
    CLRF PORTA
    RETURN
  comparador:
    movf    PORTB, 0
    SUBWF   PORTA, 0
    banksel STATUS
    BTFSS   STATUS,2
    return
    CLRF   PORTA
    return
  END


