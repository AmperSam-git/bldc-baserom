;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Passable Ledge
; By Sonikku (Original Blocktool version by S.N.N.)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

db $42
JMP Return : JMP PressDown : JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP PressDown : JMP Return : JMP Return

PressDown:
	LDA $72
	BNE Return	;if in the air, return

	LDA $16
	AND #$04
	BEQ Return	; If the player isn't tapping down, return

	LDA $96		; Move the player down 8 pixels
	CLC
	ADC #$08
	STA $96
	LDA $97
	ADC #$00
	STA $97

Return:
	RTL		; Return

print "A ledge that can be passed through by tapping down"