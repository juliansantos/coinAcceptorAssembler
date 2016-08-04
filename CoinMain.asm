 #include "configurationbits.h"
 ;****************************************************PREPROCESOR DIRECTIVES LCD
     #define portsAsDigital 0x0F ;  Entradas digitales
    #define DATAB LATB ; D0-D7
    #define RS LATA,0
    #define E  LATA,1
    #define CLEARSCREEN 0x01
    #define DISPLAYON 0x0C
    #define DISPLAYOFF 0x0A
    #define FIRSTLINE 0x80
    #define SECONDLINE 0xC0
    #define THIRDLINE 0x94
    #define FOURTHLINE 0xD4
    #define MODE8BIT5x8M 0x38
    
 ;***************************************PREPROCESOR DIRECTIVES LEDS AND BUTTONS
 #define Pulsador1 PORTB,0
 #define Pulsador2 PORTB,1
 #define Pulsador3 PORTB,2 
 #define Red LATB,3
 #define Green LATB,4
 #define Blue LATB,5
 #define LED1 LATA,3
 #define LED2 LATA,4
 #define LED3 LATA,2
 #define portasdigital 0x0F
 #define T3LED b'00111000'; COLORS
  
    CBLOCK 0x60
    delayvar:3
    blink ; number of times of blinking of a led
    buttonPushed ; button that has been pushed
    ENDC
    
    org 0
main:
    call initialconfigLCD ; get ready MCU to send data to display
    call setLCDup ; initial configuration for LCD
    call LCDCover ;Main Cover
    ;**** Here must be there the code initializate the interruption TO CALL READ BUTTON
    ;call readbutton ;
mainInsertC: 
    call LCDInsertC ;Insert a Coin
    call LEDsRed ; initial configuration for use LEDs and Buttons
    movlw 0x17 
    call delayW0ms ;170ms delay
    call LCDNInsertC
    bra mainInsertC
  
    goto $
    bra main
    
;***************************************************** READING BUTTONS SUBRUTINE    
readbutton:
    movlw 0x0A
    movwf blink ; init var blink
    call read1 ; return the number of the button pushed
    movwf buttonPushed ; save the return var in this var
    movlw T3LED 
    movwf LATB ;LEDsOFF 'colors'A
    clrf LATA ;OFF Anode
    btfsc buttonPushed,0 ;test if button 1 has been pushed
    bsf LED1
    btfsc buttonPushed,1 ;test if button 2 has been pushed
    bsf LED2
    btfsc buttonPushed,2 ;test if button 3 has been pushed
    bsf LED3
read2:    btg Blue
    movlw 0x1E
    call delayW0ms
    decfsz blink
    bra read2
    movlw T3LED 
    movwf LATB ;turn off leds 'Colors'
    bsf LED1
    bsf LED2
    bsf LED3
    bcf Red
    return    
read1:;--------------------------This won't end until one button has been pushed
    btfsc Pulsador1 
    retlw 1
    btfsc Pulsador2
    retlw 2
    btfsc Pulsador3
    retlw 4
    bra read1
    
;****************************** INITIAL CONFIGURATION LEDs AND BUTTONS SUBRUTINE   
LEDsRed:
    ;movlw b'00000111'                                 --! add this two lines to read push
    ;movwf TRISB ; setting data direction of PORTA     --~!
    clrf LATA ; setting initial value of LATA
    movlw T3LED
    movwf LATB ;LEDsOFF
    bsf LED1
    bsf LED2
    bsf LED3
    bcf Red ; Turn On the LEDs in RED COLOR
    return
    
;****************************************************************LCD SUBRUOTINES     
enablepulse: ;-------------------------------------For Latching data in the LCD 
    bsf E ;Rising Edge
    nop
    bcf E ;Falling Edge
    return 
    
command:;---------------------------------------------------For execute commands
    movwf DATAB
    bcf RS
    call enablepulse ;To latch data 
    movlw 0x02 
    call delayW0ms ;Delay for 20ms    
    return

pdata:;----------------------------------------------------For print data in LCD
    movwf DATAB
    bsf RS
    call enablepulse ;To latch data 
    movlw 0x02 
    call delayW0ms ;Delay for 20ms  
    return

setLCDup:;--------------------------------------------------For Initializate LCD    
    movlw 0x02
    call delayW0ms ; Wait 10ms for Start up of LCD
    movlw low ctrlcd ;To load the address 0x000100
    movwf TBLPTRL
    movlw high ctrlcd
    movwf TBLPTRH
    movlw upper ctrlcd
    movwf TBLPTRU

set1:    TBLRD*+
    movf TABLAT,W   
    btfsc  STATUS,Z 
    return
    call command ;execute the command
    bra set1
    
;***************************************SET UP AND INITIALIZATION MCU SUBROUTINE     
initialconfigLCD: 
    movlw portsAsDigital
    movwf ADCON1 ;Ports as digital instead of analogic
    clrf TRISA  ;PortA as digital output
    clrf LATA  ;Initializing PortA = '0'
    clrf TRISB ;PortB as digital output 
    clrf LATB ;Initializing PortB 
    return 
    
;****************************************************************INITIAL MESSAGE    
LCDCover:   
    ;*-------------------Show Welcome Line 1
    movlw low msg1
    movwf TBLPTRL
    movlw high msg1
    movwf TBLPTRH
    movlw upper msg1
    movwf TBLPTRU
    call LCD1
    return
    
    ;*------------------Show  Please insert a coin Line 3
LCDInsertC:
    movlw THIRDLINE ;move to the third line
    call command
    
    movlw low msg2
    movwf TBLPTRL
    movlw high msg2
    movwf TBLPTRH
    movlw upper msg2
    movwf TBLPTRU
    call LCD1
    return
    
LCDNInsertC:
    movlw THIRDLINE ;move to the third line
    call command
    
    movlw low msg3
    movwf TBLPTRL
    movlw high msg3
    movwf TBLPTRH
    movlw upper msg3
    movwf TBLPTRU
    call LCD1
    return
    
LCD1: tblrd*+
    movf TABLAT,W
    btfsc STATUS,Z
    return
    call pdata 
    bra LCD1
    
;***************************************************************DELAY SUBRUTINES   
delay10ms:  ;4MHz frecuency oscillator
    movlw d'84'  ;A Value
    movwf delayvar+1
d0:   movlw d'38' ;B Value
    movwf delayvar  
    nop
d1:  decfsz delayvar,F
    bra d1
    decfsz delayvar+1,F
    bra d0      
    return ;2+1+1+A[1+1+1+B+1+2B-2]+A+1+2A-2+2 => 5+A[5+3B]
    
delayW0ms: ;It is neccesary load a properly value in the acumulator before use this subrutine
    movwf delayvar+2
d2:    call delay10ms
    decfsz delayvar+2,F
    bra d2
    return 
    
;********************************************************************DATA VECTOR
    org 0x200
ctrlcd:  db  MODE8BIT5x8M,DISPLAYON,CLEARSCREEN,FIRSTLINE,0  ;Comandos a ejecutar 
msg1:    da "      WELCOME!      ",0			    
msg2:    da "PLEASE INSERT A COIN",0    
msg3:    da "                    ",0
msg4:    da "JULIAN SANTOS SA    ",0  
msg5:    da "GRACIAS POR UTILIZAR NUESTRO SERVICIO",0   
 END