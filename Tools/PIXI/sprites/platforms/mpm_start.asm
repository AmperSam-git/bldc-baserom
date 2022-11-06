;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Starting point for the Mandew's Platform Megapack sprite.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
		PHB                     ; \
		PHK                     ;  | main sprite function, just calls local subroutine
		PLB                     ;  |
		JSR INIT_POINTERS		;  |
		PLB                     ;  |
		RTL                     ; /
		
print "MAIN ",pc
		PHB                     ; \
		PHK                     ;  | main sprite function, just calls local subroutine
		PLB                     ;  |
		JSR MAINCODE_POINTERS   ;  |
		PLB                     ;  |
		RTL                     ; /
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Init Pointers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIT_POINTERS:
		LDA !7FAB40,x
		JSL $0086DF				; Pointer subroutine
	mpm_init_pointers:
	ss0:
		dw !ss0_init	; Boost platform
		dw !ss0_init	; Boost platform, infinite
	ss1:
		dw !ss1_init	; Grey falling platform, 2-tile big, falling down
		dw !ss1_init	; Grey falling platform, 4-tile big, falling down
		dw !ss1_initA	; Grey falling platform, 2-tile big, falling up
		dw !ss1_initA	; Grey falling platform, 4-tile big, falling up
		dw !ss1_init	; Grey falling platform, 2-tile big, falling right
		dw !ss1_init	; Grey falling platform, 4-tile big, falling right
		dw !ss1_init	; Grey falling platform, 2-tile big, falling left
		dw !ss1_init	; Grey falling platform, 4-tile big, falling left
	ss2:
		dw !ss2_init	; Brown left-drifting platform, 3-tile big, falling down
		dw !ss2_init	; Brown right-drifting platform, 3-tile big, falling down
	ss3:
		dw !ss3_init	; Vertical Wrapping Platform, 2-tile big, going down
		dw !ss3_init	; Vertical Wrapping Platform, 4-tile big, going down
		dw !ss3_init	; Vertical Wrapping Platform, 2-tile big, going up
		dw !ss3_init	; Vertical Wrapping Platform, 4-tile big, going up
		
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Main Pointers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		
MAINCODE_POINTERS:
		LDA !7FAB40,x
		JSL $0086DF				; Pointer subroutine
	mpm_main_pointers:
		dw !ss0_main	; Boost platform
		dw !ss0_mainA	; Boost platform, infinite
		
		dw !ss1_main	; Grey falling platform, 2-tile big, falling down
		dw !ss1_main	; Grey falling platform, 4-tile big, falling down
		dw !ss1_main	; Grey falling platform, 2-tile big, falling up
		dw !ss1_main	; Grey falling platform, 4-tile big, falling up
		dw !ss1_main	; Grey falling platform, 2-tile big, falling right
		dw !ss1_main	; Grey falling platform, 4-tile big, falling right
		dw !ss1_main	; Grey falling platform, 2-tile big, falling left
		dw !ss1_main	; Grey falling platform, 4-tile big, falling left
		
		dw !ss2_main	; Brown left-drifting platform, 3-tile big, falling down
		dw !ss2_main	; Brown right-drifting platform, 3-tile big, falling down
		
		dw !ss3_main	; Vertical Wrapping Platform, 2-tile big, going down
		dw !ss3_main	; Vertical Wrapping Platform, 4-tile big, going down
		dw !ss3_main	; Vertical Wrapping Platform, 2-tile big, going up
		dw !ss3_main	; Vertical Wrapping Platform, 4-tile big, going up

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Invalid
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ss_invalid:
		LDA #$01
		JSR Shared_GFX
		RTS