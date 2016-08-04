 #include "configurationbits.h"
 ;****************************************************PREPROCESOR DIRECTIVES LCD
 
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
    call initialconfig
    call readbutton   
    bra main
    
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
    movwf LATB ; turn off leds 'Colors'
    bsf LED1
    bsf LED2
    bsf LED3
    bcf Red
    return  
    
read1:    ;This won't end until one button has been pushed
    btfsc Pulsador1 
    retlw 1
    btfsc Pulsador2
    retlw 2
    btfsc Pulsador3
    retlw 4
    bra read1
    
initialconfig:
    movlw portasdigital
    movwf ADCON1 ; Digital I/O 
    movlw b'00000111'  
    movwf TRISB ; setting data direction of PORTA
    clrf TRISA ; PORTB data direction
    clrf LATA ; setting initial value of LATA
    movlw T3LED
    movwf LATB ;LEDsOFF
    bsf LED1
    bsf LED2
    bsf LED3
    bcf Red ; Turn On the LEDs in RED COLOR
    return
    
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
    
 END