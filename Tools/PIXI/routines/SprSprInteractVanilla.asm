;This is the almost unaltered code located at $01A421, a slice of SMW's vanilla sprite<->sprite
;interaction. Must be called in a loop as seen in $01A417 and $01A4B0. Due to how it gives an output
;after each interaction, it can be extremely useful for arranging custom sprite<->sprite behaviors.

;Input:
;	x and y = sprite slots to run interaction for.
;		Note that originally x holds the other sprite's slot rather than itself, but I think the
;		opposite would work too.
;	C = run vanilla interaction code, c = don't (will only set the carry upon contact).
;Output:
;	C = the sprites have interacted, c = the sprites have not interacted.

	PHB : PHK : PLB
	PHP
	
	LDA !1686,x
	ORA !1686,y
	AND #$08   
	ORA !1564,x
	ORA !1564,y
	ORA !15D0,x
	ORA !1632,x
	EOR !1632,y
	BNE ?end
	STX $1695|!addr
	LDA !E4,x
	STA $00
	LDA !14E0,x
	STA $01
	LDA.w !E4,y
	STA $02
	LDA !14E0,y
	STA $03
	REP #$20
	LDA $00
	SEC
	SBC $02
	CLC
	ADC #$0010
	CMP #$0020
	SEP #$20
	BCS ?end
	LDY #$00
	LDA !1662,x
	AND.b #$0F
	BEQ ?+
	INY
?+	LDA !D8,x
	CLC
	ADC ?ytable,y
	STA $00
	LDA !14D4,x
	ADC #$00
	STA $01
	LDY $15E9|!addr
	LDX #$00
	LDA !1662,y
	AND #$0F
	BEQ ?+
	INX
?+	LDA.w !D8,y
	CLC
	ADC ?ytable,x
	STA $02
	LDA !14D4,y
	ADC #$00
	STA $03
	LDX $1695|!addr
	REP #$20
	LDA $00
	SEC
	SBC $02
	CLC
	ADC #$000C
	CMP #$0018
	SEP #$20	
	BCC ?interact
	
?end
	PLP
	PLB
	CLC
	RTL

?interact
	PLP
	BCC ?end2
	PEA $01|(?end3>>16<<8)
	PLB
	PHK
	PEA.w ?end3-1
	PEA.w $80CA-1
	JML $01A4BA|!bank

?end3
	PLB
?end2
	PLB
	SEC
	RTL

?ytable
	db $02,$0A 