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
    #define FIRST4LINE 0x84
    #define SECONDLINE 0xC0
    #define THIRDLINE 0x94
    #define FOURTHLINE 0xD4
    #define MODE8BIT5x8M 0x38
    #define SIGNPESOS  0x24
    
 ;***************************************PREPROCESOR DIRECTIVES LEDS AND BUTTONS
 #define Pulsador1 PORTC,5
 #define Pulsador2 PORTC,4
 #define Pulsador3 PORTC,1 
 #define Red LATB,3
 #define Green LATB,4
 #define Blue LATB,5
 #define LED1 LATA,3
 #define LED2 LATA,4
 #define LED3 LATA,2
 #define portasdigital 0x0F
 #define T3LED b'00111000'; COLORS
 #define TRISButtons b'00000000'
 
 ;********************************************PREPROCESOR DIRECTIVES FOR UART
    #define BR9600 0x19  ; Actually it should be 25.2
    #define ASYNH8b b'00100100' ; Asyncronous mode, high speed, enable 
 

    CBLOCK 0x60
    delayvar:3
    blink ; number of times of blinking of a led
    buttonPushed ; button that has been pushed
    Tcoin ; total acumulate coins
    dTcoin ; tens of the total coin ingresed
    uTcoin ; units of the total coin ingresed
    FLAG  ; if it has been ingresed a coin 
    FLAG2 ; flag if it has been produced a interrupt
    time
    utime ; units of time
    ttime ; tens of time
    ctime  ; hundreds of time
    clc; only is executed one time
    txdata
    nsend ;number of times that txdata is send
    ENDC
    
    org 0
    goto main
    org 8
    goto CCPISR
    
main:
    call initialconfigLCD ; get ready MCU to send data to display
    call setLCDup ; initial configuration for LCD    
    call LCDCover ;Main Cover
    call initccp ; initialize interruption for CCP
    call LEDsRed ; initial configuration for use LEDs 
    ;**** Here must be there the code initializate the interruption TO CALL READ BUTTON
    ;call readbutton ;
mainInsertC: 
    call LCDInsertC ;Insert a Coin
    movlw 0x50 
    call delayW0ms ;170ms delay
    call LCDNInsertC   
    
    tstfsz Tcoin 
    bra choosebank ; It has been added a coin 
    bra mainInsertC
    bra main
    
choosebank: ;display and shows the messages when a coin has been ingresed
    call LCDBank ; shows a message
    call separateC ; separate a number
    call showMoney
    call LEDsGreen
    call readbutton
    ;call send data to servo
    clrf Tcoin ; esta linea va en la anterior subrutina
    clrf FLAG
   ; goto $
    return
;****************************Separation of units and tens of the count subrutine
separateC:
    clrf uTcoin
    clrf dTcoin
    movf Tcoin,W
    movwf uTcoin
se1:    movlw 0x09
    cpfsgt uTcoin
    return 
    bra greater9
       
greater9: ;-------------------------if the total count is greater than 1000    
    movlw 0x0A
    subwf uTcoin,F
    incf dTcoin,F
    bra se1
;****************************************show the money subrutine
showMoney:
    clrf FLAG2
    call dirnum
    movlw ' '
    call pdata
    movlw ' '
    call pdata
    movlw ' '
    call pdata
    movlw ' '
    call pdata
    movlw SIGNPESOS
    call pdata
    tstfsz dTcoin
    call showd ;show tens
    call dirnum ; point numbers
    call showu ;show units
    
    movlw '0'
    call pdata
    movlw '0'
    call pdata
    movlw ' '
    call pdata
    movlw ' '
    call pdata
    movlw ' '
    call pdata
    
    movlw 0x05
    mulwf Tcoin
    movff PRODL,time ; calc the product
    call separateT
    call dirnum ; point numbers from 0
    movf ctime,W
    call showdt ;show centenas
    call dirnum ; point numbers from 0
    movf ttime,W
    call showdt ;show tens
    call dirnum ; point numbers from 0
    movf utime,W
    call showut ;show units
    movlw 'm'
    call pdata
    movlw 'i'
    call pdata
    movlw 'n'
    call pdata
    return

separateT:
    clrf ctime
    clrf utime
    clrf ttime
    movff time,utime
    call sep0
    call sep1
    return
    
sep0:movlw d'99'
    cpfsgt utime
    return 
    bra greater100t
    
sep1:    movlw 0x09
    cpfsgt utime
    return 
    bra greater9t
    
greater100t:
    movlw d'100'
    subwf utime,F
    incf ctime,F
    bra sep0
    
greater9t: ;-------------------------if the total count is greater than 1000    
    movlw 0x0A
    subwf utime,F
    incf ttime,F
    bra sep1
    
showd:  
    movf dTcoin,W ;decenas
showdt:    
    addwf TBLPTRL
    btfsc STATUS,C
    incf TBLPTRH,F
    call show1
    return
showu:    
    movf uTcoin,W ;unidades
showut:    
    addwf TBLPTRL
    btfsc STATUS,C
    incf TBLPTRH,F
    call show1
    return
show1:
    TBLRD* ;move de data to TABLAT
    movf TABLAT,W
    call pdata
    return
    
;****************************subrutien to point direction numbers
dirnum:    
    movlw low ncoin
    movwf TBLPTRL
    movlw high ncoin
    movwf TBLPTRH
    movlw upper ncoin
    movwf TBLPTRU
    return
;***************************************************** READING BUTTONS SUBRUTINE    
readbutton:
    setf FLAG ; To indicate that has been ingresed a coin
    movlw 0x0A
    movwf blink ; init var blink
    call read1 ; return the number of the button pushed
    clrf TRISB ; data direction
    movwf buttonPushed ; save the return var in this. According to the bit 
    movlw T3LED    
    movwf LATB ;LEDsOFF 'colors'A
    clrf LATA ;OFF Anode
    btfsc buttonPushed,0 ;test if button 1 has been pushed
    bsf LED1
    btfsc buttonPushed,1 ;test if button 2 has been pushed
    bsf LED2
    btfsc buttonPushed,2 ;test if button 3 has been pushed
    bsf LED3
read2:    btg Blue ;blink the LED that represent the button that has been pushed
    movlw 0x1E
    call delayW0ms
    decfsz blink
    bra read2
    call targetbank
    movlw d'200' ;Show the message for 1s
    call delayW0ms
    call showthanks
    movlw d'100' ;Show the message for 1s
    call delayW0ms
    call TXSUB
    movlw T3LED 
    movwf LATB ;turn off leds 'Colors'
    bsf LED1 ;turn on LEDs of red color
    bsf LED2
    bsf LED3
    bcf Red
    setf clc
    return    
read1:;--------------------------This won't end until one button has been pushed
    btfss FLAG2,7 ; 7 JAJA LOL XD
    bra rr1
    clrf TRISB
    call separateC 
    call showMoney
    movlw TRISButtons                               ;
    movwf TRISB ; setting data direction of PORTB     --~!
    call LEDsGreen
rr1:   
    btfsc Pulsador1 
    retlw 1
    btfsc Pulsador2
    retlw 2
    btfsc Pulsador3
    retlw 4
    bra read1
;***************************************************** GO TO THE BANK X
targetbank:
    movlw CLEARSCREEN
    call command
    movlw THIRDLINE
    call command
    movlw low msg6
    movwf TBLPTRL
    movlw high msg6
    movwf TBLPTRH
    movlw upper msg6
    movwf TBLPTRU
    call LCD1
    call banknumber
    call pdata
    return

banknumber:    
    btfsc buttonPushed,0
    retlw '1'
    btfsc buttonPushed,1
    retlw '2'
    btfsc buttonPushed,2
    retlw '3'
    return 
    
;*******************************************SHOW THANKS SUBRUTINE
showthanks:
    movlw THIRDLINE
    call command
    movlw low msg7
    movwf TBLPTRL
    movlw high msg7
    movwf TBLPTRH
    movlw upper msg7
    movwf TBLPTRU
    call LCD1
    return
;****************************** INITIAL CONFIGURATION LEDs AND BUTTONS SUBRUTINE   
LEDsRed:
    ;clrf LATA ; setting initial value of LATA
    movlw T3LED
    movwf LATB ;LEDsOFF
    bsf LED1
    bsf LED2
    bsf LED3
    bcf Red ; Turn On the LEDs in RED COLOR
    return

LEDsGreen:
    clrf LATA ; setting initial value of LATA
    movlw T3LED
    movwf LATB ;LEDsOFF
    bsf LED1
    bsf LED2
    bsf LED3
    bcf Green ; Turn On the LEDs in RED COLOR
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
    movlw 0x01 
    call delayW0ms ;Delay for 20ms    
    return

pdata:;----------------------------------------------------For print data in LCD
    movwf DATAB
    bsf RS
    call enablepulse ;To latch data 
    movlw 0x01 
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
    bsf OSCCON,6
    bsf OSCCON,5
    bcf OSCCON,4 ;For select 4MHZ clock
    bcf UCON,3 ; Disenable USB Module, for use pins C4 and C5
    bsf UCFG,3 ;
    
    movlw portsAsDigital
    movwf ADCON1 ;Ports as digital instead of analogic
    clrf TRISA  ;PortA as digital output
    clrf LATA  ;Initializing PortA = '0'
    clrf TRISB ;PortB as digital output 
    clrf LATB ;Initializing PortB 
    movlw b'00110110'
    movwf TRISC ; data direction PortC
    clrf LATC
    setf clc
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

LCDBank:
    movlw THIRDLINE ;move to the third line
    call command
    
    movlw low msg4
    movwf TBLPTRL
    movlw high msg4
    movwf TBLPTRH
    movlw upper msg4
    movwf TBLPTRU
    call LCD1
    
    movlw FOURTHLINE ;move to the third line
    call command
    
    movlw low msg5
    movwf TBLPTRL
    movlw high msg5
    movwf TBLPTRH
    movlw upper msg5
    movwf TBLPTRU
    call LCD1
    return 
    
LCD1: tblrd*+
    movf TABLAT,W
    btfsc STATUS,Z
    return
    call pdata 
    bra LCD1
;*************************************INITIAL CONFIGURATION CCP MODULE SUBRUTINE
initccp:
    movlw 0x04 ;capture mode, falling edge
    movwf CCP1CON 
    clrf T3CON
    bsf TRISC,RC2 ; CCP1 as Input 
    bcf PIR1,CCP1IF
    bsf PIE1,CCP1IE; Enabling interrupt for CCP1
    bsf INTCON,PEIE; Enabling peripheral interrupts
    bsf INTCON,GIE; Enabling global interruptions
    clrf Tcoin
    clrf FLAG
    return
;***************************************************CCP INTERRUPT SERVICE RUTINE    
CCPISR:
    tstfsz clc
    call clear
    setf FLAG2
    clrf TRISB ; In the case of button input
    movlw 0x19
    call delayW0ms ; 25ms delay subrutine
    bcf PIR1,CCP1IF
    movlw 0x19
    call delayW0ms ; 25ms delay subrutine
;    movlw CLEARSCREEN
;    call command
    btfss PIR1,CCP1IF
    bra S200 ; Coin value =500 
    btfsc PIR1,CCP1IF
    bra S500; Coin value = 200
      
S500:;---------------------------------------------------------500 COIN SUBRUTINE
    btg LATC,RC6
    movlw 0x05
    addwf Tcoin,F
    bcf PIR1,CCP1IF ; Clear Flag CCP1 Module
    bsf FLAG,1
    retfie 1 ; restore W and Status register from shadow resgisters
    
S200:;---------------------------------------------------------200 COIN SUBRUTINE
    btg LATC,RC6
    movlw 0x02
    addwf Tcoin,F
    bcf PIR1,CCP1IF ; Clear Flag CCP1 Module
    bsf FLAG,1
    retfie 1 ;restore W and Status register from shadow registers

clear:
    movlw CLEARSCREEN
    call command
    clrf clc
    return
;****************************************************************USART SUBRUTINE    
TXSUB:
    bcf INTCON,GIE ; turn off the interruptions for a moment 
    bcf BAUDCON,BRG16 ; Baud rate generator 8 bits 'old school'
    movlw ASYNH8b
    movwf TXSTA ;
    movlw BR9600 
    movwf SPBRG ;Charging the adecuate value to generate 9600 bauds
    bcf TRISC,TX ;Setting data direction for tx pin 
    bsf RCSTA,SPEN; enabling tx pin
    
    clrf txdata
    movff Tcoin,txdata	    ;xxXXXXXX
    bcf txdata,7 ;equipos
    bcf txdata,6 ;equipos
    btfsc buttonPushed,0    ;01 bank1
    bsf txdata,6
    btfsc buttonPushed,1    ;10 bank2
    bsf txdata,7
    btfsc buttonPushed,2    ;11 bank3
    bsf txdata,7
    btfsc buttonPushed,2
    bsf txdata,6

    movlw 0x1E
    movwf nsend
senddata:    
    movf txdata,W
wait:    btfss PIR1,TXIF
    bra wait
    movwf TXREG
    decfsz nsend
    bra senddata
    bsf INTCON,GIE ; turn on the interruptions 
    ;goto $
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
    
;********************************************************************DATA VECTOR
    org 0x500
ctrlcd:  db  MODE8BIT5x8M,DISPLAYON,CLEARSCREEN,FIRSTLINE,0  ;Comandos a ejecutar 
msg1:    da "      WELCOME!      ",0			    
msg2:    da "PLEASE INSERT A COIN",0    
msg3:    da "                    ",0
msg4:    da "    CHOOSE A SEAT   ",0  
msg5:    da "   1      2      3  ",0    
msg6:    da "DIRIGASE AL BANCO:",0
ncoin:   da "0123456789",0
msg7:    da "     GRACIAS        ",0   
 END