;======================================================================
;
;Iambic morse keyer - Owen Duffy
;
;Ocillator at 8Khz gives 10wpm (110ms dit duration). 
;Rext should be between 3K and 100K.
;Using a 50K pot with series R of 3.3K and 0.0047uF (3.1KHz - 47KHz)
;
; $Log: not supported by cvs2svn $
; Revision 1.3  2001/05/01 12:29:47  owen
; Added latched paddle input during rest time.
;
; Revision 1.2  2001/04/30 23:34:12  owen
; Revised dit timing to 110mS. V1.2
;
; Revision 1.1.1.1  2001/04/30 23:15:30  owen
; Initial load of V1.1.
;
;
;======================================================================
	__CONFIG _MCLRE_OFF & _CP_ON & _WDT_OFF & _ExtRC_OSC
	LIST	P=PIC12C508A,mm=on
	RADIX	hex

#include "p12C508A.inc"

;flgs bits mask
IL	equ	02h		;iambic dash flag
IC	equ	03h		;in character

;port mask definitions
;the next 3 MUST be at those absolute addresses for the indirect jump
DITSW	equ	00h		;dot switch (on paddle key)
DAHSW	equ	01h		;dash switch (on paddle key)
AS	equ	02h		;auto character spacing
TX	equ	04h		;keying output

;timing calibration values
DAH	equ	0xda		;counts for dah
DIT	equ	0x47		;counts for dit
REST	equ	0x44		;counts for dit rest
ASPACE	equ	0x47		;counts for char space

	cblock	0x07
        flgs
        timer1
	endc
;======================================================================
	org	0x0
	goto	start
	org	0x40		;leave unprotected memory unused
;======================================================================
start
	movlw	0		;setup the options bits
	option
	clrw                    ;clear everything
	movwf   GPIO 
	clrf	flgs
	movlw	~(1<<TX)        ;mask for TRIS for output pin
	andlw	0x3f	        ;mask lower 6 bits
	tris	GPIO	        ;and turn it on
	goto	next

rest
        movlw   REST            ;put element duration in W
	call delay
next

;value used to jump into jump table
;bit	use
;0	dit
;1	dah
;2	il
;3	ic

	movfw	GPIO
	andlw	0x3	        ;mask lower 2 bits
	iorwf	flgs,w		;or in the flgs
	addwf	PCL,f		;computed goto

jtable
	goto	dit
	goto	dah
	goto	dit
	goto	next

	goto	dah
	goto	dah
	goto	dit
	goto	next

	goto	dit
	goto	dah
	goto	dit
	goto	aspace

	goto	dah
	goto	dah
	goto	dit
	goto	aspace

aspace
	clrf	flgs
 	movlw	ASPACE		;prepare for end of character delay
	call	delay
        goto    rest

dit
	bsf	GPIO,TX		;key tx on
        movlw   DIT             ;prepare for dit
	bsf	flgs,IL		;iambic long flag
        call    delay           ;and delay
	bcf	GPIO,TX		;key tx off
	goto	rest

dah  
	bsf	GPIO,TX		;key tx on
	movlw   DAH             ;prepare for dah
	bcf	flgs,IL		;iambic long flag
        call    delay           ;and delay
	bcf	GPIO,TX		;key tx off
	goto	rest

;======================================================================
;delays (spins) for number of clicks in reg W
;3 cycles per click, 1.5mS at 8KHz (10wpm)
delay
	movwf	timer1
	decfsz	timer1,1
	goto	$-1
	retlw	0
;======================================================================
	end
