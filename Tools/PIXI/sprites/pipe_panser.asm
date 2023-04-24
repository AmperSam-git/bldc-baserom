;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Pipe-Dwelling Panser
;	by MarioFanGamer
;
; This sprite is a Panser which throws fireballs to the
; player. The clue is that these are pipe dwelling and
; not walking on the ground.
;
; Depending on the first extra property byte, the Panser
; either comes out of the pipe and fires a load of
; fireballs or it will come and shoot when the player is
; close to the pipe.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Settings for a periodic Panser:
;
; Uses extra bytes: Two.
;
; Extra byte 1: Interval to wait inside the pipe.
;
; Extra byte 2: Interval of shooting fireballs
;
; Extra byte 3: Player range to not emerge from pipe.
;		(half range for each side).
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Settings for a dwelling Panser:
;
; Uses extra bytes: Two.
;
; Extra byte 1: Interval of shooting fireballs
;
; Extra byte 2: Player range to not emerge from pipe
;		(half range for each side).
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!GFX_FileNum = $9A      	;DSS ExGFX number for this sprite

!ShootSound = $27			; The sound to play when the Panser throws a fireball.
!ShootBank = $1DFC|!addr	;

!FireballSprite = $B5		; The sprite number of the fireball.

!FireballXSpeed = $10		; How fast the fireball is moving horizontally.
!FireballYSpeed = $A8		; How fast the fireball is moving vertically.

Frames:
db $00,$01


; Internal defines, do not change
!Timer = !1540
!TimeHide = !1534
!TimeShoot = !1528
!Range = !151C

FireballXSpeed:
db !FireballXSpeed, -!FireballXSpeed

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Init code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
Init:						;
	LDA !E4,x				; Offset sprite by eight pixels to the right
	CLC : ADC #$08			;
	STA !E4,x				;
	LDA !14E0,x				;
	ADC #$00				;
	STA !14E0,x				;
							;
	LDA !extra_prop_1,x		; If a dwelling Panser:
	BEQ .Periodic			;
	LDA #$0E				; Different state...
	STA !C2,x				;
	LDA !extra_byte_1,x		; ... first extra byte has shot timer...
	STA !TimeShoot,x		;
	LDA !extra_byte_2,x		; ... second extra byte has range.
	STA !Range,x			;
RTL							;
							;
.Periodic:					;
	LDA !extra_byte_1,x		; First extra pipe has hiding timer...
	STA !TimeHide,x			;
	STA !Timer,x			; ... and also set dwelling time...
	LDA !extra_byte_2,x		; ... second extra byte has shoot timer...
	STA !TimeShoot,x		;
	LDA !extra_byte_3,x		; ... third extra byte has range.
	STA !Range,x			;
RTL							;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main code wrapper
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
	PHB
	PHK
	PLB
	JSR Main
	PLB
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Main code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


Main:
	JSR Graphics			; Draw sprite
							;
	LDA !14C8,x				; If sprite is alive...
	EOR #$08				;
	ORA $9D					; ... or game is running...
	BNE .Return				;
							;
	LDA #$00				;
	%SubOffScreen()			;
							;
	JSL $01A7DC|!bank		; Handle interaction
	JSL $018032|!bank		;
							;
	TXY						; Preserve X
	LDX !C2,y				; Get state
	JSR (States,x)			;
.Return:					;
RTS							;

States:
dw .PeriodicInPipe			; 0x00
dw .Pipe					; 0x02
dw .PrepareShoot			; 0x04
dw .PeriodicShooting		; 0x06
dw .PeriodicWait			; 0x08
dw .Pipe					; 0x0A
dw .PeriodicLoop			; 0x0C

dw .DwellingInPipe			; 0x0E
dw .Pipe					; 0x10
dw .PrepareShoot			; 0x12
dw .DwellingShooting		; 0x14
dw .DwellingWait			; 0x16
dw .Pipe					; 0x18
dw .DwellingLoop			; 0x1A

.Pipe:
	TYX						; Restore
	JSL $01801A|!bank		; Apply speed
	LDA !Timer,x			; Came out of pipe?
	BNE ..Return			;
	INC !C2,x				; Next state
	INC !C2,x				;
..Return:					;
RTS							;

.PrepareShoot:
	TYX						; Restore
	LDA !TimeShoot,x		; Time to wait before shooting
	STA !Timer,x			;
	INC !C2,x				; Next state
	INC !C2,x				;
RTS							;

.PeriodicLoop:
	TYX						; Restore
	STZ !C2,x				; Reset state
	LDA !TimeHide,x			; Set time to wait
	STA !Timer,x			;
.PeriodicInPipe:			;
	TYX						; Restore
	LDA !Timer,x			; Wait to come out
	BNE ..Return			;
	LDA !Range,x			; Is the range enabled?
	BEQ ..NoHide			;
	LDA !15A0,x				; Offscreen?
	BNE ..Return			;
	JSR CheckRange			; Is the player close?
	BCC ..Return			;
..NoHide:					;
	LDA #$02				; Come out of pipe.
	STA !C2,x				;
	LDA #$10				; 16 frames.
	STA !Timer,x			;
	LDA #$F0				; One block.
	STA !AA,x				;
..Return:					;
RTS							;

.PeriodicShooting:
	TYX						; Restore
	LDA $14					; Animate sprite
	LSR #3					;
	AND #$01				;
	STA !1602,x				;
	LDA !Timer,x			; Time to shoot?
	BNE ..Return			;
	JSR ShootFireball		; Yes.
	LDA #$08				;
	STA !C2,x				;
	LDA #$10				; Going down.
	STA !Timer,x			;
	LDA #$10				;
	STA !AA,x				;
..Return:					;
RTS							;

.PeriodicWait:
	TYX						; Restore
	LDA !Timer,x			;
	BNE ..Return			;
	STZ !1602,x				;
	LDA #$10				;
	STA !Timer,x			;
	LDA #$0A				;
	STA !C2,x				;
..Return:					;
RTS							;

.DwellingLoop:
	TYX						; Restore
	LDA #$0E				; Reset state
	STA.w !C2,x				;
.DwellingInPipe:			;
	TYX						; Restore
	LDA !15A0,x				; Sprite is offscreen?
	BNE ..Return			;
	JSR CheckRange			; Check range
	BCS ..Return			; When nearby, shoot a fireball.
	LDA #$F0				; Hiding now.
	STA !AA,x				;
	LDA #$10				;
	STA !Timer,x			;
	LDA #$10				;
	STA !C2,x				;
..Return:					;
RTS							;

.DwellingShooting:			;
	TYX						; Restore
	LDA $14					; Animate sprite
	LSR #3					;
	AND #$01				;
	STA !1602,x				;
	JSR CheckRange			; Player is close?
	BCS ..Hide				;
	LDA !Timer,x			;
	BNE ..Return			;
	JSR ShootFireball		; Shoot a fireball then.
	LDA #$16				;
	STA !C2,x				;
	LDA #$04				;
	STA !Timer,x			;
..Return:					;
RTS							;
							;
..Hide:						;
	STZ !1602,x				; Close mouth
	LDA #$10				;
	STA !Timer,x			;
	LDA #$18				;
	STA !C2,x				;
	LDA #$10				;
	STA !AA,x				;
RTS							;

.DwellingWait:				;
	TYX						; Restore
	LDA !Timer,x			;
	BNE ..Return			;
	JSR CheckRange			;
	BCS ..Hide				;
	LDA !TimeShoot,x		;
	STA !Timer,x			;
	LDA #$14				; Loop the cycle
	STA !C2,x				;
..Return:					;
RTS							;

..Hide:						;
	STZ !1602,x				;
	LDA #$10				;
	STA !Timer,x			;
	LDA #$18				;
	STA !C2,x				;
RTS							;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Subroutines
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Simple 16x16 GFX routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Graphics:
	lda #!GFX_FileNum
	%FindAndQueueGFX()
	bcs .gfx_loaded
	rts
.gfx_loaded
	%GetDrawInfo()			;
							;
	LDA !186C,x				; Is sprite offscreen vertically?
	BEQ .OnScreen			;
	LDA #$F0				; Don't draw tile then.
	STA $0301|!addr,y		;
RTS							;
							;
.OnScreen:					;
	LDA $14					; Get frame counter into carry
	LSR #4					;
	LDA $00					; Code is really self-explanatory
	STA $0300|!addr,y		;
	LDA $01					;
	STA $0301|!addr,y		;
	LDA !1602,x				;
	TAX						;
	LDA Frames,x			;
	TAX
	lda.l !dss_tile_buffer,x
	STA $0302|!addr,y		;
	LDX $15E9|!addr			;
	LDA !15F6,x				; Get sprite properties with lower priority.
	ORA #$01				;
	STA $0303|!addr,y		;
	TYA						; Get extended OAM properties
	LSR #2					;
	TAY						;
	LDA !15A0,x				; Sprite is off-screen flag (X-high bit)
	ORA #$02				; 16x16 tile
	STA $0460|!addr,y		;
RTS							;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Shoots a fireball in the air
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShootFireball:
	STZ $00					; Above Panser
	LDA #$F0				;
	STA $01					;
	%SubHorzPos()			;
	LDA FireballXSpeed,y	; Shoot towards the player
	STA $02					;
	LDA #!FireballYSpeed	;
	STA $03					;
	LDA #!FireballSprite	; Firball sprite (I hope you set it right...)
	SEC						;
	%SpawnSprite()			;
	BCS +					;
	LDA #!ShootSound		; When spawned properly, play sound.
	STA !ShootBank			;
	LDA #$01				; When shooting, have mouth always open
	STA !1602,x				;
+							;
RTS							;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Checks, whether the player is close to the
; sprite.
;
; Output:
;	C: Clear if inside, set if outside.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckRange:					;
	%SubHorzPos()			;
	LDA !Range,x			;
	LSR						; Half range
	CLC : ADC $0E			; Player range
+	CMP !Range,x			;
RTS

