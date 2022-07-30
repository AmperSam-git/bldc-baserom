; Disable jump block, by Darolac
; This block disables Mario's jump and/or spinjump when Mario is
; touching it from above. 
; It's pretty customisable, as it can be configured to only
; restrict Mario's jump on certan conditions (on/off switch,
; blue/silver p-switch and Mario is in water/starman/on Yoshi).

!spin = 0	; set to 0 to disable spinjump
!jump = 0	; set to 0 to disable jump
!star = 0	; if set to anything except 0 it will not disable
				; anything if Mario has star power.
!yoshi = 0	; if set to anything except 0 it will not disable
			; anything if Mario is on Yoshi.
!water = 0	; if set to anything except 0 it will not disable
			; anything if Mario is on water.
!onoff = 0	; if set to anything except 0 it will not disable
			; anything if the on/off switch is off.
!blue = 0	; if set to anything except 0 it will not disable
			; anything if the blue p-switch is active.
!silver = 0	; if set to anything except 0 it will not disable
			; anything if the silver p-switch is active.

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside

MarioAbove:
TopCorner:
LDA #$00
if !star
ORA $1490|!addr
endif
if !yoshi
ORA $187A|!addr
endif
if !water
ORA $75
endif
if !onoff
ORA $14AF|!addr
endif
if !blue
ORA $14AD|!addr
endif
if !silver
ORA $14AE|!addr
endif
BNE .return
LDA #$80
if !jump = 0
TRB $16
endif
if !spin = 0
TRB $18
endif
.return
SpriteV:
SpriteH:
MarioBelow:
MarioSide:
BodyInside:
HeadInside:
MarioCape:
MarioFireball:

RTL

print "Disables jump/spinjump on contact."