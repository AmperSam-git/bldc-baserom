db $42
JMP + : JMP + : JMP + : JMP ++ : JMP ++ : JMP ++ : JMP ++ : JMP + : JMP + : JMP +

+:
	STZ $85
	STZ $190E|!addr
++:
	RTL

print "Turns off water level flag and sprite buoyancy when touched."