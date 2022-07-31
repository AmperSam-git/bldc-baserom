;Usage: %fireball_smoke()

	PHY
	PHP
	SEP #$30
	STZ $170B|!addr,x
	
	LDY #$03
.loop
	LDA $17C0|!addr,y
	BEQ .found
	
	DEY
	BPL .loop
	BRA +

.found
	LDA #$01
	STA $17C0|!addr,y
	
	LDA $1715|!addr,x
	STA $17C4|!addr,y
	
	LDA $171F|!addr,x
	STA $17C8|!addr,y
	
	LDA #$18
	STA $17CC|!addr,y
	
+	PLP
	PLY
	RTL
