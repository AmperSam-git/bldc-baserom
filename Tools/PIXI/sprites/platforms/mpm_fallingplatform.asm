!falldown_timer = !1564
!platform_prop = !1594
!behavior = !C2
!platform_move = !1528

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Fallingplatform routine, for platforms that act pretty much
;	just like the grey falling platform at some point.
;
; Contains a table that determines which way a platform falls.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FallingPlatform:
		JSR DoYouFall

		JSL $01B44F				; Solid platform routine thing
		BCC +
		
			LDA !behavior,x
			BNE +
			
			LDA #$01
			STA !behavior,x
			
			LDA #20
			STA !falldown_timer,x
			
		+
		
		RTS
		
DoYouFall:
		LDA !behavior,x
		BEQ FallingPlatform_return
		
	FallingPlatform_falling:
			LDA !platform_prop,x
			LSR
			LSR
			AND #$03
			JSL $0086DF				; Pointer subroutine
		FallingPlatform_Directions:
			dw Falldown
			dw Fallup
			dw Fallright 
			dw Fallleft
			
FallingPlatform_return:
		RTS