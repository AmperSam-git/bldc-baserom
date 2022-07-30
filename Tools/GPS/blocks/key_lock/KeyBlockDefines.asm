!NumbOfSa1Slots = 22		;>how many slots, change this to a number of slots
							; sa1 has open up to (so if it increases number of
							; on-screen sprites to 22, then put 22).
!custom_type = 0			;>0 = normal sprites, 1 = custom sprites from
							; Romi's Spritetool v1.40 (also used to check if
							; sprite flag is custom or not), 2 = ALTTP key stack
							; counter.
!FreeRamAlttpKey = $0DA1	;>Freeram for ALTTP key counter, not used if above
							; setting is a 0 or 1.
!SpriteNum = $80			;>what sprite number opens the gate, $80 is smw's
							; key sprite. Not used if "!custom_type" is 2.
!sfx_open =	$10				;\Door opening sfx
!sfx_port = $1DF9|!addr		;/

!AllowNotCarried = 1		; 0 = key must be carried, 1 = key can be tossed into blocks

;---------------------------
;Do not change these below:
;---------------------------
if !custom_type == 0
	!SpriteTyp = !9E
else
	!SpriteTyp = !7FAB9E
endif