;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fireball
;; By Sonikku.
;; Modified slightly by RussianMan
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FireballTiles:
	db $2C,$2D,$2C,$2D

FireballProps:
	db $04,$04,$C4,$C4

print "MAIN ",pc
	PHB : PHK : PLB
	LDA $9D
	BEQ Continue
	JMP Graphics

Continue:
	LDA !extended_y_low,x
	CMP $1C
	LDA !extended_y_high,x
	SBC $1D
	BEQ NotOffscreen
	STZ !extended_num,x
	PLB
	RTL

NotOffscreen:
	INC !extended_table,x
	;%ExtendedHurt()
	JSR Interaction
	LDA $173D|!Base2,x
	CMP #$30
	BPL .enoughGravity
	CLC : ADC #$04
	STA $173D|!Base2,x
.enoughGravity
	;%ExtendedBlockInteraction()
	JSR ObjCollision
Fireball:
	BCC .inAir
	INC $175B|!Base2,x
	LDA $175B|!Base2,x
	CMP #$02
	BCS .hitTwoObjects
	LDA $1747|!Base2,x
	BPL .plus
	LDA $0B
	EOR #$FF : INC A
	STA $0B
.plus
	LDA $0B
	CLC : ADC #$04
	TAY
	LDA.w .data_029F99,y
	STA $173D|!Base2,x
	LDA !extended_y_low,x
	SEC : SBC.w .data_029FA2,y
	STA !extended_y_low,x
	BCS .updatePos
	DEC !extended_y_high,x
	BRA .updatePos

.data_029F99
	db $00,$B8,$C0,$C8,$D0,$D8,$E0,$E8,$F0
.data_029FA2
	db $00,$05,$03,$02,$02,$02,$02,$02,$02

.hitTwoObjects
	LDA #$01
	STA $1DF9|!Base2
	LDA #$0F
	STA $176F|!Base2,x
	LDA #$01
	STA !extended_num,x
	JMP Graphics

.inAir
	STZ $175B|!Base2,x
.updatePos
	LDY #$00
	LDA $1747|!Base2,x
	BPL +
        DEY
+   CLC : ADC !extended_x_low,x
	STA !extended_x_low,x
	TYA
	ADC !extended_x_high,x
	STA !extended_x_high,x
	%SpeedY()
Graphics:
	%ExtendedGetDrawInfo()
	LDA $1747|!Base2,x
	AND #$80
	LSR A
	STA $03
	LDA !extended_behind,x
	STA $00
	LDA $01
	STA $0200|!Base2,y
	LDA $02
	STA $0201|!Base2,y
	LDA !extended_table,x
	LSR #2
	AND #$03
	TAX
	LDA.w FireballTiles,x
	STA $0202|!Base2,y
	LDA.w FireballProps,x
	EOR $03
	ORA $64
	LDX $00
	BEQ +
        AND #$CF
        ORA #$10
+   STA $0203|!Base2,y
	TYA
	LSR #2
	TAY
	LDA #$00
	STA $0420|!Base2,y
	LDX $15E9|!Base2
	PLB
	RTL

ObjCollision:
PHK				;%ExtendedBlockInteraction() is broken iirc.
PEA.w .Re-1			;
PEA.w $02A772|!BankB-1		;
JML $02A56E|!BankB		;

.Re
RTS				;

;%ExtendedHurt also isn't good (for 8x8)
Interaction:
JSR GetExClipping

JSL $03B664|!BankB		;get mario's clipping

JSL $03B72B|!BankB		;
BCC .DiffRe			;

PHB
				;
LDA.b #$02			;	
PHA
				;
PLB
				;
PHK
				;
PEA.w .return-1
			;
PEA.w $B889-1
			;
JML $02A469|!BankB		
;hurt mario

.return
	
PLB				;

.DiffRe
RTS				;

GetExClipping:
LDA $171F|!Base2,x		;Get X position
;SEC				;Calculate hitbox
;SBC #$02			;
STA $04				;

LDA $1733|!Base2,x		;
;SBC #$00			;Take care of high byte
STA $0A				;

LDA #$06			;width
STA $06				;

LDA $1715|!Base2,x		;Y pos
CLC				;
ADC #$02			;
STA $05				;

LDA $1729|!Base2,x		;
ADC #$00			;
STA $0B				;

LDA #$06			;length
STA $07				;
RTS				;
