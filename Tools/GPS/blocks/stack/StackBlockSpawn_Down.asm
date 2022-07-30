;Sample kaizo block which spawns a sprite instead of leaving a block
;Act as 25 or 130
;Will need to make one with the sprite number for each direction

!Sprite = #$82 ; Sprite number to spawn
!Custom = 1	   ; 0 = normal sprite, 1 = custom
!PassSprite = 1; 1 = don't be solid to the spawned sprite
!SpriteHit = 1 ; 1 = shells and other sprites can activate the block

db $42
JMP MarioBelow : JMP Return : JMP Return
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP Return
JMP Return : JMP Return : JMP Return

MarioBelow:
    LDA $7D
    BPL Return

MarioCape:
Trigger:
	LDA !Sprite
	if !Custom
		SEC
	else
		CLC
	endif
	%spawn_sprite()
	BCS Return
	%move_spawn_into_block()

	REP #$10
	LDX #$0025
	%change_map16()
	SEP #$10

    LDA #$30
    STA $1693|!addr
    LDY #$01

Return:
RTL

SpriteH:

	if !PassSprite
		if !Custom
		LDA !7FAB10,x
		AND #$08
		BEQ +
		LDA !7FAB9E,x
		CMP !Sprite
		BNE +
		else
		LDA !7FAB10,x
		AND #$08
		BNE +
		LDA !9E,x
		CMP !Sprite
		BNE +
		endif

		LDY #$00
		LDA #$25
		STA $1693|!addr
		RTL
		+
	endif

	if !SpriteHit
	%check_sprite_kicked_horizontal()
	BCC +
	LDY #$01
	LDA #$30
	STA $1693|!addr
	%sprite_block_position()
	JMP Trigger
	+
	endif

	RTL


SpriteV:

	if !PassSprite
		if !Custom
		LDA !7FAB10,x
		AND #$08
		BEQ +
		LDA !7FAB9E,x
		CMP !Sprite
		BNE +
		else
		LDA !7FAB10,x
		AND #$08
		BNE +
		LDA !9E,x
		CMP !Sprite
		BNE +
		endif

		LDY #$00
		LDA #$25
		STA $1693|!addr
		RTL
		+
	endif

	if !SpriteHit
	%check_sprite_kicked_vertical()
	BCC +
	LDA #$10
	STA !AA,x
	%sprite_block_position()
	JMP Trigger
	+
	endif
	RTL