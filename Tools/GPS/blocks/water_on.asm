db $42
JMP + : JMP + : JMP + : JMP ++ : JMP ++ : JMP ++ : JMP ++ : JMP + : JMP + : JMP +

+:
	LDA #$01
	STA $85
	LDA #$80
	STA $190E|!addr
++:
	RTL

print "Turns on water level flag and sprite buoyancy when touched."