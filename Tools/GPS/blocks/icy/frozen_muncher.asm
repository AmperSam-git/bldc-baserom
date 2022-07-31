db $42
JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP FIAR
JMP Return : JMP Return : JMP Return

; Map16 tile the ice block should turn into
!Map16tile	= $012F

FIAR:
	%fireball_smoke()

	REP #$10
	LDX.w #!Map16tile
	%change_map16()
	SEP #$10

Return:
	RTL

print "A frozen version of tile ", hex(!Map16tile), "."
