db $42

JMP Return : JMP Return : JMP Return
JMP Return : JMP Return
JMP Return : JMP Return
JMP Return : JMP MarioInside : JMP Return

; Teleport settings
!FixTeleport = !True		; Set to !False so the door uses Mario's position

; Lock settings
!WrongSFX = $2A				; The sound effect to play when you don't have a key. Set to 0 or false to not play any sound effect
!WrongPort = $1DFC|!addr	; Valid values are $1DF9 and $1DF9

; Door settings
!TopPart = !True			; Only let Mario pass if he's small
!BossDoor = !False			; Doesn't check if Mario is really inside similar to boss doors.

; Don't change these!
!True = 1
!False = 0

MarioInside:
	LDA $16			;\  Only enter the door if you press up.
	AND #$08		; |
	BEQ Return		;/
	LDA $8F			;\  Surprise: It's a backup of $72
	BNE Return		;/
if !TopPart
	LDA $19			;   If it's the top door part
	BNE Return		;   don't enter if big.
endif
if not(!BossDoor)
	%door_approximity()
	BCS Return		;   Check if Mario is centered enough
endif
CheckForKey:
	%carry_key()	;\  Does Mario or Yoshi carry a key?
	BMI Wrong		;/

	STZ !14C8,x		;   Consume the key (so that you don't carry it with you if you use a specific patch)

	LDA #$0F		;\  Enter door SFX
	STA $1DFC|!addr	;/

	if !FixTeleport
		LDX #$01
	else
		LDX #$00
	endif
	%teleport_direct()

if !WrongSFX
RTL
Wrong:
	LDA #!WrongSFX		;\  Enter door SFX
	STA !WrongPort		;/
else
Wrong:
endif
Return:
RTL

print "Small door which you can only enter if you carry a key."
