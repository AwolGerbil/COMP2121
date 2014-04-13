/*              connections:
		PB0-PB3     -> LED0 - LED3
		PB0 (input pin) -> PD0 (External Interrupt 0)
		PB1 (input pin) -> PD1 (External Interrupt 1) 

;currently trying to store input data
;next step: using input data for LEDs

/****************************************************************/

.include "m64def.inc"
.dseg
.org 0x100
inputstore: .byte 16
bitpattern: .bit 4

.cseg

.def temp=r16
.def counter=r17
.def counter2=r18
.def counter3=r19
.def flashcounter=r20
.def numbit=r22
.def ledval=r23
.def storecount=r24
.def readcount=r25
.def xlow=r26
.def xhigh=r27
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

RESET: 
	ldi temp, high(RAMEND)		; Initialize stack pointer
	out SPH, temp
	ldi temp, low(RAMEND)
	out SPL, temp
	;set up X pointer
	ldi xlow, low(inputstore)
	ldi xhigh, high(inputstore)
	ldi counter, 0
	ldi counter2, 0
	ldi counter3, 0
	ldi flashcounter, 0
	ldi storecount, 0
	ldi readcount, 0
	ldi temp, 0
	out DDRD, temp			; Set port D as input
	ldi temp, 255
	out DDRB, temp			; Set port B as output
	ldi ledval,0
	out PORTB, ledval
	rjmp main

; External Interrupt0 Service Routine : PB0
EXT_INT0:
	push temp			; Push Conflict Registers
	in temp, SREG			; Saving SREG
	push temp
	push xlow
	push xhigh

	ldi temp, 0xff			; Debouncing, much lazy
	delay0:
	dec temp
	brne delay0

	; Store 0 in memory

	ldi xlow, low(inputstore)	; Set up x pointer
	ldi xhigh, high(inputstore)
	add xlow, storecount		; Increment x to account for stored numbers
	adc xhigh, 0
	ldi temp, 0x00			; Load 0 for storing
	st x, temp			; Store 0
	inc storecount			; Increment stored values

	pop xhigh			; Pop Conflict Registers
	pop xlow
	pop temp			; Restoring SREG
	out SREG, temp
	pop temp
	reti

; External Interrupt1 Service Routine : PB1
EXT_INT1:
	push temp			; Push Conflict Registers
	in temp, SREG			; Saving SREG
	push temp
	push xlow
	push xhigh

	ldi temp, 0xff			; Debouncing, much lazy
	delay1:
	dec temp
	brne delay1

	; Store 1 in memory

	ldi xlow, low(inputstore)	; Set up x pointer
	ldi xhigh, high(inputstore)
	add xlow, storecount 		; Increment x to account for stored numbers
	adc xhigh, 0
	ldi temp, 0xFF			; Load FF for storing
	st x, temp			; Store FF
	inc storecount			; Increment stored values

	pop xhigh			; Pop Conflict Registers
	pop xlow
	pop temp			; Restoring SREG
	out SREG, temp
	pop temp
	reti

Timer0:
	push temp			; Push Conflict Registers
	in temp, SREG			; Saving SREG
	push temp
	push xlow
	push xhigh

/**** a counter for 3597 is needed to get one second-- Three counters are used in this example **************/                                          
                         ; 3597  (1 interrupt 278microseconds therefore 3597 interrupts needed for 1 sec)
                         ; 33 * 109 = 3597
        inc counter
	cpi counter, 33			; Counting for 33
	brne exit
	ldi counter, 0

	inc counter2
	cpi counter2, 109		; Counting for 109
	brne exit
	ldi counter2, 0

	cpi ledval, 0			; Compare the current ledval for zero
	breq ledoffstate
	cpi counter3, 2			; Checks if the led has been on for 2 seconds
	brne outled			; If it hasnt, skip to output
	clr counter3			; If it is zero jump to set it to FF
	ldi ledval, 0             	; If the current ledval is not zero set it to 0

	rjmp outled			; Jump to out put value

ledoffstate:
	inc flashcounter
	cpi flashcounter, 3		; Check if flashed 3 times
	breq end3cycle

	ldi xlow, low(bitpattern)	; Set up x pointer
	ldi xhigh, high(bitpattern)
	ld ledval, X			; Set the ledval 

outled:
	ldi counter, 0			; Clearing the counter values after counting 3597 interrupts which gives us one second
        ldi counter2, 0

        out PORTB, ledval 		; Sending the ledval to portb
        rjmp exit

end3cycle:
	ldi ledval, 0			; Check if there is enough data for a new bit pattern
	rjmp outled
		
exit:
	pop xhigh			; Pop Conflict Registers
	pop xlow
	pop temp			; Restoring SREG
	in SREG, temp
	pop temp
	reti

main:
	ldi temp, 0b00000010
	out TCCR0, temp			; Prescaling value=8  ;256*8/7.3728( Frequency of the clock 7.3728MHz, for the overflow it should go for 256 times)
	ldi temp, 1<<TOIE0		; =278 microseconds
	out TIMSK, temp			; T/C0 interrupt enable
	sei				; Enable global interrupt
loop: 
	rjmp loop			; Loop forever
