db $42

JMP Return : JMP Return : JMP Return
JMP Return : JMP Return
JMP Return : JMP Return
JMP Return : JMP MarioInside : JMP Return

MarioInside:
	LDA $14AE|!addr	;   If a silver P-switch
	BNE Return		;   ...is active, return

	LDA $16			;\  Only enter the door if you press up.
	AND #$08		; |
	BEQ Return		;/

	LDA $8F			;\  Surprise: It's a backup of $72
	BNE Return		;/

	%door_approximity()
	BCS Return		;   Check if Mario is centered enough

	LDA #$0F		;\  Enter door SFX
	STA $1DFC|!addr	;/

	%teleport_direct()
Return:
RTL

print "A small Silver P-switch door."
