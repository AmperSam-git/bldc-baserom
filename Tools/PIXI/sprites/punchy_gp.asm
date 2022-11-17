;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Punchy (Geipy Version 1.1)
;
;	[Insert with "punchy_left.cfg" and "punchy_right.cfg"]
;		Punchy will fling Mario upwards and into the direction
;		he is facing. Punchy will also fling most sprites.
;
;	Version History:
;		1.0 - First release
;		1.0.1 - Commented out four lines in the Sprite Interaction section,
;				making this one interact with a lot more other kinds of
;				sprites.
;		1.1	- Two major changes:
;
;			  1. Added a 128-bytes long table for exception bits, written in binary.
;			  Each bit of that table corresponds to a sprite number,
;			  within a group number. 1024 bits in all.
;			  Bits that are set means that the sprite should not
;			  interact with Punchy.
;			  	Vanilla sprites were tested to check their interactions with Punchy.
;				Sprites with no visible effect from said interaction have been set
;				as exceptions. All other sprites were deliberately left alone,
;				no matter how odd their interactions are in certain cases.
;				* No changes to this submission will be made if they compromise
;				  exploration in the use of this sprite.
;				If a user wants to make changes to those exceptions themselves, however,
;				be it for vanilla sprites or custom sprites, they may change the table
;				themselves. You can find the table by looking for "Exceptions_Table"
;				(preferably, with Ctrl+F)
;
;			  2. Alternate inserts for this sprite are now available,
;				 each with different colors and fling speeds. Still customizable via defines.
;
;				Red: Default (High fling speed, both horizontally and vertically)
;				Blue: Weaker fling.
;				Green: Flings Mario and Sprites towards itself as lower speeds (for a ledge-grabbing effect)
;				Yellow: Flings Mario and Sprites higher up, but with less horizontal oomph.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!GFX_FileNum = $89		;EXGFX number for this sprite

; Properties
!Tile = $00	; Tile to draw as Punchy
!FlingSpeed_LR_Red	=	$30
!FlingSpeed_LR_Blue	=	$24
!FlingSpeed_LR_Green =	$F8
!FlingSpeed_LR_Yellow =	$10
					; Speed to fling Mario and sprites at (Left and Right)
					; (Calculates both automatically based on this)
!FlingSpeed_Upwards_Red = $B8
!FlingSpeed_Upwards_Blue = $CC
!FlingSpeed_Upwards_Green = $CC
!FlingSpeed_Upwards_Yellow = $A0
					; Speed to fling Mario/Sprites upwards.
					; Provide a Negative value for Upwards, or a Positive value for Downwards if you're into that.

; SA1 defs
				; OAM Base2esses
!0300 = $0300|!Base2 ; X Position
!0301 = $0301|!Base2 ; Y Position
!0302 = $0302|!Base2 ; Tile
!0303 = $0303|!Base2 ; Properties

!15E9 = $15E9|!Base2 ; "Sprite index for the current sprite that is being processed."
!1DF9 = $1DF9|!Base2 ; Sound Effects port
!1DFC = $1DFC|!Base2 ; Sound Effects port
!1406 = $1406|!Base2 ; Camera things

print	"INIT ", pc
    PHB                     ; \
    PHK                     ;  |
    PLB                     ;  |

	INC !157C,x
	lda !extra_bits,x
  and #$04
	BNE +
	STZ !157C,x
	LDA	!15F6,x
	ORA #$40
	STA !15F6,x
+
	PHY
	LDA !extra_byte_1,x
	AND #$03
	TAY
	LDA !15F6,x
	AND #$F1
	ORA Pals,y
	STA !15F6,x
	PLY

	PLB
	RTL

print	"MAIN ", pc
                    PHB                     ; \
                    PHK                     ;  | main sprite function, just calls local subroutine
                    PLB                     ;  |
                    JSR Punchy_Start   ;  |
                    PLB                     ;  |
                    RTL                     ; /

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Pals:
db $08,$06,$0A,$04

Timer_ChangeStateAt:
db 3,8,11				; For: State #$01,#$02,#$03
Timer_ChangeStateTo:
db $02,$03,$00			; For: State #$01,#$02,#$03

FlingSpeed_LR:
db !FlingSpeed_LR_Red,(0-!FlingSpeed_LR_Red)
db !FlingSpeed_LR_Blue,(0-!FlingSpeed_LR_Blue)
db !FlingSpeed_LR_Green,(0-!FlingSpeed_LR_Green)
db !FlingSpeed_LR_Yellow,(0-!FlingSpeed_LR_Yellow)

FlingSpeed_Upwards:
db !FlingSpeed_Upwards_Red,!FlingSpeed_Upwards_Red
db !FlingSpeed_Upwards_Blue,!FlingSpeed_Upwards_Blue
db !FlingSpeed_Upwards_Green,!FlingSpeed_Upwards_Green
db !FlingSpeed_Upwards_Yellow,!FlingSpeed_Upwards_Yellow

FlingDirection:
db 0,1	; Red
db 0,1	; Blue
db 1,0	; Green
db 0,1	; Yellow

Skip:
	RTS
	; End of Code:
	;	- [$C2,x EQ #$01] -- Sprite is in State #$01 (after handling the Timer)
	;	- [$9D EQ #$01] -- Sprites a locked
	;	- [%SubOffScreen() > Carry Set] -- Sprite had been deleted during the SubOffScreen routine.

;;;;;;;; START ;;;;;;;;;

Punchy_Start:
		JSR DrawGraphics
		LDA $9D	; Lock Flag
		BNE Skip
	; [$9D EQ #$00]
		LDA #$03
		%SubOffScreen() ;SubOffScreenYadda
		BCS Skip

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Behavior code.
;		Sprite Table $C2 contains the current state of Punchy:
;			[$C2,x EQ #$00] : "Idle", default state. Contact with Mario or Sprites will activate it.
;			[$C2,x EQ #$01] : "Winding up" state. Not interactions whatsoever in this state.
;							: Uses an Base2ess in table ($1528,x) as a timer. When timer reaches a certain point,
;							: this sprite gets to its next state.
;			[$C2,x EQ #$02] : "Punching" state. Checks for interactions with Mario and Sprites again,
;							: and flings them in the appropriate direction.
;							: Also runs up a bit of ($1528,x) to get to the sprite's final state.
;			[$C2,x EQ #$03]	: "Winding down" state. Ticks up the rest of ($1528,x). Contact with Mario or Sprites
;							: will reactivate this sprite at #$01 and refresh the timer at ($1528,x)
;
;		[EQ = Equal; NE = Not Equal]
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
; Ticking down Timer at $1528,x
;	Uses tables "Timer_ChangeStateAt" and "Timer_ChangeStateTo",
;	found above the "Start" of the code --
;		-- Which are indexed by [$C2,x] minus 1.

		LDA !C2,x
		BEQ ++
		; [!C2,x NE #$00] ; If state isn't #$00, use the timer.
		INC !1528,x

		LDA !C2,x
		DEC			;v
		TAY			; y = [$C2,x] minus 1
		LDA Timer_ChangeStateAt,y
		CMP !1528,x
		BNE +

		LDA Timer_ChangeStateTo,y
		STA !C2,x

;
;	Check for Contact.
;		If in State 0 or 3, contact will result in the sprite activating.
;		If in State 2, contact will result in the source of Contact being flung.
;
;		In State 0 or 3, the Contact loop will end immediately after activation.
;		In State 2, the Contact loop will not cease until every sprite have been checked.
;
;		Uses table "FlingSpeed" above the "Start" of the code --
;			-- Indexed by $59, a Scratch RAM copy of [$157C,x] (this sprite's direction).
;
;		RAM Base2ess $59 is used as additional Scratch RAM (Copy of !157C,x -- Sprite's Direction).
;			-- Set during the JSR to SpriteHitbox.
;		RAM Base2ess $5A is used as additional Scratch RAM (Copy of !C2,x -- Sprite's state)
;	-----------------------

+	; Entry point for Sprite States 1, 2 and 3.
		LDA !C2,x
		CMP #$01
		BEQ Skip
	; [$C2,x NE #$01]

++	; Entry point for Sprite State 0.

		JSR SpriteHitbox	; Get Sprite Clipping (ClipRAM A)

		JSL $03B664			; Get Player Clipping (ClipRAM B)
		JSL $03B72B 		; Check for Contact
		BCC MarioSkip

		LDA $5A			; copy of Punchy's !C2,x
		CMP #$02
		BNE ActivatePunchy

		LDY $59			; Copy of Sprite's Direction and color (in Scratch RAM)

		LDA FlingSpeed_LR,y
		STA $7B 		; Player X Speed

		LDA FlingSpeed_Upwards,y
		STA $7D			; Player Y Speed

		LDA #$80		; Allow camera to scroll upwards if
		STA !1406		; vertical scrolling is enabled.

		LDA #$01		;
		STA !1DF9		; Play Sound Effect (hit head)

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;	Sprite Loop

MarioSkip:	; Entry point if Mario didn't make contact.

		LDX.b #!SprSize
--
		DEX
		BMI ++

		LDA !14C8,x		; Sprite Status
		BEQ --			; Don't interact with null sprites
		CMP #$08		; If the Sprite's status is normal, A-ok
		BEQ +
		CMP #$09		; If the Sprite's status is carryable, A-ok
		BEQ +
		CMP #$0A		; At this point, if the sprite isn't being kicked, not OK.
		BNE --
+
		CPX !15E9
		BEQ --

		JSR CheckExceptions ; Check for Exceptions
		BNE --

		;LDA !1686,x		; "Sprite properties, fifth Tweaker/MWR byte."
		;BMI --			; Specifically checking "d=Don't interact with objects"
		;AND #$08
		;BNE --			; And also "s=Don't interact with other sprites"

		JSL $03B6E5		; Get Sprite Clipping (ClipRAM B)
		JSL $03B72B 	; Check for Contact
		BCC --

		LDA $5A			; copy of Punchy's !C2,x
		CMP #$02
		BNE ActivatePunchy_Sprites

		LDY $59			; Copy of Punchy's Direction and color (in Scratch RAM)

		LDA FlingDirection,y
		STA !157C,x

		LDA FlingSpeed_LR,y
		STA !B6,x 		; Sprite X Speed

		LDA FlingSpeed_Upwards,y
		STA !AA,x		; Sprite Y Speed

		LDA #$01		;
		STA !1DF9		; Play Sound Effect (hit head)

		LDA !14C8,x		; Sprite status
		CMP #$09
		BNE --
		; [!14C8,x EQ #$09] -- other sprite is in "Carryable" state.
		LDA #$0A
		STA !14C8,x

		BRA -- ; Next Sprite
++
	LDX !15E9

	RTS
	; End of Code (Sprite Loops)

;
;	Activating Punchy.
;		Only happens in state 0 or 3.
;		Sets $C2,x to #$01 and the timer at ($1528,x) to 0 (for a fresh start)
;

ActivatePunchy_Sprites:
	LDX !15E9	; Get Punchy's Sprite Index back.
ActivatePunchy:
	LDA #$01
	STA !C2,x
	STZ !1528,x
	RTS
	; End of Code (Punchy Activated)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
;	SpriteHitBox
;		Sets the Scratch RAM for ClipRAM A.
;		Also makes a copy of (!157C,x) into Scratch RAM $59.
;
;	The Hitbox depends on the sprite's current state and direction.
;

Hitbox_XDisp:
db $00,$00,$00,$00
Hitbox_XLength:
db $10,$10,$10,$10
Hitbox_YDisp:
db $FE,$00,$FE,$00
Hitbox_YHeight:
db $12,$08,$12,$08

SpriteHitbox:
	LDY #$00
	LDA !C2,x
	STA $5A		; (as a copy of !C2,x in Scratch RAM)
	CMP #$02
	BEQ +
	INY		; so if !C2,x isn't #$02, y gets +1
+
	LDA !157C,x
	STA $59		; (as a copy of !157C,x in Scratch RAM)
	BEQ +
	INY			; If facing right, y gets +2
	INY
+
	LDA !extra_prop_2,x
	AND #$03
	ASL
	ORA $59		; (copy of !157C,x combined with a copy of !extra_prop_2 in Scratch RAM)
	STA $59

	LDA !E4,x	;v
	CLC
	ADC Hitbox_XDisp,y
	STA $04		; X-Disp, Low Byte

	LDA !14E0,x	;v
	ADC #$00
	STA $0A		; X-Disp, High Byte

	LDA Hitbox_XLength,y	;v
	STA $06		; X-Disp, Length

	STZ $0F
	LDA Hitbox_YDisp,y
	BPL +
	DEC $0F
+
	CLC
	ADC !D8,x	;v
	STA $05		; Y-Disp, Low Byte

	LDA !14D4,x	;v
	ADC $0F
	STA $0B		; Y-Disp, High Byte

	LDA Hitbox_YHeight,y	;v
	STA $07		; Y-Disp, Height


	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	[EXCEPTIONS]
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckExceptions:
	LDA !7FAB10,x
	AND #$0C
	LSR #2
	TAY
	LDA ExtraBitMask,y
	STA $00

	LDA !7FAB9E,x
	LSR #3
	ORA $00
	TAY
	LDA Exceptions_Table,y
	STA $00

	; $00 now contains the bits from the Exceptions Table

	LDA !7FAB9E,x
	AND #$07
	TAY
	LDA BitTable,y
	AND $00
	RTS

;Vanilla_Exceptions:
;db $0E,$1A,$1C,$45,$59,$5A,$6B,$6C
;db $6D,$79,$7B,$B1,$B9,$C7,$1E,$2C
;db $49,$4B,$4C,$64,$9B,$1F,$9E,$A5
;db $A6,$AC,$AD,$BB,$4A,$63,$A3,$E0
;db $2A,$2E,$3C,$52,$9F,$B7,$B8,$60
;db $29
ExtraBitMask:
db $00,$20,$40,$60

BitTable:
db $80,$40,$20,$10,$08,$04,$02,$01
  ;$x0,$x1,$x2,$x3,$x4,$x5,$x6,$x7	; First Byte
  ;$x8,$x9,$xA,$xB,$xC,$xD,$xE,$xF	; Second Byte

Exceptions_Table:
; Bit = 1 = Exception (don't interact with Punchy)
; Bit = 0 = Run normally.

; Extra Bits = 0 (Vanilla sprites, normally)
;	01234567, 89ABCDEF
db %00000000,%00000010	; $0x -- (Sprite  $0E)
db %00000000,%00101011	; $1x -- (Sprites $1A,$1C,$1E,$1F)
db %00000000,%01101010	; $2x -- (Sprites $29,$2A,$2C,$2E)
db %00000000,%00001000	; $3x -- (Sprite  $3C)
db %00000100,%01111000	; $4x -- (Sprites $45,$49,$4A,$4B,$4C)
db %00100000,%01100000  ;     -- $52,$59,$5A
db %10011000,%00011100  ;     -- $60,$63,$64,$6B,$6C,$6D
db %00000000,%01010000  ;     -- $79,$7B
db %00000000,%00000000  ;     -- --
db %00000000,%00010011  ;     -- $9B,$9E,$9F,
db %00010110,%00001100  ;     -- $A3,$A5,$A6,$AC,$AD
db %01000001,%11010000  ;     -- $B1,$B7,$B8,$B9,$BB
db %00000001,%10000000  ;     -- $C7,$C8
db %00000000,%00000000  ;     -- --
db %10000000,%00000000  ;     -- $E0
db %00000000,%00000000  ;     -- --

; Extra Bits = 1	(Custom sprites start here)
;	01234567, 89ABCDEF
db %00000000,%00000000	; $0x
db %00000000,%00000000	; $1x
db %00000000,%00000000	; $2x
db %00000000,%00000000	; $3x
db %00000000,%00000000	; $4x
db %00000000,%00000000	; $5x
db %00000000,%00000000	; $6x
db %00000000,%00000000	; $7x
db %00000000,%00000000	; $8x
db %00000000,%00000000	; $9x
db %00000000,%00000000	; $Ax
db %00000000,%00000000	; $Bx
db %00000000,%00000000	; $Cx
db %00000000,%00000000  ; $Dx
db %00000000,%00000000  ; $Ex
db %00000000,%00000000	; $Fx

; Extra Bits = 2
;	01234567, 89ABCDEF
db %00000000,%00000000	; $0x
db %00000000,%00000000	; $1x
db %00000000,%00000000	; $2x
db %00000000,%00000000	; $3x
db %00000000,%00000000	; $4x
db %00000000,%00000000	; $5x
db %00000000,%00000000	; $6x
db %00000000,%00000000	; $7x
db %00000000,%00000000	; $8x
db %00000000,%00000000	; $9x
db %00000000,%00000000	; $Ax
db %00000000,%00000000	; $Bx
db %00000000,%00000000	; $Cx
db %00000000,%00000000  ; $Dx
db %00000000,%00000000  ; $Ex
db %00000000,%00000000	; $Fx

; Extra Bits = 3
;	01234567, 89ABCDEF
db %00000000,%00000000	; $0x
db %00000000,%00000000	; $1x
db %00000000,%00000000	; $2x
db %00000000,%00000000	; $3x
db %00000000,%00000000	; $4x
db %00000000,%00000000	; $5x
db %00000000,%00000000	; $6x
db %00000000,%00000000	; $7x
db %00000000,%00000000	; $8x
db %00000000,%00000000	; $9x
db %00000000,%00000000	; $Ax
db %00000000,%00000000	; $Bx
db %00000000,%00000000	; $Cx
db %00000000,%00000000  ; $Dx
db %00000000,%00000000  ; $Ex
db %00000000,%00000000	; $Fx





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DrawGraphics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DirectionOffset:
db $00,$0C

XDisp:
; - Facing Right
db	$F0,$EC,$EF,$F6
db  $FE,$00,$00,$00
db  $FE,$F6,$EE,$F0
; Facing Left
db	$10,$14,$11,$0A
db  $02,$00,$00,$00
db  $02,$0A,$12,$10

DrawGraphics:
	lda #!GFX_FileNum        ; find or queue GFX
	%FindAndQueueGFX()
	bcs .gfx_loaded
	rts                      ; don't draw gfx if ExGFX isn't ready
.gfx_loaded
	%GetDrawInfo()

	LDA !15F6,x ; Properties
	STA $04		; Scratch RAM

	LDA !1528,x ; Timer
	STA $05		; Scratch RAM

	LDA !157C,x
	TAX
	LDA DirectionOffset,x
	CLC
	ADC $05
	TAX

	LDA $00
	CLC
	ADC XDisp,x
	STA !0300,y

	LDA $01
	STA !0301,y

	LDX #!Tile
	lda !dss_tile_buffer,x
	STA !0302,y

	LDA $04		; Properties
	ORA $64
	STA !0303,y

	LDX !15E9	; Regain Punchy's Sprite Slot

	LDA #$00	; 1 tile
	LDY #$02	; 16x16
	JSL $01B7B3	; Finish OAM Write

	RTS