db $42
JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP FIAR
JMP Return : JMP Return : JMP Return

FIAR:
	%fireball_smoke()
	%erase_block()
Return:
	RTL

print "A frozen block that disappears when thawed."
