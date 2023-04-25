;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Cooligan's sunglasses. To be inserted as an EXTENDED sprite.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;properties of the glasses

	!GFX_FileNum = $A7 ; DSS ExGFX
	!Tile = $06		;16x16
	!Pal = $E
	!Page = $1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;extended sprite code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
	LDA $9D
	BNE Graphics

;custom gravity. the routine's values are pretty silly.
	LDA $173D|!addr,x
	CMP #$30
	BPL MaxYSpeed
	CLC
	ADC #$03
	STA $173D|!addr,x
	BRA UpdateYPos
MaxYSpeed:
	LDA #$30
	STA $173D|!addr,x

UpdateYPos:
	PHK
	PEA.w UpdateReturn-1
	PEA.w $B889-1
	JML $02B560|!bank
UpdateReturn:

Graphics:
    lda #!GFX_FileNum
    %FindAndQueueGFX()
    bcs .gfx_loaded
    rts
.gfx_loaded
	%ExtendedGetDrawInfo()

	LDA $01
	STA $0200|!addr,y
	LDA $02
	STA $0201|!addr,y
	LDA !dss_tile_buffer+!Tile
	STA $0202|!addr,y
	LDA #(!Pal-$8<<1)+!Page
	ORA $1765|!addr,x
	ORA $64
	STA $0203|!addr,y
	TYA
	LSR #2
	TAY
	LDA #$02
	STA $0420|!addr,y
	RTL