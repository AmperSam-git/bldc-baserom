;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; goombrat/goombud
;; by sonikku
;; basically just the smw goomba but it walks on ledges
;; 
;; set the extension to values 00-07 to accomplish different types of behaviour
;; 
;; the various behaviours are as follows:
;; 00 - normal; walks
;; 01 - para-1; walks, then hops 3 times before making a larger 4th hop			a la sprite x10
;; 02 - para-2; flies left bobbing up and down						a la sprite x08
;; 03 - para-3; bounces upon touching the floor; x position defines height		a la sprite x09
;; 04 - para-4; flies left/right in intervals						a la sprite x0A
;; 05 - para-5; flies up/down in intervals						a la sprite x0B
;; 06 - para-6; oscillates up and down in intervals; extra bit spawns group of 5*	a la sprite x39 (xDE for group)
;; 07 - sliding; slides on slopes							a la sprite xBD
;; 
;; * the 4 others that spawn alongside the placed sprite utilize a flag that detects if this sprite has
;; been killed or despawned. if it hasn't, the others will not despawn when going offscreen.
;; 
;; if the .json's "Hop in/kick shells" bit is set, it'll not walk on ledges and use a different tilemap (default smw goombrat)
;; this is if you want to customize the palette and stuff
;; you can also just set the 5th bit in the Extension field (i.e. "15" instead of "05") to accomplish the same thing
;; 
;; asakumop (https://twitter.com/asakumop) tweeted the graphics at me

!GFX_FileNum = $86		;EXGFX number for this sprite

!base2 = !Base2
print "INIT ",pc
	PHB
	PHK
	PLB
	JSR +
	PLB
	RTL
+	LDA #$FF		; \ default parent is none
	STA !160E,x		; / poor orphan boy
	%SubHorzPos()		; \ 
	TYA			;  | face mario
	STA !157C,x		; / 
	LDA !extra_byte_1,x	; \
	AND #$10		;  | branch if extra bit clear
	BEQ +			; /
	LDA #$04		; \ set palette
	STA !15F6,x		; /
	LDA !1656,x		; \
	ORA #$40		;  | make it so it's just a normal goomba
	STA !1656,x		; /
+	LDA !extra_byte_1,x	; \
	AND #$07		;  | make it so some idiot doesn't load sprite behaviour x8, crash the game, and then they message me on discord asking why it breaks
	STA !1594,x		; /
	ASL			; \ load pointer to states
	TAX			;  | 
	JMP (.ptr_init,x)	; /
.ptr_init
	dw .init_ret
	dw .init_ret2
	dw .init_ret2
	dw .init_bounce
	dw .init_ret2
	dw .init_ret2
	dw .init_spawn4
	dw .init_ret2

.init_ret
	LDX $15E9|!base2	; 
	LDA #$01		; \ basically just make it so the sprite doesn't immediately turn around
	STA !1510,x		; /
.init_ret2
	RTS			; 

.init_bounce
	LDX $15E9|!base2	; 
	LDA !D8,x		; \
	LSR : LSR : LSR : LSR	;  | initial y position determines height
	AND #$01		;  | 
	STA !1510,x		; /
	RTS			; 
.init_spawn4
	LDX $15E9|!base2	; 
	LDA !7FAB10,x		; \
	AND #$04		;  | branch if extra bit clear
	BEQ .init_ret2		; /
	LDA #$06		; \ set this type
	STA !1594,x		; /
	STZ $00			; \
	STZ $02			;  | clear some default offsets
	STZ $03			; /
	LDY #$00		; 
-	PHY			; 
	LDA #$10		; \
	LDY !157C,x		;  | 
	BNE +			;  | 
	LDA #$F0		;  | offset next sprite by the amount in A based on direction each loop
+	CLC			;  | 
	ADC $00			;  | 
	PLY			;  | 
	STA $00			; /
	PHX			; 
	STZ $08			; initial movement direction
	LDX #$00		; \
	TYA			;  | 
	AND #$01		;  | 
	BNE +			;  | every other position in the loop swaps the initial swoop and offset
	INC $08			;  | 
	LDX #$20		;  | 
+	STX $01			; /
	PLX			; 
	PHY			; 
	LDA !7FAB9E,x		; \
	SEC			;  | same sprite as this one
	%SpawnSprite()		; /
	LDA #$06		; \
	STA !1594,x		;  | same state as this one
	STA !1594,y		; /
	LDA !1656,x		; 
	STA !1656,y		; 
	LDA !15F6,x		; 
	STA !15F6,y		; 
	LDA #$08		; \ status = #$08, we don't really wanna run this init again lol
	STA !14C8,y		; /
	LDA !157C,x		; \ same direction as this sprite
	STA !157C,y		; /
	LDA $08			; \ set initial swoop
	STA !C2,y		; /
	TXA			; \ this sprite = child sprite's parent
	STA !160E,y		; /
	PLY			; 
	INY			; 
	CPY #$04		; 
	BCC -			; 
	RTS			; 

print "MAIN ",pc
	PHB			; \
	PHK			;  | 
	PLB			;  | 
	JSR Main		;  | load sprite routine
	PLB			;  | 
	RTL			; /

Main:	LDA !167A,x		; 
	PHA			; 
	STZ !167A,x
	LDA !160E,x		;; !160E,x contains the "parent" sprite index (used for the group of 5)
	BMI ++			; branch if no parent
	PHX			; 
	TAX			; 
	LDA !14C8,x		; \
	CMP #$01		;  | 
	BEQ +			;  | branch if parent sprite is alive in any way
	CMP #$08		;  | 
	BCS +			; /
	PLX			; 
	LDA #$FF		; \ sprite has been orphaned :(
	STA !160E,x		; /
	BRA ++			; 
+	PLX			; 
	LDA #$04		; \ can't despawn if it has a parent
	STA !167A,x		; /
++	%SubOffScreen()		; handle offscreen situation
	PLA			; 
	STA !167A,x		; 
	LDA !157C,x		; 
	PHA			; 
	LDA !15AC,x		; \
	CMP #$04		;  | 
	BCC +			;  | change the direction the sprite faces during the turning animation (but only for the graphics routine)
	LDA !157C,x		;  | 
	EOR #$01		;  | 
	STA !157C,x		; /
+	JSR .subgfx		; load graphics routine
	PLA			; 
	STA !157C,x		; 
	LDA $9D			; \ branch if sprites locked
	BNE .return		; /
	LDA !14C8,x		; \
	CMP #$08		;  | branch if sprite is alive
	BEQ +			; /
.return	RTS			; 
+	LDA !14C8,x		; 
	PHA			; 
	JSL $01A7DC		; load sprite collision routine
	LDA !14C8,x		; \
	CMP #$04		;  \ branch if killed via stomp/spin jump
	BCC .nostun		;  /
	CMP #$09		;  | check to see if the status *would* be stunned
	BNE .nostun		; /
	LDA !1594,x		; \ do normal stuff when it isn't winged
	BEQ .stun		; /
	CMP #$07		; \ but also if it's sliding
	BEQ .stun		; /
	PLA			; 
	STA !14C8,x		; block status change
	STZ !AA,x		; no y speed
	STZ !B6,x		; no x speed
	PHA
.stun	STZ !1594,x		; no longer winged
	STZ !1510,x		; no longer on-ground
.nostun	PLA			; 
+	LDA !1594,x		; \
	ASL			;  | load pointer to behaviours
	TAX			;  | 
	JMP (.ptr,x)		; /
.ptr	dw .goomba_normal
	dw .goomba_winged
	dw .goomba_winged_para1
	dw .goomba_winged_para2
	dw .goomba_winged_para3
	dw .goomba_winged_para4
	dw .goomba_winged_para5
	dw .goomba_slide

.goomba_normal
	LDX $15E9|!base2	; 
	JSL $018032		; interact with other sprites
	JSL $01802A		; process x/y speeds with gravity
	LDA !1588,x		; \
	AND #$03		;  | branch if touching wall
	BNE .touch_wall		; /
	LDA !1588,x		; \
	AND #$04		;  | branch if in the air
	BEQ .in_air		; /
	JSR .set_yspeed		; adjust y speed on the ground based on whether or not sprite is on slope
	LDA #$01		; \ set on-ground flag
	STA !1510,x		; /
	LDA !15AC,x		; \ branch if sprite is turning around
	BNE +			; /
	JSR .set_xspeed		; load x speed based on direction
+	INC !1570,x		; increment frame counter
	BRA +			; 
.in_air
	LDA !1656,x		; \
	AND #$40		;  | branch if "hop in/kick shells" set
	BNE +			; /
	LDA !1510,x		; \ branch when not able to turn around
	BEQ +			; /
	STZ !AA,x		; nullify y speed
	STZ !1510,x		; clear flag for turning at ledges
.touch_wall
	JSR .flip_dir		; flip sprite direction
+	LDA !1588,x		; \
	AND #$08		;  | branch if not touching ceiling
	BEQ +			; /
	STZ !AA,x		; nullify y speed
+	JSR .set_animation	; set animation
	RTS			; 
	
.goomba_winged
	LDX $15E9|!base2	; 
	JSL $018032		; interact with other sprites
	JSL $01802A		; process x/y speeds with gravity
	JSR .set_xspeed		; load x speed based on direction
	DEC !AA,x		; decrease gravity of sprite
	LDA !1510,x		; \
	LSR			;  | 
	LSR			;  | set normal frame based on !1510,x
	LSR			;  | 
	AND #$01		;  | 
	STA !1602,x		; /
	INC !1510,x		; increment turn around frame counter
	LDA !151C,x		; \ wing animation state
	BNE +			; /
	LDA !AA,x		; \ branch if sprite going down
	BPL +			; /
	INC !1570,x		; \ increment wing animation frame
	INC !1570,x		; /
+	INC !1570,x		; increment wing animation frame
	LDA !1588,x		; \
	AND #$08		;  | check if not touching ceiling
	BEQ +			; /
	STZ !AA,x		; nullify y speed
+	LDA !1588,x		; \
	AND #$04		;  | check if not touching the floor
	BEQ .finish_para	; /
	LDA !1510,x		; \
	AND #$3F		;  | branch if turn timer isn't set
	BNE +			; /
	%SubHorzPos()		; \
	TYA			;  | turn around
	STA !157C,x		; /
+	JSR .set_yspeed		; adjust y speed on the ground based on whether or not sprite is on slope
	LDA !151C,x		; \
	BNE +			;  | clear wing animation counter any time the wing animation state is zero
	STZ !1570,x		; /
+	LDA !1540,x		; \ branch if timer set
	BNE .finish_para	; /
	INC !151C,x		; 
	LDY #$F0		; \
	LDA !151C,x		;  | 
	CMP #$04		;  | 
	BNE +			;  | 
	STZ !151C,x		;  | Y will contain y speed
	JSL $01ACF9		;  | randomize the sprites timer
	AND #$3F		;  | 
	ORA #$50		;  | 
	STA !1540,x		;  | 
	LDY #$D0		;  | 
+	STY !AA,x		; /
	LDA !1588,x		; \
	AND #$03		;  | branch if not touching wall
	BEQ .finish_para	; /
	JSR .flip_dir		; flip sprite
.finish_para
	RTS			; 

.set_xspeed
	LDY !157C,x		; \
	LDA !1594,x
	CMP #$06
	BNE +
	INY : INY
+	LDA .xspeed,y		;  | set x speed based on direction
	STA !B6,x		; /
	RTS			; 
.xspeed	db $08,$F8,$10,$F0
.set_yspeed
	LDY #$00		; \
	LDA !15B8,x		;  | 
	BEQ +			;  | set y speed based on whether sprite is on a slope or not
	LDY #$18		;  | 
+	TYA			;  | 
	STA !AA,x		; /
	RTS			; 
.set_animation
	LDA !1570,x		; \
	LSR : LSR : LSR		;  | set A index based on frame counter
	AND #$01		; /
	LDY !15AC,x		; \ branch if not turning
	BEQ +			; /
	LDA #$02		; set A index to turn frame
+	STA !1602,x		; set frame
	RTS
.flip_dir
	LDA !B6,x		; \
	EOR #$FF		;  | invert x speed
	INC			;  | 
	STA !B6,x		; /
.flip_dir2
	LDA !157C,x		; \
	EOR #$01		;  | invert direction
	STA !157C,x		; /
	LDA #$08		; \ set turning timer
	STA !15AC,x		; /
	RTS			; 

.goomba_winged_para1
	LDX $15E9|!base2	; 
	JSL $01801A		; update y pos no grav
	JSL $018022		; update x pos no grav
	JSL $018032		; interact with other sprites
	JSR .set_xspeed		; set sprite x speed
	INC !1570,x		; increment animation frame counter
	JSR .set_animation	; set animation
	LDY #$FC		; \
	LDA !1570,x		;  | 
	AND #$20		;  | 
	BEQ +			;  | make sprite bob up and down
	LDY #$04		;  | 
+	TYA			;  | 
	STA !AA,x		; /
	RTS			; 
.goomba_winged_para2
	LDX $15E9|!base2	; 
	JSL $01802A		; set x/y speed with gravity
	LDA !1588,x		; \
	AND #$03		;  | branch if not touching wall
	BEQ +			; /
	JSR .flip_dir		; flip sprite
+	JSR .set_xspeed		; set x speed
	LDA !1588,x		; \
	AND #$04		;  | branch if not touching floor
	BEQ ++			; /
	LDY #$D0		; \
	LDA !1510,x		;  | 
	BNE +			;  | set y speed based on initial x position
	LDY #$B0		;  | 
+	TYA			;  | 
	STA !AA,x		; /
++	DEC !AA,x		; decrease gravity
	INC !1570,x		; increase animation frame counter
	JSR .set_animation	; set animation
	LDA !1588,x		; \
	AND #$08		;  | branch if not touching ceiling
	BEQ +			; /
	STZ !AA,x		; nullify y speed
+	RTS				
.goomba_winged_para3
	LDX $15E9|!base2	; 
	JSL $018022		; update x pos no grav
	JSL $01801A		; update y pos no grav
	LDY #$FC		; \
	LDA !1570,x		;  | 
	AND #$20		;  | 
	BEQ +			;  | make sprite bob up and down
	LDY #$04		;  | 
+	TYA			;  | 
	STA !AA,x		; /
	LDA !B6,x		; \
	JSR .para_shared	;  | oscillate left and right
	STA !B6,x		; /
	RTS			; 
.goomba_winged_para4
	LDX $15E9|!base2	; 
	JSL $01801A		; update y pos no grav
	LDA !AA,x		; \
	JSR .para_shared	;  | oscillate up and down
	STA !AA,x		; /
	RTS			; 
.para_shared
	STA $00			; 
	INC !1570,x		; increment frame counter
	JSR .set_animation	; set animation
	LDA !1540,x		; \ branch when timer set
	BNE .timer_set		; /
	INC !1510,x		; increment 
	LDA !1510,x		; \
	AND #$03		;  | branch if we shouldn't be accelerating
	BNE .timer_set		; /
	LDA !151C,x		; \
	AND #$01		;  | accelerate based on 2 potential values
	TAY			; /
	LDA $00			; \
	CLC			;  | accelerate
	ADC .accel,y		;  | 
	STA $00			; /
	CMP .max,y		; \ branch if not at max speed
	BNE .timer_set		; /
	INC !151C,x		; increment state of acceleration
	LDA #$30		; \ set slow-accel timer
	STA !1540,x		; /
.timer_set
	LDA #$00		; \
	LDY $00			;  | 
	BMI +			;  | 
	INC			;  | set direction based on the direction moving
+	CMP !157C,x		;  | 
	BNE +			;  | 
	JSR .flip_dir2		; /
+	LDA $00			; 
	RTS			; 
.accel	db $FF,$01
.max	db $F0,$10

.goomba_winged_para5
	LDX $15E9|!base2	; 
	JSL $018022		; update x pos no grav
	JSL $01801A		; update y pos no grav
	JSR .set_xspeed		; set x speed
	INC !1570,x		; increment animation frame counter
	JSR .set_animation	; load animation
	LDA !C2,x		; \
	AND #$01		;  | y speed/accel based on state
	TAY			; /
	LDA !AA,x		; \
	CLC			;  | setup y acceleration
	ADC .y_accel,y		;  | 
	STA !AA,x		; /
	CMP .y_max,y		; \ branch if not at the max speed
	BNE +			; /
	INC !C2,x		; increment state
+	RTS			; 
.y_accel
	db $01,$FF
.y_max
	db $18,$E8

.goomba_slide
	LDX $15E9|!base2	; 
	JSL $01802A		; update sprite x/y w/ gravity
	LDA #$00		; \
	LDY !B6,x		;  | 
	BEQ .no_x1		;  | direction based on speed
	BPL +			;  | 
	INC A			;  | 
+	STA !157C,x		; /
.no_x1	LDA !1504,x		; \
	BEQ +			;  | 
	DEC !1504,x		;  | turn sprite to normal if it's no longer sliding
	CMP #$01		;  | 
	BNE +			;  | 
	STZ !1594,x		; /
+	LDA !1504,x		; \ no slope if about to exit slide
	BNE .no_slope		; /
	LDA !1588,x		; \
	AND #$04		;  | branch if not on ground
	BEQ .no_slope		; /
	LDA $14			; \
	AND #$03		;  | branch every 3/4 frames
	BNE +			; /
	LDA !157C,x		; \
	ASL : ASL : ASL		;  | 
	STA $00			;  | 
	LDA #$0C		;  | 
	STA $01			;  | spawn smoke
	LDA #$14		;  | 
	STA $02			;  | 
	LDA #$03		;  | 
	%SpawnSmoke()		; /
+	LDA #$03		; \ set frame
	STA !1602,x		; /
	LDY #$00		; \
	LDA !B6,x		;  | 
	BEQ .no_x2		;  | 
	BPL +			;  | get absolute speed in either direction
	EOR #$FF		;  | 
	INC A			;  | 
+	STA $00			; /
	LDA !15B8,x		; \ branch if not on slope
	BEQ .no_x2		; /
	LDY $00			; \
	EOR !B6,x		;  | branch if sprite is travelling up a slope
	BPL .no_x2		; /
	LDY #$D0		; \ boop the boy up
.no_x2	STY !AA,x		; /
	LDA $14			; \
	AND #$01		;  | branch every other frame
	BNE .no_slope		; /
	LDA !15B8,x		; \ branch when actually on a slope
	BNE .on_slope		; /
	LDA !B6,x		; \ branch if still has x speed
	BNE +			; /
	LDA #$20		; \ set timer before exiting state
	STA !1504,x		; /
	RTS			; 
+	BPL +			; \
	INC !B6,x		;  | decel sprite
	INC !B6,x		;  | 
+	DEC !B6,x		; /
.no_slope
	RTS			; you BROKE my GRILL?

.on_slope
	ASL			; 
	ROL			; 
	AND #$01		; 
	TAY			; 
	LDA !B6,x		; \
	CMP .x_max,y		;  | 
	BEQ +			;  | accelerate based on direction moving
	CLC			;  | 
	ADC .x_accel,y		;  | 
	STA !B6,x		; /
+	RTS			; 
.x_max	db $20,$E0
.x_accel
	db $02,$FE

!0300	= $0300|!Base2
!0301	= $0301|!Base2
!0302	= $0302|!Base2
!0303	= $0303|!Base2
!0460	= $0460|!Base2

.subgfx	
	lda #!GFX_FileNum        ; find or queue GFX
	%FindAndQueueGFX()
	bcs .gfx_loaded
	rts                      ; don't draw gfx if ExGFX isn't ready	
.gfx_loaded
%GetDrawInfo()
	LDA #$FF		; \ tiles drawn = none
	STA $0F			; /

	LDA !14C8,x		; \ state of sprite in $05
	STA $05			; /

	LDA !1594,x		; \ type of goomba in $06
	STA $06			; /

	LDA #$01		; \ draw first wing
	JSR .draw_wings		; / (this is a dumb way to do this, but it gives increased control over tile priority)

	LDA !157C,x		; \ direction of sprite in $02
	STA $02			; /

	PHY
	LDY !1602,x		; \ frame of sprite in $03
	LDA !1656,x		;  | 
	AND #$40		;  | 
	BEQ +			;  | 
	TYA : CLC		;  | 
	ADC #$04 : TAY		;  | 
+	STY $03			; /
	PLY
	
	LDA !15F6,x		; \ palette of sprite in $04
	STA $04			; /

	PHX			; 
	LDA $00			; \ load x position of tile
	STA !0300,y		; /

	LDA $01			; \ load y position of tile
	STA !0301,y		; /

	PHX
	LDX $03			; 
	LDA .tilemap,x		;  | load tilemap of sprite
	TAX
	lda !dss_tile_buffer,x
	PLX
	STA !0302,y		; /

	LDA .palette,x		; \
	CMP #$FF		;  | branch if sprite should be using given palette
	BEQ .setprop		; /
	LDA $04			; \ factor palette in
	AND #$FE		;  | factor out gfx page
	ORA .palette,x		;  | factor in our own gfx page
	LDX $02			; /
	BRA +			; 
.setprop			; 
	LDX $02			; \
	LDA $04			;  | 
+	PHY			;  | 
	LDY $05			;  | 
	CPY #$08		;  | 
	BEQ +			;  | 
	INX : INX		;  | factor in palette and flipping when needed based on direction or state
+	PLY			;  | 
	ORA .properties,x	;  | 
	ORA $64			;  | 
	STA !0303,y		; /

	PHY			; \
	TYA			;  | 
	LSR : LSR		;  | 
	TAY			;  | set tile size
	LDA #$02		;  | 
	STA !0460,y		;  | 
	PLY			; /
	PLX			; 
	INY : INY : INY : INY	; 
	INC $0F			; increment tiles used

	LDA #$00		; \ draw second wing
	JSR .draw_wings		; / (this is a dumb way to do this, but it gives increased control over tile priority)

	LDY #$FF		; 
	LDA $0F			; 
	JSL $01B7B3		; 
	RTS			; 
.tilemap
	db $00,$01,$00,$02	; walk 1, walk 2, turn
	db $A8,$AA,$A8,$E8	; walk 1, walk 2, turn
.palette
	db $FF,$FF,$FF,$FF
	db $FF,$FF,$FF,$01
.properties
	db $40,$00	; left/right
	db $C0,$80	; flipped left/right

.draw_wings
	STA $0E			; get index of wing drawn
	LDA $06			; \
	BEQ .no_wings		; /
	CMP #$07		; \
	BEQ .no_wings		; /
	LDA $05			; \
	CMP #$08		;  | no wings if not alive and not carried
	BNE .no_wings		; /
	LDA !1570,x		; \
	LSR			;  | 
	LSR			;  | 
	AND #$02		;  |
	CLC			;  | calculate which wing frame to use
	ADC !1602,x		;  | 
	AND #$03		;  | 
	STA $08			;  | 
	ASL			;  | 
	STA $02			; /
	LDA !157C,x		; \ direction of wings
	STA $04			; /
	PHX			; 
	LDX $0E			; \ indexed by wing drawn
	STX $03			; /
	TXA			; \
	CLC			;  | 
	ADC $02			;  | 
	PHA			;  | 
	LDX $04			;  | index for x position of wings
	BNE +			;  | 
	CLC			;  | 
	ADC #$08		;  | 
+	TAX			; /
	LDA $00			; \
	CLC			;  | wing tile x position
	ADC .wing_xpos,x	;  | 
	STA !0300,y		; /
	PLX			; 
	LDA $01			; \
	CLC			;  | wing tile y position
	ADC .wing_ypos,x	;  | 
	STA !0301,y		; /
	LDX $08			; \
	LDA .wing_tilemap,x	;  | wing tilemap
	STA !0302,y		; /
	PHY			; \
	TYA			;  | 
	LSR			;  | 
	LSR			;  | wing tile size
	TAY			;  | 
	LDA .wing_tilesize,x	;  | 
	STA !0460,y		;  | 
	PLY			; /
	LDX $03			; \
	LDA $04			;  | 
	LSR			;  | 
	LDA .wing_prop,x	;  | calculate wing properties and palette
	BCS +			;  | 
	EOR #$40		;  | 
+	ORA $64			;  | 
	STA !0303,y		; /
	INY : INY : INY : INY	; 
	INC $0F			; increment tiles used
	PLX			; 
.no_wings
	RTS			; 
.wing_tilemap
	db $4E,$4E,$5D,$5D
.wing_tilesize
	db $02,$02,$00,$00
.wing_prop
	db $46,$06
.wing_xpos
	db $F7,$0B,$F6,$0D,$FD,$0C,$FC,$0D
	db $0B,$F5,$0A,$F3,$0B,$FC,$0C,$FB
.wing_ypos
	db $F7,$F7,$F8,$F8,$01,$01,$02,$02

; ░░░░░▄▄▄▄▄▄░░░░░
; ░░▄▀▀░░░░░░▀▀▄░░
; ░▄▀░░░░░░░░░░▀▄░
; ░██▀████▀█▄░░░█░
; ░░█ ▄██▄ ▄█░░░█░
; ░▄▀▀▀█▀▀▀▀░░░░█░
; ░█▄░░█░░░▄█████▄
; ████░█░░████████