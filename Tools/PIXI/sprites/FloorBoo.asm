;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Floor Boo / Stretch by dtothefourth
;;  Based on the Sparky disassembly by imamelia
;;
;;  A boo sprite that follows walls while hidden and
;;  then briefly pops out
;;
;;  Uses 4 extra bytes
;;
;;  Extra Byte 1 - Hide Time
;;		How long the boo stays hidden, in 4 frame increments
;;
;;  Extra Byte 2 - Extend Time
;;		How many frames the boo stays out in 4 frame increments
;;
;;  Extra Byte 3 - Movement Speed
;;		How quickly the boo moves around
;;
;;  Extra Byte 4 - Wall Follow
;;		If not 0, boo moves along floors while hidden
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!GFX_FileNum = $85		;EXGFX number for this sprite

InitXSpeed:
db $08,$00
InitYSpeed:
db $00,$08

XSpeed:
db $01,$FF,$FF,$01,$FF,$01,$01,$FF
YSpeed:
db $01,$01,$FF,$FF,$01,$01,$FF,$FF

XSpeed2:
db $10,$00,$F0,$00,$F0,$00,$10,$00
YSpeed2:
db $00,$10,$00,$F0,$00,$10,$00,$F0

ObjCheckVals:
db $01,$04,$02,$08,$02,$04,$01,$08

ObjCheckVals2:
db $04,$02,$08,$01,$04,$01,$08,$02

Reversed:
db $04,$07,$06,$05,$00,$03,$02,$01

HTiles:
db $00,$01,$02,$03,$04,$05,$0C
VTiles:
db $06,$07,$08,$09,$0A,$0B,$0C

;HTiles:
;db $80,$82,$84,$86,$88,$8A,$8C
;VTiles:
;db $A0,$A2,$A4,$A6,$A8,$AA,$AC


print "INIT ",pc
	PHB
	PHK
	PLB
	JSR InitSparky
	PLB
	RTL

InitSparky:

	STZ !1510,x ; Pop-up phase
	LDA !extra_byte_1,x
	STA !1602,x ; Pop-up timer
	

	LDA !E4,x	; sprite X position
	LDY #$00		;
	AND #$10	;
	EOR #$10		;
	STA !151C,x	;
	BNE StartOutLeft	; move right if the sprite is on an odd X coordinate
	INY		;
StartOutLeft:	;
	LDA InitXSpeed,y	;
	STA !B6,x		; set the sprite's initial X speed
	LDA InitYSpeed,y	;
	STA !AA,x	; set the sprite's initial Y speed
	INC !164A,x	;
	LDA !151C,x	;
	LSR #2
	STA !C2,x	;

	RTS


print "MAIN ",pc
	PHB : PHK : PLB : JSR Main : PLB
	RTL

Main:
	JSL $018032|!BankB	; interact with sprites
	JSL $01ACF9|!BankB	; get a random number
	ORA $9D		;
	BNE NoSet1	; if sprites are locked or the number was not 0...
	LDA #$0C		; don't set this timer
	STA !1558,x	;
NoSet1:		;
     
	LDA !14C8,x	;
	CMP #$08		; if the sprite is still alive...
	BEQ StillAlive	; skip this termination code
	STZ !1528,x	;
	LDA #$FF		;
	STA !1558,x	; reset this timer
Return0:		;
	RTS

StillAlive:		
	LDA $9D		; if sprites are locked...
	BEQ +
	
	JSR SubGFX

	BRA Return0	; return
	+
	%SubOffScreen()


	LDA !1540,x	;
	ORA !1510,x
	BNE Skip1		; branch if the timer is set

	LDY !C2,x	;
	LDA YSpeed,y	; set the sprite's Y speed
	STA !AA,x	;
	LDA XSpeed,y	; set the sprite's X speed
	STA !B6,x		;

	JSL $019138|!BankB	; interact with objects

	LDA !1588,x	; check the sprite's object status
	AND #$0F	; if the sprite is touching an object...
	BNE Skip1		; branch

	LDA #$08		;
	STA !1564,x	; disable contact with other sprites
	LDA #$0D		; timer = 0D
	STA !1540,x	;

Skip1:		;

	JMP ShowHide

CheckTimer1:	;
	JSR SubGFX

	JMP WallFollow

SubGFX:

	LDA !1510,x
	BNE +
	RTS
	+
	lda #!GFX_FileNum        ; find or queue GFX
	%FindAndQueueGFX()
	bcs .gfx_loaded
	rts                      ; don't draw gfx if ExGFX isn't ready	
.gfx_loaded
	%GetDrawInfo()

	LDA !C2,x
	AND #$01
	BEQ +
	JMP VertGFX
	+

	LDA !D8,x
	EOR #$FF
	INC
	AND #$0F
	CMP #$08
	BCC +
	ORA #$F0
	+
	CLC
	ADC $01
	STA $01

	LDA #$33
	STA $03

	LDA !C2,x
	AND #$03
	CMP #$02
	BNE +

	DEC $01

	LDA #$B3
	STA $03
	+

	LDA !C2,x
	BEQ ++
	CMP #$06
	BNE +
	++
	LDA $03
	ORA #$40
	STA $03

	+


	LDA !1510,x
	CMP #$03
	BNE +
	LDA !1602,x
	LSR #2
	BRA +++
	+
	DEC
	BNE +

	LDA !1602,x
	LSR #2
	CMP #$05
	BCC ++
	+++
	AND #$01
	CLC
	ADC #$03
	++
	PHX
	TAX
	LDA HTiles,X
	TAX
	lda !dss_tile_buffer,x
	STA $02
	PLX

	BRA ++
	+

	LDA !1602,x
	LSR #2
	CMP #$06
	BCC +++
	LDA #$05
	+++

	PHX
	TAX
	STA $02
	LDA HTiles,X
	TAX
	lda !dss_tile_buffer,x
	STA $02
	PLX

	++

	LDA $00
	STA $0300|!addr,y
	LDA $01
	STA $0301|!addr,y
	LDA $02
	STA $0302|!addr,y
	LDA $03
	STA $0303|!addr,y
	LDA #$00
	LDY #$02
	JSL $01B7B3|!BankB
	RTS

VertGFX:

	DEC $01

	LDA !E4,x
	EOR #$FF
	INC
	AND #$0F
	CMP #$08
	BCC +
	ORA #$F0
	+
	CLC
	ADC $00
	STA $00

	LDA #$33
	STA $03

	LDA !C2,x
	CMP #$07
	BEQ ++
	CMP #$01
	BNE +
	++
	LDA #$73
	STA $03
	+

	LDA !C2,x
	CMP #$01
	BEQ ++
	CMP #$05
	BNE +
	++
	LDA $03
	ORA #$80
	STA $03

	+


	LDA !1510,x
	CMP #$03
	BNE +
	LDA !1602,x
	LSR #2
	BRA +++
	+
	DEC
	BNE +

	LDA !1602,x
	LSR #2
	CMP #$05
	BCC ++
	+++
	AND #$01
	CLC
	ADC #$03
	++
	PHX
	TAX
	LDA VTiles,X
	TAX
	lda !dss_tile_buffer,x
	STA $02
	PLX

	BRA ++
	+

	LDA !1602,x
	LSR #2
	CMP #$06
	BCC +++
	LDA #$05
	+++

	PHX
	TAX
	STA $02
	LDA VTiles,X
	TAX
	lda !dss_tile_buffer,x
	STA $02
	PLX

	++

	LDA $00
	STA $0300|!addr,y
	LDA $01
	STA $0301|!addr,y
	LDA $02
	STA $0302|!addr,y
	LDA $03
	STA $0303|!addr,y
	LDA #$00
	LDY #$02
	JSL $01B7B3|!BankB
	RTS




ShowHide:
	LDA !1510,x
	BEQ +

	DEC
	BNE ++

	JMP Show
	++
	DEC
	BNE ++
	JMP Hide
	++
	JMP Run

	+


	LDA !1602,x
	BNE +

	LDA !extra_byte_4,x
	BEQ ++++

	LDA !C2,X
	AND #$01
	BEQ +++

	LDA !D8,x
	AND #$0F
	BNE ++
	BRA ++++

	+++
	LDA !E4,x
	AND #$0F
	BNE ++

	++++
	INC !1510,x

	LDY !C2,x		;
	LDA YSpeed2,y		; set the sprite's Y speed
	BEQ +++
	JSR GetSpeed
	+++
	STA !AA,x		;
	LDA XSpeed2,y		;
	BEQ +++
	JSR GetSpeed
	+++
	STA !B6,x			

	BRA Show

	+

	LDA $13
	AND #$03
	BNE ++

	LDA !1602,x
	DEC
	STA !1602,x
	++
	JMP CheckTimer1

Show:

	JSR SubGFX

	LDA !1602,x
	INC
	CMP #$14
	BNE +

	LDA !C2,x
	STA !160E,x

	INC !1510,x
	INC !1510,x
	LDA !extra_byte_2,x

	+
	STA !1602,x

	RTS

Hide:
	JSR SubGFX

	LDA !1602,x
	CMP #$20
	BCC +
	JSL $01A7DC|!BankB	; interact with the player
	LDA !1602,x
	+

	DEC
	BNE +

	LDA !160E,x
	STA !C2,x

	STZ !1510,x
	LDA !extra_byte_1,x

	+
	STA !1602,x

	RTS

Run:
	JSL $01A7DC|!BankB	; interact with the player
	JSR SubGFX

	LDA !1602,x
	INC
	CMP !extra_byte_2,x
	BNE +

	DEC !1510,x
	LDA #$30

	+
	STA !1602,x

	JSL $018022|!BankB		; update sprite X position without gravity
	JSL $01801A|!BankB		; update sprite Y position without gravity


	LDA !AA,x
	PHA
	LDA !B6,x
	PHA
	LDA !E4,x
	PHA
	LDA !14E0,x
	PHA
	LDA !D8,x
	PHA
	LDA !14D4,x
	PHA


	LDY !C2,x	;
	LDA YSpeed,y	; set the sprite's Y speed
	STA !AA,x	;
	LDA XSpeed,y	; set the sprite's X speed
	STA !B6,x		;

	JSL $019138|!BankB	; interact with objects

	PLA
	STA !14D4,x
	PLA
	STA !D8,x
	PLA
	STA !14E0,x
	PLA
	STA !E4,x
	PLA
	STA !B6,x
	PLA
	STA !AA,x





	print "check ",pc

	LDA !C2,X
	TAY
	LDA ObjCheckVals,y
	STA $00

	LDA !C2,X
	TAY
	LDA ObjCheckVals2,y
	STA $01

	LDA !1588,x
	BIT $00
	BEQ +
	
	JSR Reverse
	RTS

	+

	LDA !1588,x
	BIT $01
	BNE +
	
	JSR Reverse
	+	
	RTS

Reverse:
	LDA !AA,x
	EOR #$FF
	INC
	STA !AA,x
	LDA !B6,x
	EOR #$FF
	INC
	STA !B6,x
	LDA !C2,x
	TAY
	LDA Reversed,y
	STA !C2,x
	RTS


WallFollow:
	LDA !extra_byte_4,x
	BNE +
	RTS
	+

	LDA #$08		; check value = 08
	CMP !1540,x	; if the timer has reached the check value...
	BNE NoChangeState	;
	INC !C2,x	; change the sprite state
	LDA !C2,x	;
	CMP #$04		; if the sprite state has reached 04...
	BNE NoResetState	;
	STZ !C2,x	; reset it to 00
NoResetState:	;
	CMP #$08		; if it is 08...
	BNE NoChangeState	;
	LDA #$04		; set it to 04
	STA !C2,x	;

NoChangeState:	;
	LDY !C2,x		;
	LDA !1588,x		; check the object contact status
	AND ObjCheckVals,y	; depending on the sprite state
	BEQ Skip2			; if the sprite isn't touching the specified surface, skip the next part
	LDA #$08			;
	STA !1564,x		; disable contact with other sprites for a few frames
	DEC !C2,x		; decrement the sprite state
	LDA !C2,x		;
	BPL CompareState1		; if the result was positive, branch
	LDA #$03			;
	BRA StoreState1		; set the sprite state to 03

CompareState1:		;
	CMP #$03			;
	BNE Skip2			;
	LDA #$07			;
StoreState1:		;
	STA !C2,x		;

Skip2:			;
	LDY !C2,x		;
	LDA YSpeed2,y		; set the sprite's Y speed
	STA !AA,x		;
	LDA XSpeed2,y		;
	STA !B6,x			;

	JSL $018022|!BankB		; update sprite X position without gravity
	JSL $01801A|!BankB		; update sprite Y position without gravity
	RTS	

GetSpeed:
	BMI +
	LDA !extra_byte_3,x
	RTS
	+
	LDA !extra_byte_3,x
	EOR #$FF
	INC
	RTS
	

