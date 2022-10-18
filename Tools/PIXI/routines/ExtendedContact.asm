;Input:  C   = (Clear = 8x8 , Set = 16x16)

;Output: C   = (Clear = No Contact , Set = Contact)

	LDA #$01 : STA $00
	LDA #$06
	BCC +
	LDA #$03 : STA $00
	LDA #$0A
+	STA $06
	STA $07
	LDA $171F|!Base2,x
	CLC
	ADC $00
	STA $04
	LDA $1733|!Base2,x
	ADC #$00
	STA $0A
	LDA $1715|!Base2,x
	CLC
	ADC $00
	STA $05
	LDA $1729|!Base2,x
	ADC #$00
	STA $0B
	JSL $03B664|!BankB
	JSL $03B72B|!BankB
	RTL
