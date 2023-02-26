//
//
// project Semi automatic washingmachine
//
// Created: 24/02/2023
// Author : DELL
//



.include "m328pdef.inc"
	.org	0x00
	rjmp	SETUP_Main

	.org	0x002
	rjmp	INTO_Handler

	.org	0x001A
	rjmp	TOVF1_ISR


	.def	G1_reg		= r16
	//.def	Tcount		= r17

	.def	number		= r18				// display R
	.def	Tcount		= r19
	.def	number3		= r20
	.def	number1		= r21

	.def	number2		= r22

	.def	lCount		= r23				// delay count R
	.def	iLoopRL		= r24
	.def	iLoopRH		= r25

	.equ	iVal		= 1998
	.equ	C_Adres		= 60

	.equ	startTime	= 5

	ldi		G1_reg	, 0b11111111			// PB port input  0-input, 1- output
	out		DDRB	, G1_reg

	ldi		G1_reg	, 0b11100000			// PD port input  0-input, 1- output
	out		DDRD	, G1_reg

	ldi		G1_reg	, 0b00111110
	out		DDRC	, G1_reg



// ----------------------- Setup section start -------------------------
//
//
SETUP_Main:
	// eeprom check ....................................................
	ldi		iLoopRL	, LOW(C_Adres)						
	ldi		iLoopRH	, HIGH(C_Adres)
	rcall	EEPROM_read

	cpi		number	, 0b00000000
	breq	newStart
	cpi		number	, LOW(startTime)
	brne	powerOut	
	// ................................................................
EEPROM_ckeched:
	// ADC set ........................................................
	ldi		G1_reg	, 0b00100000			// ADC Multiplexer Selection Register
	sts		ADMUX	, G1_reg				// bit 7,6 - Voltage Reference Selections for ADC
											// bit 5 - ADC left adjest result ( 0-start at low bit in ADCL total 10bits)
											// bit 3:0 - Analog Channel Selection Bits ( 000 - PC0)

	ldi		G1_reg	, 0b10000111			//  ADC Control and Status Register A
	sts		ADCSRA	, G1_reg	
	// ................................................................

	// Pin out set .....................................................
	ldi		G1_reg	, 0b00111111			// PB port input  0-input, 1- output
	out		DDRB	, G1_reg

	ldi		G1_reg	, 0b11100000			// PD port input  0-input, 1- output
	out		DDRD	, G1_reg
// -----------------------------------------------------------------------



// ----------------------------- SETUP loop -------------------------------
SETUP:
	// PIn out C as input ..........................................
	ldi		G1_reg	, 0b00000000
	out		DDRC	, G1_reg

	cbi		PORTD	, 1						// Disable water out relay
	cbi		PORTD , 5						// Buzzer disable

Wlevel:										// Water level set
	ldi		G1_reg	, 0b11000111
	sts		ADCSRA	, G1_reg				// ADC start conversion

wait_adc:
	lds		G1_reg	, ADCSRA
	sbrs	G1_reg	, 4						// SBRS - Skip if 4th bit in register is set
	rjmp	wait_adc						// if 4th bit = 0 loop to wait_adc
											// continue until detect the input analog value
	ldi		G1_reg	, 0b11010111			// Interrupt flag set 1
	sts		ADCSRA	, G1_reg

	lds		number , ADCH					// get the highbits of A to D convert value
		
	// Pin out C set ..........................................
	/*ldi		G1_reg	, 0b11111111
	out		DDRC	, G1_reg*/

	// ADC value check..........................................
	cpi		number	, 0b01001100
	brlo	lowLevel
	cpi		number	, 0b10000000
	brlo	midLevel
	brge	highLevel
	// .........................................................

Start_check:
	in		G1_reg	, PIND								
	sbrc	G1_reg	, 3
	rjmp	Ultrasoinc_check					//  If start press

	ldi		number2	, 0b00000001				// HI display
	ldi		number3	, 0b00001011
	rcall	Seven_segment

	rjmp	SETUP

lowLevel:										// water level check
	ldi		number	, 0b00011000
	cbi		PORTC	, 3
	cbi		PORTC	, 4
	sbi		PORTC	, 5
	rjmp	Start_check
midLevel:
	ldi		number	, 0b00010000
	cbi		PORTC	, 3
	sbi		PORTC	, 4
	sbi		PORTC	, 5
	rjmp	Start_check
highLevel:
	ldi		number	, 0b00001000
	sbi		PORTC	, 3
	sbi		PORTC	, 4
	sbi		PORTC	, 5
	rjmp	Start_check
// ------------------------------------------------------------------


// Power out option --------------------------------------------------
powerOut:
	rjmp main
newStart:
	ldi		iLoopRL	, LOW(C_Adres)
	ldi		iLoopRH	, HIGH(C_Adres)
	ldi		number	, LOW(startTime)
	rcall	EEPROM_write
	rjmp	EEPROM_ckeched
// ------------------------------------------------------------------	



// -------------------------- Ultrasonic sensor check ---------------
Ultrasoinc_check:
	// Pin out set ...............................................
	ldi		G1_reg	, 0b11111110
	out		DDRB	, G1_reg

	ldi		G1_reg	, 0b11100011 
	out		DDRD	, G1_reg

	ldi		G1_reg	, 0b00111110
	out		DDRC	, G1_reg
	// ..............................................................

	sbi		PORTD	, 0						// Enable relay 1 water in

	// Trigger signal ............................................
	sbi		PORTD	, 7			
	rcall	delay_timer0
	cbi		PORTD	, 7
	
	// Read recived signal .......................................
	rcall	echo_PW
	rcall	WLevel_con						// conditional check
	rcall	delay_ms

	rjmp	Ultrasoinc_check
WLevel_con:
	cp		R28		, number
	brlo	main1234

	ret
main1234:
	cbi		PORTD	, 0						// Disable relay 1 water in
	rjmp	main

	ret
// ----------------------------------------------------------------



// echo signal read -----------------------------------------------
echo_PW:
    ldi		R20		, 0b00000000
    sts		TCCR1A	, R20					// Timer 1 normal mode
    ldi		R20		, 0b11000101			// set for rising edge detection &
    sts		TCCR1B	, R20					// prescaler=1024, noise cancellation ON
l1: 
	in		R21		, TIFR1
    sbrs	R21		, ICF1
    rjmp	l1								//loop until rising edge is detected

    lds		R16		, ICR1L					// store count value at rising edge

    out		TIFR1	, R21					// clear flag for falling edge detection
    ldi		R20		, 0b10000101
    sts		TCCR1B	, R20					// set for falling edge detection
l2: 
	in		R21		, TIFR1
    sbrs	R21		, ICF1
    rjmp	l2								// loop until falling edge is detected

    lds		R28		, ICR1L					// store count value at falling edge

    sub		R28		, R16					// count diff R22 = R22 - R16
    out		TIFR1	, R21					// clear flag for next sensor reading
    ret
// ----------------------------------------------------------------



// delay timer0 --------------------------------------------------
delay_timer0:								// 10 usec delay via Timer 0
    clr		R20
    out		TCNT0	, R20					// initialize timer0 with count=0
    ldi		R20		, 20
    out		OCR0A	, R20					// OCR0 = 20
    ldi		R20		, 0b00001010
    out		TCCR0B	, R20					// timer0: CTC mode, prescaler 8
    
l0: 
	in		R20		, TIFR0					// get TIFR0 byte & check
    sbrs	R20		, OCF0A					// if OCF0=1, skip next instruction
    rjmp	l0								// else, loop back & check OCF0 flag
    
    clr		R20
    out		TCCR0B	, R20					// stop timer0
    
    ldi		R20		, (1<<OCF0A)
    out		TIFR0	, R20					// clear OCF0 flag
    ret
// -----------------------------------------------------------------



// delay in ms ------------------------------------------------------
delay_ms:
	ldi		R21		, 255
l6: 
	ldi		R22		, 255
l7: 
	ldi		R23		, 50
l8: 
	dec		R23
    brne	l8
    dec		R22
    brne	l7
    dec		R21
    brne	l6
    ret	
// ---------------------------------------------------------------------





// ------------------------ Main start setup ---------------------------
//
//
main_start_:
	ldi		G1_reg	, 0b11111111				// PB port input  0-input, 1- output
	out		DDRB	, G1_reg

	ldi		G1_reg	, 0b11100011
	out		DDRD	, G1_reg

	ldi		G1_reg	, 0b00111110
	out		DDRC	, G1_reg
main:	
	// Timer 1 counter set ............................................
	cli

	ldi		G1_reg	, 0b00000100			// set clock(/128)
	sts		TCCR1B	,	G1_reg

	ldi		G1_reg	, 0b00000000
	sts		TCNT1H	, G1_reg
	sts		TCNT1L	, G1_reg

	ldi		G1_reg	, 0b00000001			// inturrupt enable
	sts		TIMSK1	, G1_reg

	// reset interrupt ..................................................
	ldi		G1_reg , 0b00000001				// External Interrupt Mask Register
	out		EIMSK , G1_reg					// INT0 external pin interrupt is enabled ( pin D2)

	ldi		G1_reg , 0b00000011				// External Interrupt Control Register A
	sts		EICRA , G1_reg	

	sei
	// ..................................................................

	// Pin out set .....................................................
	/*ldi		G1_reg	, 0b11111111				// PB port input  0-input, 1- output
	out		DDRB	, G1_reg

	ldi		G1_reg	, 0b11100011
	out		DDRD	, G1_reg

	ldi		G1_reg	, 0b00111110
	out		DDRC	, G1_reg*/
	// ..................................................................

	ldi		Tcount	, 0b00000000				// Tcount clear	
	cbi		PORTD	, 5							// buzzer clear

// -------------------------------------------------------------------------


// ---------------------------- Main loop start ----------------------------
start:
	// door check .......................................................
	in		G1_reg	, PIND								
	sbrs	G1_reg	, 4
	rjmp	DoorOpen

	// start / stop switch ..............................................
	in		G1_reg	, PIND								
	sbrs	G1_reg	, 3
	rjmp	Pause

	// Time complete check ..............................................
	rcall	TimeCheck							// count down read

	ldi		iLoopRL	, LOW(C_Adres)				// eeprom read
	ldi		iLoopRH	, HIGH(C_Adres)
	rcall	EEPROM_read

	cpi		number	, 0b00000000				// end loop if count is 0
	breq	End

	mov		G1_reg	, number					// Display number
	rcall	Divide_number
	rcall	Seven_segment
	rcall	Seven_segment
	rcall	Seven_segment
	ldi		lCount	, 5
	rcall	Delay_1milles

	// IF all pass continue ..............................................
	sbi		PORTC	, 1							// motor enable

	sbrc	Tcount	, 0
	rjmp	plus_dir
plus_dir1:										// direction 1
	sbi		PORTC	, 2
	rjmp	start
plus_dir:										// direction 2
	cbi		PORTC	, 2
	rjmp	start
// -----------------------------------------------------------------



// Door Open -------------------------------------------------------
DoorOpen:
	cbi		PORTC	, 1

	ldi		G1_reg	, 0b00000000
	sts		TCNT1H	, G1_reg
	sts		TCNT1L	, G1_reg

	ldi		Tcount	, 0b00000000

	ldi		number2	, 0b00000000
	ldi		number3	, 0b00001010
	rcall	Seven_segment
	rcall	Seven_segment
	rcall	Seven_segment
	rcall	Seven_segment
	rcall	Seven_segment

	rjmp start
// ------------------------------------------------------------------
	


// Pause the system -------------------------------------------------
Pause:
	cbi		PORTC	, 1
	
	ldi		G1_reg	, 0b00000000
	sts		TCNT1H	, G1_reg
	sts		TCNT1L	, G1_reg

	ldi		Tcount	, 0b00000000

	ldi		iLoopRL	, LOW(C_Adres)
	ldi		iLoopRH	, HIGH(C_Adres)
	rcall	EEPROM_read

	cpi		number	, LOW(startTime)				// To main start
	breq	End_reset

	mov		G1_reg	, number
	rcall	Divide_number
	rcall	Seven_segment

	rjmp	start
// ------------------------------------------------------------------	



// End of the system -------------------------------------------------
End:
	sbi		PORTD	, 1								// water out set
	sbi		PORTD , 5
	cbi		PORTC	, 1

	ldi		G1_reg	, 0b00000000
	sts		TCNT1H	, G1_reg
	sts		TCNT1L	, G1_reg

	ldi		Tcount	, 0b00000000

	ldi		iLoopRL	, LOW(C_Adres)
	ldi		iLoopRH	, HIGH(C_Adres)
	rcall	EEPROM_read

	mov		G1_reg	, number
	rcall	Divide_number
	rcall	Seven_segment

	in		G1_reg	, PIND							// To main start			
	sbrs	G1_reg	, 3
	rjmp	End_reset

	rjmp start

End_reset:
	cbi		PORTD	, 1
	cbi		PORTD , 5
	cbi		PORTD	, 0
	cbi		PORTC	, 1
	cbi		PORTC	, 2

	rjmp	SETUP_Main
// ---------------------------------------------------------------------



// EEPROM Write -----------------------------------------------------
// + iLoopRH, iLoopRL, number registers have given values
// no stored data
EEPROM_write:
	sbic	EECR	, EEPE						// wait for completion of previous write
	rjmp	EEPROM_write

	out		EEARH	, iLoopRH					// write address
	out		EEARL	, iLoopRL
	out		EEDR	, number					// write data

	sbi		EECR	, EEMPE						// set EEMPE 1
	sbi		EECR	, EEPE						// start to write

	ldi		lCount	, 5
	rcall	Delay_1milles

	ret
// -------------------------------------------------------------------




// EEPROM Read ------------------------------------------------------
// + iLoopRH, iLoopRL registers have given values
// number register store the read value
EEPROM_read:
	sbic	EECR	, EEPE						// wait for completion of previous write
	rjmp	EEPROM_read

	out		EEARH	, iLoopRH					// write address
	out		EEARL	, iLoopRL

	sbi		EECR	, EERE						// start reading

	ldi		lCount	, 5
	rcall	Delay_1milles

	in		number	, EEDR						// read data to number
	ret
// -----------------------------------------------------------------




// Delay 1 milli seconds -----------------------------------------------
// + lCount register have the given value of multipule delay
// iLoopRL, iLoopRH registers are used
// no store data
// iVal		= 3998
Delay_1milles:
	ldi		iLoopRL	, LOW(iVal)
	ldi		iLoopRH	, HIGH(iVal)
iLoop:
	sbiw	iLoopRL, 1							// Subtract immediate from word ( count down)
	brne	iLoop								// branch to iLoop if iLoopRL registers != 0 ( until zero)

	dec		lCount								// Decrement lCount <-- lCount -1
	brne	Delay_1milles						// branch to oLoop
	nop											// No operation
	ret
// ---------------------------------------------------------------------




// Divide by 10 --------------------------------------------------------
// + G1_reg registor have the given value
// number, number2, number3 registers are used
// number2, number3 register store the 1st and 2nd digits
Divide_number:
	ldi number , 0b00000000	
div_1:
	cpi		G1_reg	, 0b00001010				// divide by 10
	brge	div_10
	mov		number2 , G1_reg
	mov		number3	, number	
	ret
div_10:
	inc		number
	subi	G1_reg	, 0b00001010
	rjmp	div_1
//---------------------------------------------------------------------




// Time check  --------------------------------------------------------
// + number, Tcount, iLoopRL, iLoopRH registers used
// EEPROM_read and EEPROM_write functons are used
// Tcount value update
// minimum check 4s
TimeCheck:
	cpi		Tcount	, 0b00000010					// 1x2 s check
	brge	minutesC
	ret
minutesC:
	ldi		iLoopRL	, LOW(C_Adres)
	ldi		iLoopRH	, HIGH(C_Adres)
	rcall	EEPROM_read

	dec		number

	ldi		iLoopRL	, LOW(C_Adres)
	ldi		iLoopRH	, HIGH(C_Adres)
	rcall	EEPROM_write

	ldi		Tcount	, 0b00000000

	ret
// --------------------------------------------------------------------




// 7 segment display --------------------------------------------------
// + number2 and number3 registers have the given values
// number1, number, G1_reg registers are used
// no store data
Seven_segment:						
	// number 1 selcting
	mov		number	, number2			
	rcall	num_check

	rcall	Display

	sbi		PORTB	, PINB3
	cbi		PORTB	, PINB4
	//sbi		PORTB	, PINB4
	ldi		lCount	, 5
	rcall	Delay_1milles
	sbi		PORTB	, PINB4
	//cbi		PORTB	, PINB4
	cbi		PORTB	, PINB3
	
	// number 2 selcting
	mov		number	, number3			
	rcall	num_check

	rcall	Display

	sbi		PORTB	, PINB3
	cbi		PORTB	, PINB5
	//sbi		PORTB	, PINB5
	ldi		lCount	, 5
	rcall	Delay_1milles
	sbi		PORTB	, PINB5
	//cbi		PORTB	, PINB5
	cbi		PORTB	, PINB3

	ret


Display:										// shift register protocol
	ldi		G1_reg	, 8
loop:
	SBRC	number1	, 0
	rjmp	_pinSet
testtt:
	sbi		PORTB	, PINB2
	ldi		lCount	, 1
	rcall	Delay_1milles

	cbi		PORTB	, PINB2
	cbi		PORTB	, PINB1
	ldi		lCount	, 1
	rcall	Delay_1milles

	LSR		number1
	dec		G1_reg
	brne	loop

	ret
_pinSet:
	sbi		PORTB	, PINB1
	rjmp	testtt


num_check:								// number cheking
	cpi		number	, 0b00000000
	breq	con0
	cpi		number	, 0b00000001
	breq	con1	
	cpi		number	, 0b00000010
	breq	con2
	cpi		number	, 0b00000011
	breq	con3
	cpi		number	, 0b00000100
	breq	con4	
	cpi		number	, 0b00000101
	breq	con5
	cpi		number	, 0b00000110
	breq	con6
	cpi		number	, 0b00000111
	breq	con7	
	cpi		number	, 0b00001000
	breq	con8
	cpi		number	, 0b00001001
	breq	con9
	cpi		number	, 0b00001010
	breq	con10
	cpi		number	, 0b00001011
	breq	con11
	ret

/*con0:
	ldi		number1	, 0b00000001
	ret	
con1:
	ldi		number1 , 0b01001111
	ret
con2:
	ldi		number1	, 0b00010010
	ret
con3:
	ldi		number1	, 0b00000110
	ret
con4:
	ldi		number1	, 0b01001100
	ret
con5:
	ldi		number1	, 0b00100100
	ret
con6:
	ldi		number1	, 0b00100000
	ret
con7:
	ldi		number1 , 0b00001111
	ret
con8:
	ldi		number1	, 0b00000000
	ret
con9:
	ldi		number1	, 0b00000100
	ret
con10:
	ldi		number1	, 0b00110000
	ret
con11:
	ldi		number1	, 0b01001000
	ret*/
con0:
	ldi		number1	, 0b01111110
	ret	
con1:
	ldi		number1 , 0b00110000
	ret
con2:
	ldi		number1	, 0b01101101
	ret
con3:
	ldi		number1	, 0b01111001
	ret
con4:
	ldi		number1	, 0b00110011
	ret
con5:
	ldi		number1	, 0b01011011
	ret
con6:
	ldi		number1	, 0b01011111
	ret
con7:
	ldi		number1 , 0b01110000
	ret
con8:
	ldi		number1	, 0b01111111
	ret
con9:
	ldi		number1	, 0b01111011
	ret
con10:
	ldi		number1	, 0b01001111
	ret
con11:
	ldi		number1 , 0b00110111
	ret
//--------------------------------------------------------------



// Timer inturrupt ---------------------------------------------
// per 4s inturrupt
TOVF1_ISR:
	push	G1_reg								// push registers
	push	number
	push	number1
	push	number2
	push	number3
	push	lCount
	push	iloopRL
	push	iLoopRH

	ldi		G1_reg	, 0b00000000
	sts		TCNT1H	, G1_reg					// set TCNT1 register to 0
	sts		TCNT1L	, G1_reg

	inc		Tcount

	pop		iLoopRH								// pull registers
	pop		iloopRL
	pop		lCount
	pop		number3
	pop		number2
	pop		number1
	pop		number
	pop		G1_reg

	reti
// -----------------------------------------------------------------


// Reset interrupt -------------------------------------------------
INTO_Handler:	
	push	G1_reg								// push registers
	push	number
	push	number1
	push	number2
	push	number3
	push	lCount
	push	iloopRL
	push	iLoopRH

	ldi		iLoopRL	, LOW(C_Adres)
	ldi		iLoopRH	, HIGH(C_Adres)
	ldi		number	, LOW(startTime)
	rcall	EEPROM_write

	ldi		Tcount	, 0b00000000

	cbi		PORTD , 5		

	pop		iLoopRH								// pull registers
	pop		iloopRL
	pop		lCount
	pop		number3
	pop		number2
	pop		number1
	pop		number
	pop		G1_reg

	reti										// return from interrupt
// ----------------------------------------------------------------------

	

