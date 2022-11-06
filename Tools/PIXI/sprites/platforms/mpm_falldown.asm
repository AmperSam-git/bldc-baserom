!falldown_timer = !1564
!platform_prop = !1594
!behavior = !C2
!platform_move = !1528

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Falldown shared routines.
;		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Falldown:

		STZ !B6,x

		LDA #$04

		LDY !falldown_timer,x
		BNE Movedown
		
			LDA !AA,x
			CLC
			ADC #$03
		
			CMP #$30
			BCC Movedown
			
				LDA #$30
		
	Movedown:
		STA !AA,x

		JSL $01801A		; Update Y position
		RTS
		
Fallright:

		LDA #$04

		LDY !falldown_timer,x
		BNE Moveleft
		
			LDA !B6,x
			CLC
			ADC #$02
		
			CMP #$18
			BCC Moveright
			
				LDA #$18
		
	Moveright:
		STA !B6,x

		JSL $018022		; Update X position		
		LDA $1491|!Base2
		STA !platform_move,x
		
		RTS
		

Fallleft:
		STZ !AA,x

		LDA #$F4

		LDY !falldown_timer,x
		BNE Moveleft
		
			LDA !B6,x
			SEC
			SBC #$02
		
			CMP #$E8
			BCS Moveleft
			
				LDA #$E8
		
	Moveleft:
		STA !B6,x
		
		JSL $018022		; Update X position		
		LDA $1491|!Base2
		STA !platform_move,x
		
		RTS	
	
Fallup:
		STZ !B6,x

		LDA !AA,x
		DEC
		
		BPL Moveup
		CMP #$E0
		BCS Moveup
			
		LDA #$E0
		
	Moveup:
		STA !AA,x

		JSL $01801A		; Update Y position
		RTS	