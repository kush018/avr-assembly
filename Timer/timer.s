
/*
Author: Khushi Galrani
Description:
On button press, the led turns on and off, spending 1 second on and 1 second off. This cycle repeats 10 times.
The delay due to the timer is EXACTLY 1 second for a clock speed of 1 MHz
*/

.DEF count=R16
.DEF tccr1b_on=R17
.DEF tccr1b_off=R18
.DEF zero=R19
.DEF temp=R20

.ORG 0x13

begin:

ldi zero, 0
ldi count, 20
ldi tccr1b_on, 0b00011011; 0001 1011
ldi tccr1b_off, 0b00011000; 0001 1000

;configure stack
ldi temp, HIGH(RAMEND)
out SPH, temp
ldi temp, LOW(RAMEND)
out SPL, temp

.MACRO led_on
sbi PORTB, 1
.ENDMACRO

.MACRO led_off
cbi PORTB, 1
.ENDMACRO

;configure LED pin
sbi DDRB, 1; PB1 is an output pin
led_off

;configure button pin and interrupt
cbi DDRD, 2; PD2 is an input pin (INT0)
sbi PORTD, 2; pull up resistor enabled
ldi temp, 0b00000010; 0000 0010
out MCUCR, temp; falling edge triggered interrupt (on button press)
ldi temp, 0b01000000; 0100 0000
out GICR, temp; enable interrupt for int0


;configure timer and timer interrupt
out TCCR1A, zero
out TCCR1B, tccr1b_off

ldi temp, 0x3d; time = 0x3d09
out ICR1H, temp
ldi temp, 0x09
out ICR1L, temp

.MACRO timer_reset
out TCNT1H, zero
out TCNT1L, zero
.ENDMACRO

.MACRO timer_start
out TCCR1B, tccr1b_on
.ENDMACRO

.MACRO timer_stop
out TCCR1B, tccr1b_off
.ENDMACRO

ldi temp, 0b00100000; 0010 0000
out TIMSK, temp; enable timer interrupt

timer_reset

;Global interrupt enable
sei

halt:
rjmp halt

ISR_button:
	led_on
	ldi count, 20
	timer_start
	reti

ISR_timer:
	dec count
	brne not_over_yet
	over:
	timer_stop
	timer_reset
	reti
	not_over_yet:
	led_on
	sbrc count, 0; skip if count is even
	led_off; only done if count is odd
	reti


.ORG 0x00
rjmp begin
.ORG 0x01
rjmp ISR_button
.ORG 0x05
rjmp ISR_timer

