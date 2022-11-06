;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Choose which sub-sprites are inserted.
;		0 = do not insert
;		1 = do insert
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!ss0_boost_platform_insert = 1
!ss1_falling_platform_insert = 1
!ss2_drifting_platform_insert = 1
!ss3_vwrap_platform_insert = 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Labels for each subsprite
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

macro define_label(label, condition)
	if !<condition> == 1
		!<label> = <label>
	else
		!<label> = ss_invalid
	endif
endmacro
	
macro include_if(file, condition)
	if !<condition> = 1
		incsrc <file>
	endif
endmacro
	
%define_label(ss0_init, ss0_boost_platform_insert)
%define_label(ss0_main, ss0_boost_platform_insert)
%define_label(ss0_mainA, ss0_boost_platform_insert)

%define_label(ss1_init, ss1_falling_platform_insert)
%define_label(ss1_initA, ss1_falling_platform_insert)
%define_label(ss1_main, ss1_falling_platform_insert)

%define_label(ss2_init, ss2_drifting_platform_insert)
%define_label(ss2_main, ss2_drifting_platform_insert)

%define_label(ss3_init, ss3_vwrap_platform_insert)
%define_label(ss3_main, ss3_vwrap_platform_insert)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	includes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

incsrc "platforms/mpm_start.asm"
incsrc "platforms/mpm_sharedgfx.asm"
incsrc "platforms/mpm_falldown.asm"
incsrc "platforms/mpm_fallingplatform.asm"
incsrc "platforms/mpm_wrapping.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	subspr includes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%include_if("platforms/boost_platform.asm", ss0_boost_platform_insert)
%include_if("platforms/falling_platform.asm", ss1_falling_platform_insert)
%include_if("platforms/drifting_platform.asm",ss2_drifting_platform_insert)
%include_if("platforms/vwrap_platform.asm",ss3_vwrap_platform_insert)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	misc table defines
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!falldown_timer = !1540
!platform_prop = !1594
!behavior = !C2
