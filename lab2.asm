/***************************************************************************************
   Example.3.2: This example demonstrates on how TIMER0 OVERFLOW interrupt can be used
                to switch the speaker and motor on and off for approximately one second
	        The STACK POINTER is needed to keep track of the return address
                ***********************************************************************/
/*              connections:
		    PB0-PB3     -> LED0 - LED3
		    PB4         -> Mot    
		    Ain(Audio)  -> OpD
		    ASD         -> Speaker (PIN 1)
		    PB0(Switch) -> OpE   

;currently trying to store input data
;next step: using input data for LEDs

/**************************************************************************************/

.include "m64def.inc"
.dseg
.org 0x100
cheese: .byte 16

.cseg
.def temp=r16
.def counter=r17
.def counter2=r18
.def counter3=r19
.def counter4=r20
.def counter5=r22
.def numbit=r23
.def ledval=r21
;setting up the interrupt vector
jmp RESET
jmp EXT_INT0 ; IRQ0 Handler for PD0
jmp EXT_INT1 ; IRQ1 Handler for PD1 --> D is hardwired as interrupt input
jmp Default ; IRQ2 Handler
jmp Default ; IRQ3 Handler
jmp Default ; IRQ4 Handler
jmp Default ; IRQ5 Handler
jmp Default ; IRQ6 Handler
jmp Default ; IRQ7 Handler
jmp Default ; Timer2 Compare Handler
jmp Default ; Timer2 Overflow Handler
jmp Default ; Timer1 Capture Handler
jmp Default ; Timer1 CompareA Handler
jmp Default ; Timer1 CompareB Handler
jmp Default ; Timer1 Overflow Handler
jmp Default ; Timer0 Compare Handler
jmp Timer0  ; Timer0 Overflow Handler


Default: reti

RESET: ldi temp, high(RAMEND) ; Initialize stack pointer
out SPH, temp
ldi temp, low(RAMEND)
out SPL, temp
;set up z pointer
ldi counter,0            
ldi counter2,0
ldi counter3,0
ldi counter4,0
ldi counter5,0
ldi temp, 0
out DDRD, temp ;set port D as input
ldi temp,255
out DDRB,temp   ;set port D as output
ldi ledval,0
out PORTB,ledval
rjmp main

; interrupt place invoked by EXT interrupt0 when button PB0 is pressed
EXT_INT0:                  ; saving the temp value into the stack  
push temp
in temp, SREG              ; inserting the SREG values into temp
push temp                  ; saving the temp into stack
ldi temp 0;
;our code here

pop temp                   ; taking out temp from stack which has SREG
out SREG, temp             ; copy the values in temp into SREG
pop temp                   ; take the temp value from stack
reti



; interrupt place invoked by EXT interrupt1 when button PB1 is pressed
EXT_INT1:
push temp
in temp, SREG
push temp
;our code here

pop temp
out SREG, temp
pop temp
reti


Timer0:                  ; Prologue starts.
push r29                 ; Save all conflict registers in the prologue.
push r28
in r24, SREG
push r24                 ; Prologue ends.

/**** a counter for 3597 is needed to get one second-- Three counters are used in this example **************/                                          
                         ; 3597  (1 interrupt 278microseconds therefore 3597 interrupts needed for 1 sec)
cpi counter, 97          ; counting for 97
brne notsecond
 
cpi counter2, 35         ; counting for 35
brne secondloop          ; jumping into count 100 

cpi ledval,0             ; compare the current ledval for zero
breq setVal
inc counter4
cpi counter4,2
brne outmot   
clr counter4             ; if it is zero jump to set it to FF
ldi ledval,0             ; if the current ledval is not zero set it to 0
inc counter5
cpi counter5,3
breq stopflash
rjmp outmot              ; jump to out put value

stopflash:
		ldi temp, 0<<TOIE0		     ; =278 microseconds
		out TIMSK, temp          ; T/C0 interrupt enable	
		rjmp  outmot

setVal: ldi ledval,0b00001101    ; set the ledval 

outmot: ldi counter,0    ; clearing the counter values after counting 3597 interrupts which gives us one second
        ldi counter2,0
        ldi counter3,0
        out PORTB,ledval ; sending the ledval to port
        rjmp exit        ; go to exit

notsecond: inc counter   ; if it is not a second, increment the counter
           rjmp exit

secondloop: inc counter3 ; counting 100 for every 35 times := 35*100 := 3500
            cpi counter3,100 
            brne exit
	    inc counter2
	    ldi counter3,0                  
exit: 
pop r24                  ; Epilogue starts;
out SREG, r24            ; Restore all conflict registers from the stack.
pop r28
pop r29
reti                     ; Return from the interrupt.

main:
ldi temp, 0b00000010     ; 
out TCCR0, temp          ; Prescaling value=8  ;256*8/7.3728( Frequency of the clock 7.3728MHz, for the overflow it should go for 256 times)
ldi temp, 1<<TOIE0       ; =278 microseconds
out TIMSK, temp          ; T/C0 interrupt enable
sei                      ; Enable global interrupt
loop: rjmp loop          ; loop forever