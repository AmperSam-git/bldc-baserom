!falldown_timer = !1564
!platform_prop = !1594
!behavior = !C2
!offset = #(ss1-mpm_init_pointers)>>1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Grey falling platform
;
;	Init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Platform_clip:
db $2F,$33,$2F,$33,$2F,$33,$2F,$33
Platform_properties:
db $00,$02,$04,$06,$08,$0A,$0C,$0E

ss1_initA:
		LDA #$20
		STA !AA,x

ss1_init:
		LDA !7FAB40,x
		SEC
		SBC.b !offset
		TAY

		LDA Platform_clip,y
		STA !1662,x
		
		LDA Platform_properties,y
		STA !platform_prop,x
		RTS
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		Main
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ss1_main:
		LDA !platform_prop,x
		AND #$03
		INC
		INC
		
		JSR Shared_GFX			; Graphics routine

		LDA $9D					; Animation lock flag
		BNE ss1_return			; "freeze!"

		LDA #$00
		%SubOffScreen()
		
		JSR FallingPlatform
			
ss1_return:
		RTS