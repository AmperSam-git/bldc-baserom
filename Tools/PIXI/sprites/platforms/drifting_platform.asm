!falldown_timer = !1564
!platform_prop = !1594
!behavior = !C2
!offset = #(ss2-mpm_init_pointers)>>1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Grey falling platform
;
;	Init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Platform_clip2:
db $32,$32
Platform_properties2:
db $01,$01
Platform_xspeed2:
db $F4,$0C

ss2_init:
		LDA !7FAB40,x
		SEC
		SBC.b !offset
		TAY

		LDA Platform_clip2,y
		STA !1662,x
		
		LDA Platform_properties2,y
		STA !platform_prop,x
		
		LDA Platform_xspeed2,y
		STA !B6,x
		
		RTS
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		Main
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ss2_main:
		LDA !platform_prop,x
		AND #$03
		INC
		INC
		
		JSR Shared_GFX			; Graphics routine

		LDA $9D					; Animation lock flag
		BNE ss2_return			; "freeze!"

		LDA #$00
		%SubOffScreen()
		
		LDA !behavior,x
		BNE +
		JSL $018022		; Update X position	
+

		
		JSR FallingPlatform
			
ss2_return:
		RTS