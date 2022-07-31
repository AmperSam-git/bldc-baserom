db $42
JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP FIAR
JMP Return : JMP Return : JMP Return

FIAR:
	%fireball_smoke()

	PHY
	LDA #$06			;\
	STA $9C				;| Generate coin
	JSL $00BEB0|!bank	;/
	PLY

Return:
	RTL

print "A frozen coin."
