db $42
JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP FIAR
JMP Return : JMP Return : JMP Return

FIAR:
	%fireball_smoke()

	PHY
	LDA #$0E			;\
	STA $9C				;| Generate note block
	JSL $00BEB0|!bank	;/
	PLY

Return:
	RTL

print "A frozen note block."
