WrapUp:
		LDA $1C
		SEC
		SBC #$10
		STA $00
		LDA $1D
		SBC #$00
		STA $01

		LDA !14D4,x
		XBA
		LDA !D8,x
		
		REP #$20
		CMP $00
		SEP #$20
		BPL +
	
			INC !14D4,x
+
		RTS
		
WrapDown:
		LDA $1C
		CLC
		ADC #$F0
		STA $00
		LDA $1D
		ADC #$00
		STA $01

		LDA !14D4,x
		XBA
		LDA !D8,x
		
		REP #$20
		CMP $00
		SEP #$20
		BMI +
	
			DEC !14D4,x
+
		RTS