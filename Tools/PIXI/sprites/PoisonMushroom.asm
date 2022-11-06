;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; Poison Mushroom, by imamelia (rewritten by kaizoman/thomas)
;
; This is the poison mushroom sprite from SMB1.
; It is different from the existing one; it acts more like the original.
;
; Uses extra bit: YES
;  - If the extra bit is set, the mushroom will kill the player,
;    otherwise it will just damage the player
;
; Extra bytes: 0
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; defines and tables
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

!XSpd		= $10	; how fast it moves horizontally
!Tile		= $00	; tile number to use, properties are defined in the JSON
!GFX_FileNum = $7C


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; main routine wrapper
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

print "MAIN ",pc
	PHB
	PHK
	PLB
	JSR Main
	PLB
print "INIT ",pc
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; main routine
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Main:
	LDA $64 : STA $03
	LDA !1540,x
	BEQ NotBeingSpawned
	
	CMP #$36
	LDA #$F9
	BCS .SetYSpd
	JSL $019138|!BankB		; process object interaction
	LDA !1528,x
	BNE .NoPriorityChange
	LDA #$10 : STA $03
  .NoPriorityChange:
	JSR SubGFX
	LDA #$FC
  .SetYSpd:
	STA !AA,x
	LDA $9D
	BNE .Return
	JSL $01801A|!BankB		; update y position, no gravity
  .Return
	RTS



NotBeingSpawned:
	JSR SubGFX
	
	LDA !14C8,x
	EOR #$08
	ORA $9D
	BNE Return
	LDA #$00
	%SubOffScreen()

	LDA !AA,x
	BMI .InAir
	LDA !1588,x
	BIT #$04
	BEQ .InAir
	LDA #$00
	LDY !1588,x
	BPL +
	LDY !15B8,x
	BEQ +
	LDA #$18
  + STA !AA,x
  .InAir:
  
	LDA !1588,x
	BIT #$08
	BEQ .NotHittingCeiling
	STZ !AA,x
  .NotHittingCeiling:
	
	BIT #$03
	BEQ .NotHittingSide
	LDA !157C,x
	EOR #$01
	STA !157C,x
  .NotHittingSide:
	
	LDA #!XSpd
	LDY !157C,x
	BEQ +
	LDA.b #$100-!XSpd
  +	STA !B6,x
  
	JSL $01802A|!BankB		; update X/Y pos, apply gravity, process object interaction
	JSL $01A7DC|!BankB		; process Mario interaction
	BCC Return
	LDA $1490|!Base2
	ORA $1497|!Base2
	ORA $1493|!Base2
	BNE .disappear
	%BES(+)    ; if extra bit is set
	JSL $00F5B7|!bank  ; if not set, only hurt
	BRA ++
	+
	JSL $00F606|!bank  ; kill the player
	++
  .disappear:
	STZ !14C8,x
Return:
	RTS



;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; graphics routine
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SubGFX:

	lda #!GFX_FileNum        ; find or queue GFX
	%FindAndQueueGFX()
	bcs .gfx_loaded
	rts                      ; don't draw gfx if ExGFX isn't ready
.gfx_loaded
	%GetDrawInfo()
	LDA $00 : STA $0300|!Base2,y
	LDA $01 : STA $0301|!Base2,y
	PHX
    LDX.b #!Tile            ;\ Set the tile number.
	lda !dss_tile_buffer,x
	PLX
	STA $0302|!Base2,y
	LDA !15F6,x
	ORA $03
	STA $0303|!Base2,y
	
	LDY #$02
	LDA #$00
	JSL $01B7B3|!BankB		; set size/high x bit
	RTS
