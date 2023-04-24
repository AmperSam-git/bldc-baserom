;Cloud Drop by smkdan (optimized by Blind Devil)

;will swoosh back and forth between an area defined by range.
;DOESN'T USE EXTRA BIT
;EXTRA PROP 1: Range.  Keep it sane or it'll rush offscreen.

!GFX_FileNum = $9C		;DSS ExGFX number

;Graphics defines:
; Horizontal
!Head1 =	$00	;head frame 1
!Head2 =	$01	;head frame 2
!Head3 =	$02	;head frame 3
!Head4 =	$03	;head frame 4
!Head5 =	$04	;head frame 5
!Tail =		$05	;tail

; Vertical
!VHead1 =	$06	;head frame 1
!VHead2 =	$07	;head frame 2
!VHead3 =	$08	;head frame 3
!VHead4 =	$09	;head frame 4
!VHead5 =	$0A	;head frame 5
!VTail  =	$0B	;tail


INCDECTBL:	db $FF,$01	;right, left.  Sub if going right, add if going left.
EORTBL:		db $00,$FF
TWOCTBL:	db $00,$01

print "INIT ",pc
	LDA #$01
	STA !157C,x	;going left

	LDA !7FAB28,x	;load range
	EOR #$FF
        STA $00
        LDA !7FAB10,x
        AND #$04
        BEQ +
        LDA $00
        STA !AA,x
	STZ !1570,x	;reset turning byte
	RTL
+       LDA $00
	STA !B6,x	;into speed
	STZ !1570,x	;reset turning byte
	RTL

print "MAIN ",pc
	PHB
	PHK
	PLB
	JSR Run
	PLB
	RTL	;also nothing

Run:
	LDA #$00
	%SubOffScreen()
	JSR GFX

	LDA !14C8,x
	EOR #$08
	ORA $9D			;locked sprites?
	ORA !15D0,x		;being eaten by yoshi?
	BNE Return

	; STZ !AA,x	;no Yspd ever

	LDA !1570,x	;turning byte..
	BEQ Keep_Moving
	INC !1570,x	;increment once each frame
	CMP #$13
	BNE Return_I	;return if it's hit the total frames

	LDA !157C,x	;change direction
	EOR #$01
	CLC
	STA !157C,x

        LDA !7FAB10,x
        AND #$04
        BEQ +
	LDA !7FAB28,x	;load range / original speed
	LDY !157C,x
	EOR EORTBL,y	;invert accordingly
	CLC
	ADC TWOCTBL,y	;two's complement adjustment
	STA !AA,x	;new xspd
        BRA ++
+	LDA !7FAB28,x	;load range / original speed
	LDY !157C,x
	EOR EORTBL,y	;invert accordingly
	CLC
	ADC TWOCTBL,y	;two's complement adjustment
	STA !B6,x	;new xspd

++	STZ !1570,x	;reset counter

	BRA Return_I	;interact

Keep_Moving:
	LDY !157C,x	;load direction..
        LDA !7FAB10,x
        AND #$04
        BEQ +
	LDA !AA,x	;load speed..
	CLC
	ADC INCDECTBL,y	;sub1 or add1 depedning on direction
	STA !AA,x	;new Xspd
	BNE Return_I	;not zero, return as normal
	LDA #$01
	STA !1570,x	;else start turning
        BRA Return_I
+	LDA !B6,x	;load speed..
	CLC
	ADC INCDECTBL,y	;sub1 or add1 depedning on direction
	STA !B6,x	;new Xspd
	BNE Return_I	;not zero, return as normal
	LDA #$01
	STA !1570,x	;else start turning

Return_I:
	JSL $018022|!BankB		;speed update
	JSL $01801A|!BankB		;speed update
	JSL $01A7DC|!BankB		;mario interact
	JSL $018032|!BankB		;sprites

Return:
	RTS

;=====

TILEMAP:	db !Head1,!Tail
		db !Head2,!Tail
		db !Head3,!Head3
		db !Head4,!Head4
		db !Head5,!Tail

XDISP:	db $00,$10
	db $00,$0D
	db $00,$00
	db $00,$00
	db $00,$F1

	db $00,$F0
	db $00,$F3
	db $00,$00
	db $00,$00
	db $00,$0F

YDISP:	db $00,$00
	db $00,$FE
	db $00,$00
	db $00,$00
	db $00,$00

PROP:	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$40

	db $40,$40
	db $40,$40
	db $40,$40
	db $40,$40
	db $40,$00

GFX:

	lda #!GFX_FileNum        ; find or queue GFX
	%FindAndQueueGFX()
	bcs .gfx_loaded
	rts                      ; don't draw gfx if ExGFX isn't ready

.gfx_loaded


	%GetDrawInfo()
	STZ $08		;reset
	STZ $06
	STZ $07
	STZ $05

	LDA !15F6,x	;store sprite properties
	STA $04

LDA !7FAB10,x
AND #$04
BEQ +
JML Vert
+
	LDA !157C,x	;flip
	BNE No_Mirror

	LDA #$0A	;skip past entries with no flip
	STA $06
	STA $05

No_Mirror:
	LDA !1570,x	;frame counter for sprite frames
	LSR #2		;each 8 frames
	ASL		;drop a bit, 2 bytes per entry
	STA $09		;add frame value to indexes

	LDA $08		;chr index
	CLC
	ADC $09
	STA $08
	LDA $06		;xindex
	CLC
	ADC $09
	STA $06
	LDA $07		;yindex
	CLC
	ADC $09
	STA $07
	LDA $05		;$05
	CLC
	ADC $09
	STA $05

	PHX		;preserve sprite index
	LDX #$00	;loop index zero

OAM_Loop:
	TXA
	CLC
	ADC $06
	PHX
	TAX
	LDA $00
	CLC
	ADC XDISP,x
	STA $0300|!Base2,y	;xpos
	PLX

	TXA			;loop index into A
	CLC
	ADC $07			;add index bits
	PHX			;preserve loop index
	TAX			;and we have a prepared YDISP index
	LDA $01
	CLC
	ADC YDISP,x
	STA $0301|!Base2,y	;ypos
	PLX			;restore loop index

 	TXA			;same process as seen above
 	CLC
 	ADC $08

 	PHX
 	TAX
 	LDA.w TILEMAP,x
 	TAX
 	lda.l !dss_tile_buffer,x
 	STA $0302|!Base2,y	;CHR
 	PLX

	TXA
	CLC
	ADC $05
	PHX
	TAX
	LDA PROP,x
	ORA $04
	ORA $64			;level bits
	STA $0303|!Base2,y
	PLX

	INY
	INY
	INY
	INY
	INX
	CPX #$02		;3 loops
	BNE OAM_Loop

	PLX			;restore sprite index

	LDY #$02		;16x16 tiles
	LDA #$01		;2 tiles
	JSL $01B7B3|!BankB	;bookkeeping
	RTS

VTILEMAP:	db !VHead1,!VTail
		db !VHead2,!VTail
		db !VHead3,!VHead3
		db !VHead4,!VHead4
		db !VHead5,!VTail

VXDISP:	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00

VYDISP:	db $00,$10
	db $00,$0B
	db $00,$00
	db $00,$00
	db $00,$F0

	db $00,$F0
	db $00,$F5
	db $00,$00
	db $00,$00
	db $00,$10

VPROP:	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$00
	db $00,$80

	db $80,$80
	db $80,$80
	db $80,$80
	db $80,$80
	db $80,$00

Vert:
	LDA !157C,x	;flip
	BNE .No_Mirror

	LDA #$0A	;skip past entries with no flip
	STA $06
	STA $05

.No_Mirror:
	LDA !1570,x	;frame counter for sprite frames
	LSR #2		;each 8 frames
	ASL		;drop a bit, 2 bytes per entry
	STA $09		;add frame value to indexes

	LDA $08		;chr index
	CLC
	ADC $09
	STA $08
	LDA $07		;xindex
	CLC
	ADC $09
	STA $07
	LDA $06		;yindex
	CLC
	ADC $09
	STA $06
	LDA $05		;$05
	CLC
	ADC $09
	STA $05

	PHX		;preserve sprite index
	LDX #$00	;loop index zero

.OAM_Loop:
	TXA
	CLC
	ADC $07
	PHX
	TAX
	LDA $00
	CLC
	ADC VXDISP,x
	STA $0300|!Base2,y	;xpos
	PLX

	TXA			;loop index into A
	CLC
	ADC $06			;add index bits
	PHX			;preserve loop index
	TAX			;and we have a prepared YDISP index
	LDA $01
	CLC
	ADC VYDISP,x
	STA $0301|!Base2,y	;ypos
	PLX			;restore loop index

	TXA			;same process as seen above
	CLC
	ADC $08

	PHX
	TAX
	LDA.w VTILEMAP,x
 	TAX
 	lda.l !dss_tile_buffer,x
	STA $0302|!Base2,y	;CHR
	PLX

	TXA
	CLC
	ADC $05
	PHX
	TAX
	LDA VPROP,x
	ORA $04
	ORA $64			;level bits
	STA $0303|!Base2,y
	PLX

	INY
	INY
	INY
	INY
	INX
	CPX #$02		;3 loops
	BNE .OAM_Loop

	PLX			;restore sprite index

	LDY #$02		;16x16 tiles
	LDA #$01		;2 tiles
	JSL $01B7B3|!BankB	;bookkeeping
	RTS