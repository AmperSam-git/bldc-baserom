;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Boost Platforms
;
;		GIEPY ver 1.0
;			Jumps up when Mario steps off the platform. Can be stood on
;			in midair and jumped off of again.
;
;		6 cfg files are included:
;			boost_plat_2tiles.cfg
;			boost_plat_3tiles.cfg
;			boost_plat_4tiles.cfg	; Can only jump from their starting position.
;
;			boost_plat_2tiles_gold.cfg
;			boost_plat_3tiles_gold.cfg
;			boost_plat_4tiles_gold.cfg	; Jump off whenever Mario steps off, even when in the air.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print	"INIT ", pc
		LDA !D8,x
		SEC
		SBC #$02
		STA !D8,x
		STA !1594,x	; Copy of sprite platform's starting Y position (low byte).

		LDA !14D4,x
		SBC #$00
		STA !14D4,x
		STA !1626,x	; Copy of sprite platform's starting Y position (high byte).


		RTL

print	"MAIN ", pc
                    PHB                     ; \
                    PHK                     ;  | main sprite function, just calls local subroutine
                    PLB                     ;  |
                    JSR BoostPlat_Start		;  |
                    PLB                     ;  |
                    RTL                     ; /

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!JumpSpeed = #$D8
!MaintainSpeedTime = #20
!FallSpeedLimit = #$30

		Skip:
		RTS

BoostPlat_Start:
		LDA !extra_byte_1,x	; Length of platform (in 16x16 tiles)
		JSR DrawGFX

		LDA $9D	; Lock Flag
		BNE Skip
	; [$9D EQ #$00]
		%SubOffScreen() ;SubOffScreenYadda
		BCS Skip

		LDA !14C8,x
		CMP #$08
		BNE Skip

;;;;;;;;;;;;;;;;; Behavior code start ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
;	States of $C2,x
;
;		EQ #$00 -- Sprite is idle, at starting position, not moving.
;		EQ #$01 -- Sprite is at idle position, but ready to go up.
;		EQ #$02 -- Sprite is jumping up.
;
;	States of $151C,x
;		EQ #$00 -- Sprite is not being stepped on.
;		NE #$00 -- Sprite is being stepped on.
;

;Interactions:
		JSL $01801A		; Update sprite's Y Position.

		JSL $01B44F
		BCC NoContact

		LDA !C2,x
		BNE +
	; [!C2,x EQ #$00] State = idle
	; Set platform to a "stepped on" state.
		LDA #$01
		STA !151C,x

		INC !C2,x	; $C2,x = #$01

		LDA !D8,x
		CLC
		ADC #$02
		STA !D8,x	; Y position +2

		LDA !14D4,x
		ADC #$00
		STA !14D4,x
		BRA Movement
	+

	; [$C2,x NE #$00]
; 	If Extra Property byte 2 is set, the platform will keep track of being stepped on
;	even while it's moving.
		LDA !extra_byte_2,x
		BEQ Movement
	; [!extra_byte_2 NE #$00]
		LDA #$01
		STA !151C,x
		BRA Movement	; Done with Interactions

NoContact:
		LDA !151C,x
		BEQ +
	; [$151C,x NE #$00] - Sprite had been stepped on in the previous frame.
	;	i.e. this action caused by stepping off:
		LDA !JumpSpeed
		STA !AA,x		; Set sprite Y speed

		LDA !MaintainSpeedTime
		STA !1540,x		; Set a timer to maintain upwards speed.

		STZ !151C,x		; Platform is now no longer stepped on.

		LDA #$02
		STA !C2,x		; Sprite is moving.
	+

Movement:

		LDA !C2,x
		CMP #$02
		BNE Done	; Sprite will only move in $C2,x state #$02.
	; [$C2,x EQ #$02] -- Sprite is moving.

		LDA !1540,x		; timer
		BNE +
		; [$1540,x EQ #$00] -- Sprite no longer maintains its Y speed.
		;	Note that $1540,x automatically decrements once per frame.
		INC !AA,x
		INC !AA,x
		+

		LDA !AA,x
		BMI Done
		; If sprite is going upwards, no further action is required.

		; [!AA,x is positive] (sprite is moving downwards)
		; Speed limiting.
		CMP !FallSpeedLimit
		BCC +
		; [!AA,x > !FallSpeedLimit]
		LDA !FallSpeedLimit
		STA !AA,x
	+
	; Snap to starting position.

		LDA !D8,x
		STA $00
		LDA !14D4,x
		STA $01

		LDA !1594,x	; Copy of sprite platform's starting Y position (low byte).
		STA $02
		LDA !1626,x	; Copy of sprite platform's starting Y position (high byte).
		STA $03

		PHP				; Push 8-bit mode onto the stack.
		REP #$20		; 16-bit mode.

		LDA $00
		BMI +
		CMP $02
		BCC +
		SEP #$20

		LDA !1594,x		; Set sprite's Y Position back to
		STA !D8,x		; its starting Y position.
		LDA !1626,x
		STA !14D4,x

		STZ !C2,x		; Sprite's behavior is now back to idle.
		STZ !AA,x
	+
		PLP				; Pull back into 8-bit mode.
Done:
		RTS				; Code is done with, gj dude.

;;;;;;;;;;;;;;;;;;;;; Drawing Routine ;;;;;;;;;;;;;;;;;;;
;
;	Input: A = Length of the platform (in 16x16 tiles)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

XDisp:
db $00,$10,$20,$30,$40,$50,$60,$70

DrawGFX:
	AND #$07	;
	CLC
	ADC #$02
	STA $03		; Amounts of tiles to draw

lda #$62       ; find or queue GFX
%FindAndQueueGFX()
bcs .gfx_loaded
rts                      ; don't draw gfx if ExGFX isn't ready

.gfx_loaded
	%GetDrawInfo()

	LDA #$02
	STA $04		; $04 contains and keeps track of the graphic to draw.

	LDA !15F6,x
	STA $05		; Copy of $15F6,x -- Sprite properties

	LDX $03
--
	DEX
	BMI ++

	BNE +
	STZ $04
	+

	LDA $00
	CLC
	ADC XDisp,x
	STA $0300|!Base2,y

	LDA $01
	STA $0301|!Base2,y

	PHX
	LDX $04
	lda !dss_tile_buffer,x
	PLX
	STA $0302|!Base2,y

	LDA $05
	ORA $64
	STA $0303|!Base2,y

	LDA #$01
	STA $04	;

	INY
	INY
	INY
	INY

	BRA --

++

	LDX $15E9|!Base2	; Get sprite slot back.

	LDA $03			; Tiles to draw
	DEC
	LDY #$02		; 16x16
	JSL $01B7B3		; Finish OAM Write

	RTS
