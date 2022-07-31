db $42
JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP FIAR
JMP Return : JMP Return : JMP Return

FIAR:
	%fireball_smoke()

	PHY
	LDA #$13			;\
	STA $9C				;| Generate on-off block block
	JSL $00BEB0|!bank	;/
	PLY

Return:
	RTL

print "A frozen ON-OFF block."
