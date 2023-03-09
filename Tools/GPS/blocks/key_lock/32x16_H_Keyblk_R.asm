;Behaves $130
;This is the right block of the 2x1 block gate.

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide : JMP SpriteV : JMP SpriteH
JMP MarioCape : JMP MarioFireBall : JMP TopCorner : JMP BodyInside : JMP HeadInside

incsrc KeyBlockDefines.asm

;-------------------------------------------------
;check if player presses up or down depending on
;what side
;-------------------------------------------------
TopCorner:
MarioAbove:
	LDA $15
	AND.b #%00000100
	BNE Unlock
	RTL
MarioBelow:
	LDA $15
	AND.b #%00001000
	BNE Unlock
	-
	RTL
;-------------------------------------------------
;check if player unlocks it facing correctly.
;-------------------------------------------------
MarioSide:
HeadInside:

;left_side:			;\Player should face towards block when touching side.
	LDA $76			;|
	BNE -		;/
SideDone:
;-------------------------------------------------
;This checks what sprite number and deletes key.
;-------------------------------------------------
Unlock:
if !custom_type == 0 || !custom_type == 1
	LDA $1470|!addr		;\Return if carrying nothing.
	ORA $148F|!addr		;|
	BEQ -		;/
	PHX
	LDX.b #!NumbOfSa1Slots-1
-
	LDA !14C8,x		;\If sprite status = not carried then next slot
	CMP #$0B		;|
	BNE NextSlot		;/

	LDA !7FAB10,x		;\Check if its a custom sprite
	AND #$08		;|
	if !custom_type = 0	;|
		BNE ReturnPull	;|
	else			;|
		BEQ ReturnPull	;|
	endif			;/
	LDA !SpriteTyp,x	;\If sprite number doesn't match, then next slot
	CMP #!SpriteNum		;|
	BNE NextSlot		;/
	JMP match_sprite	;>if match, then proceed.
NextSlot:
	DEX
	BPL -
ReturnPull:
	PLX
	RTL				;>if all slots checked and still didn't find, return.
match_sprite:
	STZ !14C8,x		;>erase key.
	PLX				;>done with slots.
	LDA #$40		;\Fix a bug that if you unlock the block and kick it
	TSB $15			;/at the same frame makes deleting the key not function.
;--------------------------------------
;This code below is for using ALTTP key
;--------------------------------------
else
	LDA !FreeRamAlttpKey
	BEQ Return
	DEC A
	STA !FreeRamAlttpKey
endif
;---------------------------------
;Erase block.
;---------------------------------
Erase:
	LDY #$00		;\Right when it disappears, shouldn't stop the player's
	LDA #$25		;|movement.
	STA $1693|!addr		;/

	%create_smoke()			;>smoke
	%erase_block()			;>Delete self.
	LDA $5B				;\Check if vertical level = true
	AND #$01			;|
	BEQ +				;|
	PHY				;|
	LDA $99				;|Fix the $99 and $9B from glitching up if placed
	LDY $9B				;|other than top-left subscreen boundaries of vertical
	STY $99				;|levels!!!!! (barrowed from the map16 change routine of GPS).
	STA $9B				;|(this switch values $99 <-> $9B, since the subscreen boundaries are sideways).
	PLY				;|
+					;/
	REP #$20			;\Move 1 block left.
	LDA $9A				;|
	CLC : ADC #$FFF0		;|
	STA $9A				;|
	SEP #$20			;/
	%create_smoke()			;
	%erase_block()			;


	LDA #!sfx_open			;\Play sfx.
	STA !sfx_port		;/
	RTL
SpriteV:
SpriteH:
	if !AllowNotCarried

	LDA !14C8,x		;\If sprite status = not carried then next slot
	CMP #$09		;|
	BNE Return		;/

	LDA !7FAB10,x		;\Check if its a custom sprite
	AND #$08		;|
	if !custom_type = 0	;|
		BNE Return	;|
	else			;|
		BEQ Return	;|
	endif			;/
	LDA !SpriteTyp,x	;\If sprite number doesn't match, then next slot
	CMP #!SpriteNum		;|
	BNE Return		;/

	STZ !14C8,x		;>erase key.

	%sprite_block_position()

	BRA Erase

	endif
	RTL
MarioCape:
MarioFireBall:
BodyInside:
Return:
	RTL

print "The right of the 2x1 key block."