db $42
JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP Return : JMP FIAR
JMP Return : JMP Return : JMP Return

!sprite_number 	= $3E
!is_custom		= 0		; 0 = vanilla, 1 = custom
!sfx			= $00	; Set to $00 for no SFX.
!sfx_addr		= $1DF9|!addr

FIAR:
	%fireball_smoke()

	lda.b #!sprite_number
if !is_custom
	sec
else
	clc
endif
	%spawn_sprite()
	bcs +
	%move_spawn_into_block()
	lda.b #!sfx : sta !sfx_addr
+	%erase_block()
Return:
	rtl

print "A frozen version of sprite ", hex(!sprite_number), "."