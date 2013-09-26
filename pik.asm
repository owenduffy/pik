;
;Iambic morse keyer
;
;Copyright 2001 Owen Duffy.
;
;======================================================================
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;======================================================================
;Ocillator at 10Khz gives 10wpm (122ms dit duration). 
;Rext should be between 3K and 100K.
;Using a 25K pot with series R of 3.3K and 0.0047uF (7KHz - 48KHz)
;
;======================================================================

 	ifdef __12C508
	__CONFIG _MCLRE_OFF & _CP_ON & _WDT_OFF & _ExtRC_OSC
	#include "p12C508.inc"
	LIST	P=12C508,mm=on
	endif

	ifdef __12C508A
	__CONFIG _MCLRE_OFF & _CP_ON & _WDT_OFF & _ExtRC_OSC
	#include "p12C508A.inc"
	LIST	P=12C508A,mm=on
	endif

	ifdef __12F509
	__CONFIG _MCLRE_OFF & _CP_ON & _WDT_OFF & _ExtRC_OSC
	#include "p12F509.inc"
	LIST	P=12F509,mm=on
	endif

	ifdef __12CE519
	__CONFIG _MCLRE_OFF & _CP_ON & _WDT_OFF & _ExtRC_OSC
	#include "p12CE519.inc"
	LIST	P=12CE519,mm=on
	endif

	ifdef __12F510
	#include "p12F510.inc"
	__CONFIG _MCLRE_OFF & _CP_ON & _WDT_OFF & _ExtRC_OSC & _IOSCFS_OFF
	LIST	P=12F510,mm=on
	endif

	__IDLOCS	h'1'
	RADIX	hex


;port & flgs mask definitions
;these equates must be contiguous from 0
DITSW	equ	0		;dot switch (on paddle key)
DAHSW	equ	DITSW+1		;dash switch (on paddle key)
IL	equ	DAHSW+1		;iambic dash flag
IC	equ	IL+1		;in character

AS	equ	0x3		;auto character spacing
TX	equ	0x4		;keying output

;timing calibration values
DAH	equ	0xb5		;counts for dah
DIT	equ	0x3b		;counts for dit
REST	equ	0x39		;counts for dit rest
ASPACE	equ	0x76		;counts for char space

	cblock	0x0a
        flgs
        timer1
		paddle
	endc
;======================================================================
	org	0x0
	goto	start
	data	'P','I','K',' ','V','1','.','1','5'
	org	0x40		;leave unprotected memory unused
;======================================================================
start
	ifdef __12F510
	movlw	~(1<<C1ON)	;mask for comparator off
	andwf   CM1CON0
	movlw	~(1<<ANS1 | 1<<ANS0) ;mask for ADC off
	andwf   ADCON0
	endif
	clrw			;initialise GPIO
	movwf   GPIO
 	movlw	~(1<<TX)	;mask for TRIS for output pins
	tris	GPIO	        ;and activate outputs
	clrw			;setup the options bits
	option
	movlw	(1<<DAHSW|1<<DITSW) ;paddle pins
clrflgs	clrf	flgs

;value used to jump into jump table
;bit	use
;0	dit
;1	dah
;2	il
;3	ic

route	andwf	GPIO,w		;or in the paddle
	andlw	1<<DITSW|1<<DAHSW ;mask paddle bits
	iorwf	flgs,w		;or in the flgs
	addwf	PCL,f		;computed goto

jtable	goto	dit
	goto	dah
	goto	dit
	sleep

	goto	dah
	goto	dah
	goto	dit
	sleep

	goto	dit
	goto	dah
	goto	dit
	goto	aspace

	goto	dah
	goto	dah
	goto	dit
	goto	aspace

aspace	clrf	flgs
 	clrf	paddle		;clear the paddle latch
 	comf	paddle,f
 	movlw	ASPACE		;prepare for end of character delay
	call	delay
	movfw	paddle		;get paddle latch
	goto	route

dit	bsf	GPIO,TX		;tx hi
 	clrf	paddle		;clear the paddle latch
 	comf	paddle,f
        movlw   DIT             ;prepare for dit
	bsf	flgs,IL		;iambic long flag
        call    delay           ;and delay
	nop
	bcf	GPIO,TX		;tx lo

 	btfsc	GPIO,AS		;is autospace on
 	bsf	flgs,IC		;set in character flag
        movlw   REST            ;put element duration in W
	call delay
	movfw	paddle		;get paddle latch
	iorlw	1<<DITSW        ;ignore dit bit
	nop
	goto	route

dah	bsf	GPIO,TX		;tx hi
 	clrf	paddle		;clear the paddle latch
 	comf	paddle,f
	movlw   DAH             ;prepare for dah
	bcf	flgs,IL		;iambic long flag
        call    delay           ;and delay
	nop
	bcf	GPIO,TX		;tx lo

 	btfsc	GPIO,AS		;is autospace on
 	bsf	flgs,IC		;set in character flag
        movlw   REST            ;put element duration in W
	call	delay
	movfw	paddle		;get paddle latch
	iorlw	1<<DAHSW        ;ignore dah bit
	goto	route
;======================================================================
;delays (spins) for number of clicks in reg W
;5 cycles per click, 2.0mS at 10KHz (10wpm)
delay
	movwf	timer1
	movfw	GPIO		;read paddle
	andwf	paddle,f	;latch paddle
	decfsz	timer1,1
	goto	$-3
	retlw	0
;======================================================================
	end
