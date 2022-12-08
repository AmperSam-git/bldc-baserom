db $42
JMP + : JMP + : JMP + : JMP ++ : JMP ++ : JMP ++ : JMP ++
JMP + : JMP + : JMP +

+:
	STZ $19				;> remove player's powerup
	STZ $0DC2|!addr 	;> remove player's item
	STZ $1407|!addr		;> remove cape flight
	STZ $13E0|!addr		;> reset pose
	LDA $13ED|!addr		;\
	AND #%01111111		;| remove slide state
	STA $13ED|!addr		;/
	lda #$01 			;\ give i-frames
    sta $1497|!addr     ;/

++:
	RTL

print "Block that removes any powerup or item from Mario as well as flight state"