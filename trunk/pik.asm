;======================================================================
;
;Iambic morse keyer - Owen Duffy
;
;Ocillator at 8Khz gives 10wpm (110ms dit duration). 
;Rext should be between 3K and 100K.
;Using a 50K pot with series R of 3.3K and 0.0047uF (3.1KHz - 47KHz)
;
; $Log: not supported by cvs2svn $
; Revision 1.6  2001/05/06 09:24:34  owen
; Fixed broken autospace.
;
; Revision 1.5  2001/05/06 07:15:49  owen
; Restored broken autospace function
;
; Revision 1.4  2001/05/06 06:09:13  owen
; Removed scan of paddles during rest period.
;
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
DAH	equ	0x82		;counts for dah
DIT	equ	0x2a		;counts for dit
REST	equ	0x28		;counts for dit rest
ASPACE	equ	0x53		;counts for char space

	cblock	0x07
        flgs
        timer1
	paddle
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
	goto	route2

;value used to jump into jump table
;bit	use
;0	dit
;1	dah
;2	il
;3	ic

route1	andwf	GPIO,w		;or in the paddle
	goto	$+2
route2	movfw	GPIO
	andlw	0x3	        ;mask lower 2 bits
	iorwf	flgs,w		;or in the flgs
	addwf	PCL,f		;computed goto

jtable	goto	dit
	goto	dah
	goto	dit
	goto	route2

	goto	dah
	goto	dah
	goto	dit
	goto	route2

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
	goto	route1

dit	bsf	GPIO,TX		;key tx on
 	clrf	paddle		;clear the paddle latch
 	comf	paddle,f
        movlw   DIT             ;prepare for dit
	bsf	flgs,IL		;iambic long flag
        call    delay           ;and delay
	bcf	GPIO,TX		;key tx off

 	btfss	GPIO,AS		;is autospace on
 	bsf	flgs,IC		;set in character flag
        movlw   REST            ;put element duration in W
	call delay
	movfw	paddle		;get paddle latch
	iorlw	0x1	        ;overwrite dit bit
	nop
	goto	route1

dah	bsf	GPIO,TX		;key tx on
 	clrf	paddle		;clear the paddle latch
 	comf	paddle,f
	movlw   DAH             ;prepare for dah
	bcf	flgs,IL		;iambic long flag
        call    delay           ;and delay
	nop
	nop
	bcf	GPIO,TX		;key tx off

 	btfss	GPIO,AS		;is autospace on
 	bsf	flgs,IC		;set in character flag
        movlw   REST            ;put element duration in W
	call delay
	movfw	paddle		;get paddle latch
	iorlw	0x2	        ;overwrite dah bit
	nop
	goto	route1
;======================================================================
;delays (spins) for number of clicks in reg W
;5 cycles per click, 2.5mS at 8KHz (10wpm)
delay
	movwf	timer1
	movfw	GPIO		;read paddle
	andwf	paddle,f	;latch paddle
	decfsz	timer1,1
	goto	$-3
	retlw	0
;======================================================================
	end
