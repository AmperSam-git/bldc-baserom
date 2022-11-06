!falldown_timer = !1564
!platform_prop = !1594
!behavior = !C2
!offset = #(ss0-mpm_init_pointers)>>1
!bottom_low = !151C
!bottom_high = !1534

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Boost platform
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Palette0:
db $01,$05

ss0_init:
		LDA !7FAB40,x
		CLC
		ADC.b !offset
		TAY
		LDA Palette0,y
		STA !15F6,x

		LDA #$2F
		STA !1662,x
		
		LDA !D8,x
		SEC
		SBC #$04
		STA !D8,x
		STA !bottom_low,x
		
		LDA !14D4,x
		SBC #$00
		STA !14D4,x
		STA !bottom_high,x

ss0_return2:		
		RTS
		


ss0_main:
		LDA #$02
		JSR Shared_GFX
		
		LDA $9D
		BNE ss0_return2
		
		LDA #$00
		%SubOffScreen()
		
		LDA !behavior,x
		JSL $0086DF	
	ss0_behaviors:
			dw ss0_idle_waiting
			dw ss0_stepped_on
			dw ss0_jump

ss0_mainA:
		LDA #$02
		JSR Shared_GFX
		
		LDA $9D
		BNE ss0_return2
		
		LDA #$00
		%SubOffScreen()
		
		LDA !behavior,x
		JSL $0086DF	
	ss0_behaviorsA:
			dw ss0_idle_waiting
			dw ss0_stepped_on
			dw ss0_infinite_jump
			dw ss0_infinite_jump
			
	ss0_idle_waiting:
		JSL $01B44F		; solid platform
		BCC ss0_return2
			INC !behavior,x
			LDA !D8,x
			CLC
			ADC #$04
			STA !D8,x
			LDA !14D4,x
			ADC #$00
			STA !14D4,x
			RTS
	
	ss0_stepped_on:
		JSL $01B44F		; solid platform
		BCS ss0_return2
			INC !behavior,x
			
			LDA !bottom_low,x
			STA !D8,x
			
			LDA !bottom_high,x
			STA !14D4,x
			
			LDA #$D8
			STA !AA,x
			
			LDA #$10
			STA !falldown_timer,x
			RTS
	
	ss0_jump:

		LDA !falldown_timer,x
		BNE +
		
			LDA !AA,x
			CLC
			ADC #$02
			BMI ++
			CMP #$30
			BCC ++

			LDA #$30
		++
			STA !AA,x
			
			
			
		+
		
		JSL $01801A		; Update Y position
	
	
		LDA !D8,x
		STA $00
		LDA !14D4,x
		STA $01
		LDA !bottom_low,x
		STA $02
		LDA !bottom_high,x
		STA $03
		
		REP #$20
		LDA $00
		CMP $02
		SEP #$20
		BMI ss0_jump_return
		
			LDA !bottom_low,x
			STA !D8,x
			LDA !bottom_high,x
			STA !14D4,x
			STZ !behavior,x
	
	ss0_jump_return:
		JSL $01B44F		; solid platform
	
		RTS
	
	ss0_infinite_jump:
		JSR ss0_jump
		
		BCC ss0_infinite_nottouch
			LDA !behavior,x
			CMP #$02
			BNE ss0_return
				LDA #$03
				STA !behavior,x
				RTS
			
	ss0_infinite_nottouch:
			LDA !behavior,x
			CMP #$03
			BNE ss0_return
			
				LDA #$02
				STA !behavior,x
				
				LDA #$D8
				STA !AA,x
			
				LDA #$10
				STA !falldown_timer,x
			
ss0_return:
		RTS