db $42
JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP FIAR
JMP Return : JMP Return : JMP Return

FIAR:
	%fireball_smoke()

	REP #$10
	LDX.w #$001F ; Map16 tile the ice block should turn into
	%change_map16()
	SEP #$10

Return:
	RTL

print "A frozen door."
