db $42
JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP FIAR
JMP Return : JMP Return : JMP Return

!Map16tileb	= $002E ; Bottom tile of regular Yoshi Coin
!Map16tilet	= $002D ; Top tile of regular Yoshi coin

FIAR:
	%fireball_smoke()

	REP #$30
	LDX.w #!Map16tileb
	%change_map16()
	%swap_XY()

	LDA $98
	SEC
	SBC #$0010
	STA $98

	LDX.w #!Map16tilet
	%change_map16()
	SEP #$30
Return:
	RTL

print "The bottom of a frozen Yoshi coin."
