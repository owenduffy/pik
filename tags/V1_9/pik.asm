;======================================================================
;
;Iambic morse keyer - Owen Duffy
;
;Ocillator at 10Khz gives 10wpm (110ms dit duration). 
;Rext should be between 3K and 100K.
;Using a 25K pot with series R of 3.3K and 0.0039uF (7KHz - 60KHz)
;
; $Log: not supported by cvs2svn $
; Revision 1.8  2001/05/13 06:25:15  owen
; Revised to product ~TX output in addition to TX, pin reassignment, renamed.
;
; Revision 1.7  2001/05/10 11:18:52  owen
; Added dot and dash look ahead as per ACCU-KEYER.
;
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


;port & flgs mask definitions
;these equates must be contiguous from 0
DITSW	equ	0		;dot switch (on paddle key)
DAHSW	equ	DITSW+1		;dash switch (on paddle key)
IL	equ	DAHSW+1		;iambic dash flag
IC	equ	IL+1		;in character

TXI	equ	0x2
AS	equ	0x3		;auto character spacing
TX	equ	0x4		;keying output

;timing calibration values
DAH	equ	0xa3		;counts for dah
DIT	equ	0x35		;counts for dit
REST	equ	0x32		;counts for dit rest
ASPACE	equ	0x6a		;counts for char space

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
	clrw			;setup the options bits
	option
	movlw	1<<TXI		;initialise GPIO
	movwf   GPIO 
	movlw	~(1<<TX | 1<<TXI) ;mask for TRIS for output pins
	tris	GPIO	        ;and turn it on
	clrf	flgs
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
	andlw	1<<DITSW | 1<<DAHSW ;mask paddle bits
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

dit	bsf	GPIO,TX		;tx hi
	bcf	GPIO,TXI	;txi lo
 	clrf	paddle		;clear the paddle latch
 	comf	paddle,f
        movlw   DIT             ;prepare for dit
	bsf	flgs,IL		;iambic long flag
        call    delay           ;and delay
	bcf	GPIO,TX		;tx lo
	bsf	GPIO,TXI	;txi hi

 	btfss	GPIO,AS		;is autospace on
 	bsf	flgs,IC		;set in character flag
        movlw   REST            ;put element duration in W
	call delay
	movfw	paddle		;get paddle latch
	iorlw	1<<DITSW        ;ignore dit bit
	nop
	nop
	nop
	goto	route1

dah	bsf	GPIO,TX		;tx hi
	bcf	GPIO,TXI	;txi lo
 	clrf	paddle		;clear the paddle latch
 	comf	paddle,f
	movlw   DAH             ;prepare for dah
	bcf	flgs,IL		;iambic long flag
        call    delay           ;and delay
	bcf	GPIO,TX		;tx lo
	bsf	GPIO,TXI	;txi hi

 	btfss	GPIO,AS		;is autospace on
 	bsf	flgs,IC		;set in character flag
        movlw   REST            ;put element duration in W
	call delay
	movfw	paddle		;get paddle latch
	iorlw	1<<DAHSW        ;ignore dah bit
	nop
	nop
	nop
	goto	route1
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