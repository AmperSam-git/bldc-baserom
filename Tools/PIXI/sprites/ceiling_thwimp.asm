;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Ceiling Thwimp (GIEPY version 1.0)
;		Ceiling Thwimp is an upside-down Thwimp
;		that falls upwards and jumps from the ceiling.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Customizable defines
!WaitTime = #57		; Time to wait on the ceiling.
!Gravity = #$03		; Gravity.
!Go_XSpeed = $0F	; X Speed when jumping.
!JumpSpeed = #$61	; Jumping speed.
!MaxSpeed = #$C0	; Maximum speed while falling.

; SA1 defs
!0300 = $0300|!Base2 ; X Position
!0301 = $0301|!Base2 ; Y Position
!0302 = $0302|!Base2 ; Tile
!0303 = $0303|!Base2 ; Properties

!15E9 = $15E9|!Base2 ; "Sprite index for the current sprite that is being processed."
!1DF9 = $1DF9|!Base2 ; Sound Effects port
!1DFC = $1DFC|!Base2 ; Sound Effects port
!1406 = $1406|!Base2 ; Camera things


;;;;;;;;;;; CODE STARTS HERE

print	"INIT ", pc
		LDA !D8,x	; shifting Thwimp's postion a bit.
		SEC
		SBC #$03
		STA !D8,x
		LDA !14D4,x
		SBC #$00
		STA !14D4,x
		RTL

print	"MAIN ", pc
                    PHB                     ; \
                    PHK                     ;  | main sprite function, just calls local subroutine
                    PLB                     ;  |
                    JSR CeilingThwimp_Start ;  |
                    PLB                     ;  |
                    RTL                     ; /




JumpXSpeed:
db (0-!Go_XSpeed),!Go_XSpeed ; (Left, Right)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Usual Code Starting shenanigans.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Skip:
		RTS

CeilingThwimp_Start:
		JSR DrawGraphics
		LDA $9D	; Lock Flag
		BNE Skip
	; [$9D EQ #$00]
		%SubOffScreen() ;SubOffScreenYadda
		BCS Skip

		LDA !14C8,x
		CMP #$08
		BNE Skip

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Behavior Code.
;		RAM Table at ($1528,x) is used as a timer
;		for this sprite. When the timer reaches 0,
;		this sprite jumps from its ceiling.
;
;		Misc Table at ($1594,x) is used as an "In the air"
;		flag.
;			[$1594,x EQ #$00]: Sprite is not in the air.
;			[$1594,x NE #$00]: Sprite is in the air.
;
;		Misc Table at ($157C,x) contains the direction for the next jump.
;			[$157C,x EQ #$00]: Sprite is going to jump to the left.
;			[$157C,x EQ #$00]: Sprite is going to jump to the right.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		JSL $01A7DC ; Default interactions with Player subroutine.


	; Handling being in the air, on the ceiling, or landing.
		LDA !1594,x
		BEQ OnTheCeiling
			;[$1594,x NE #$00] - Sprite is in the air.

		JSL $019138	; Object interactions

		LDA !1588,x ; sprite "blocked" status
		AND #$04	; "d = down."
		BEQ +
		STZ !AA,x	; if touching the ground, set !AA,x to zero.
	+

		LDA !AA,x
		SEC
		SBC !Gravity
		STA !AA,x		; Make sprite fall upwards.
		BPL ++
		; [$AA,x is Negative] (sprite going upwards)
	; Speed limiter
		CMP #$C0
		BCS +
		LDA #$C0
		STA !AA,x
		+

		LDA !1588,x ; sprite "blocked" status
		AND #$08	; "u = up."
		BNE ThwimpHasLanded
			;[$1588,x AND #$28 EQ #$00] - Sprite is still in the air.

	++

		LDY #$01	; "r = right."
		LDA !B6,x	; checking X Speed
		BMI +		; if going to the left...
		INY			; change "r = right." for "l = left."
		+
		TYA			; Boop! In the accumulator it goes.
		AND !1588,x ; sprite "blocked" status
		BEQ +
			;[$1588,x AND #$43 NE #$00] - Sprite is touching a wall
		LDA !B6,x
		EOR #$FF
		INC
		STA !B6,x	; Invert X-Speed
		+

		JSL $018022 ; Update X position
		JSL $01801A	; Update Y Position

		BRA HandleTimer
		; End of Code: Thwimp is in the air.

OnTheCeiling:
		; don't update positions when not in the air.
		JSL $019138	; Object interactions

		LDA !1588,x ; sprite "blocked" status
		AND #$08	; "u = up."
		BNE +
			;[$1588,x AND #$28 EQ #$00] - Sprite is back in the air somehow.
		INC !1594,x ; signify that the sprite is "in the air".
		+
		BRA HandleTimer

ThwimpHasLanded:
		; bringing small correctives to the vertical position
		LDA !D8,x
		AND #$F0
		CLC
		ADC #$0D
		STA !D8,x
		;LDA !14D4,x
		;ADC #$00
		;STA !14D4,x

		LDA #$01		;
		STA !1DF9		; Play Sound Effect (thwimp landing)

		LDA !WaitTime	;
		STA !1528,x		; Set the time to be waiting.

		STZ !1594,x		; Set sprite to be "Not in the air" (so on the ceiling)

		LDA #$F8
		STA !AA,x		; Set Y Speed to -8 (for ceiling checks)
		STZ !B6,x		; Set X Speeed to 0
			; End of Code: Thwimp is in the air and has landed on the ceiling.

	; Timer handler.
HandleTimer:
		LDA !1528,x
		BEQ +
		DEC !1528,x
		BNE +
		; making Thwimp jump.
		LDA !157C,x
		TAY
		LDA JumpXSpeed,y
		STA !B6,x

		LDA !JumpSpeed
		STA !AA,x

		LDA !157C,x		;
		EOR #$01		; Invert Direction for next jump.
		STA !157C,x		;
		+
		RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	DrawGraphics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DrawGraphics:
	lda #$95        ; find or queue GFX
	%FindAndQueueGFX()
	bcs .gfx_loaded
	rts                      ; don't draw gfx if ExGFX isn't ready
.gfx_loaded
    %GetDrawInfo()

    LDA $00                 ;\ Set the X position of the tile
    STA $0300|!Base2,y      ;/
    LDA $01                 ;\ Set the Y position of the tile
    STA $0301|!Base2,y      ;/
	PHX
    LDX.b #$00            ;\ Set the tile number.
	lda !dss_tile_buffer,x
	PLX
    STA $0302|!Base2,y      ;/

    LDA #$F0                ; Discard the sprite two slots below in OAM.
    STA $0309|!Base2,y      ; Fixes visual garbage from $14C8,x == $09

    LDA !15F6,x             ; Write the YXPPCCCT property byte of the tile
    ORA $64
    STA $0303|!Base2,y

    INY #4

    LDY #$02                ; Y ends with the tile size .. 02 means it's 16x16
    LDA #$00                ; A -> number of tiles drawn - 1.
    JSL $01B7B3|!BankB      ; Finish OAM write.
    RTS