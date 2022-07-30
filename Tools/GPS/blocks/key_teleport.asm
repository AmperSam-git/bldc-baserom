;Key teleport bloc;
;by smkdan

;This warps player when they carry TELEITEM into the block.  It's a key in this case.

!TELEITEM = $80

;;;;;;;;;;;;;;;;;;;;;;;;;;
;Below, above and side offsets must be 0. all other must be -1,
;and the whole page unchecked!
;;;;;;;;;;;;;;;;;;;;;;;;;;

db $42
JMP Run : JMP Run : JMP Run : JMP Return : JMP Return : JMP Return : JMP Return
JMP Run : JMP Run : JMP Run

print "This block will teleport the player if they are carrying a key"

Run:
PHX
PHY
PHA
LDX #$00

Loop:

LDA !9E,x
CMP #!TELEITEM  ;The sprite number. Change it to any >>>carryable<<< sprite to teleport with that sprite
BNE NoMatch
LDA !14C8,x
CMP #$0B
BEQ Teleport

NoMatch:
INX
if !sa1
CPX #$16
else
CPX #$0C
endif
BEQ Return2
BRA Loop

Teleport:
SEP #$30
LDA #$06
STA $71
STZ $89
STZ $88

Return2:
PLA
PLY
PLX

Return:
RTL
