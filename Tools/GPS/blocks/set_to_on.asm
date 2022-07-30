db $42

JMP + : JMP + : JMP + : JMP + : JMP +
JMP ++ : JMP + : JMP + : JMP + : JMP +

+:
	LDA $14AF|!addr
	BEQ ++

	DEC $14AF|!addr	;set switch to on
	LDA #$0B
	STA $1DF9|!addr	;sound number
++:
	RTL

print "A button that sets the on/off status to on."