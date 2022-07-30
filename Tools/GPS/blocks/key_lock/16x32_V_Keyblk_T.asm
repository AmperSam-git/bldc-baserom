;Behaves $130
;This is the top block of the 1x2 block gate.

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
	-
	RTL
;-------------------------------------------------
;check if player unlocks it facing correctly.
;-------------------------------------------------
MarioSide:
HeadInside:
	REP #$20		;>begin 16-bit mode
	LDA $9A			;\the block position
	AND #$FFF0		;/
	CMP $94			;\if block is right of mairo (if mario is hitting the
	SEP #$20		;|left side), then branch to left side.
	BCS left_side		;/(end 16-bit mode)

;right_side:
	LDA $76			;\Player should face towards block when touching side.
	BNE -		;|
	JMP SideDone		;|
left_side:			;|
	LDA $76			;|
	BEQ -		;/
SideDone:
;-------------------------------------------------
;This checks what sprite number and deletes key.
;-------------------------------------------------
Unlock:
if !custom_type == 0 || !custom_type == 1
	LDA $1470		;\Return if carrying nothing.
	ORA $148F		;|
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
	RTL			;>if all slots checked and still didn't find, return.
match_sprite:
	STZ !14C8,x		;>erase key.
	PLX			;>done with slots.
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
	STA $1693		;/

	%create_smoke()			;>smoke
	%erase_block()			;>Delete self
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
	REP #$20			;\Move 1 block down.
	LDA $98				;|
	CLC : ADC #$0010		;|
	STA $98				;|
	SEP #$20			;/
	%create_smoke()			;
	%erase_block()			;


	LDA #!sfx_open			;\Play sfx.
	STA !RAM_port_open		;/
MarioBelow:
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

print "The top of the 1x2 key block."