;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Cooligan, by Koopster
;
;A penguin that slides around and takes 2 hits to kill.
;
;Make sure to insert sunglasses.asm as an extended sprite and set !ExtendedSprNum in this file
;accordingly, or bad things may happen...
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;extended sprite number
	!ExtendedSprNum = $08

;tilemap: head, feet for normal, flopping 1, flopping 2 respectively.
;	use the cfg editor to change the palette and sprite page.

	!GFX_FileNum = $A7 ; DSS ExGFX
	!Tilemap = $00,$01,$02,$03,$04,$05

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;init
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
	PHB : PHK : PLB

	LDA !1558,x
	BNE +

	%SubHorzPos()
	TYA
	STA !157C,x

	+
	PLB

	RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;wrapper
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
	PHB : PHK : PLB

	LDA $9D
	BNE +

	JSR Main

	+
	JSR Graphics

	PLB

	RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;main code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Main:
	LDA #$07
	%SubOffScreen()

	LDA !14C8,x
	CMP #$08
	BEQ Alive

	LDA !15F6,x		;\
	ORA #$80		;|if the sprite is dead, flip it vertically
	STA !15F6,x		;/

	RTS

Alive:
	JSR SpriteInteract	;run "custom" sprite interaction
	JSL $01A7DC|!bank	;run player interaction
	BCC +				;branch if there is no contact...
	JSR PlayerInteract	;otherwise, run our custom interaction

	+
	LDA !C2,x			;\
	BEQ AnimationEnd	;|
	LDA !1540,x			;|
	LSR #2				;|
	INC					;|
	STA !1602,x			;|update animation frames if flopping
	LDA !1540,x			;|
	BNE AnimationEnd	;|
	LDA #$08			;|
	STA !1540,x			;/

AnimationEnd:
	LDA !1558,x			;\
	BNE +				;|unless coming out of a shooter, run block interaction
	JSL $019138|!bank	;/

	+
	LDA !1588,x		;\
	AND #$03		;|
	BEQ +			;|
	LDA !157C,x		;|flip if we're hitting a wall
	EOR #$01		;|
	STA !157C,x		;/

	+
	LDA !C2,x		;\
	ASL				;|
	ORA !157C,x		;|
	TAY				;|set x speed based on state and direction
	LDA .XSpeed,y	;|
	STA !B6,x		;/

	LDA !1588,x		;\
	AND #$04		;|
	ORA !1558,x		;|
	BEQ +			;|if on the floor or coming out of a shooter, nullify the y speed
	STZ !AA,x		;|
	BRA ++			;/

	+
	LDA !AA,x		;\
	CLC				;|
	ADC #$03		;|
	CMP #$30		;|run custom gravity
	BCC +			;|
	LDA #$30		;|
+	STA !AA,x		;/

	++
	JSL $01801A|!bank	;update x position
	JSL $018022|!bank	;update y position

	RTS

.XSpeed
	db $20,$E0		;regular
	db $10,$F0		;flopping

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;subroutines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;sprite interaction
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SpriteInteract:
	LDA !7FAB9E,x	;\
	STA $5A			;/hold the cooligan sprite number here, since it can't be accessed through y

	TXA
	BEQ .End
	TAY
	EOR $13
	LSR
	BCC .End
	DEX

-	LDA !14C8,x
	CMP #$08
	BCC .Next

	LDA !7FAB9E,x	;\
	CMP $5A			;|is the sprite we're interacting with another cooligan?
	BNE .Vanilla	;/
	LDA.w !C2,y		;\
	CMP !C2,x		;|are they on the same state? if neither, run vanilla interaction
	BEQ .Vanilla	;/

	CLC
	%SprSprInteractVanilla()
	BCC .Next

	LDA !C2,x		;\
	BNE .KillX		;/branch if the other sprite (in x) is the one to die
	PLA				;\
	PLA				;/don't run the rest of the sprite if this sprite is the one to die
	TXA				;\
	TYX				;|flip x and y
	TAY				;/
.KillX
	INC $1490|!addr		;\
	JSR CooliganKill	;|set star timer briefly, as that is used to check the 1-up sound
	DEC $1490|!addr		;/

	LDX $1695|!addr		;restore sprite to interact with (stored here if interaction happened)
	LDY $15E9|!addr		;restore current sprite

	BRA .Next

.Vanilla
	SEC
	%SprSprInteractVanilla()

.Next
	DEX
	BPL -

	LDX $15E9|!addr

.End
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;kills cooligan in x due to cooligan in y
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CooliganKill:
	LDA #$02		;\
	STA !14C8,x		;/kill the sprite in x

	LDA #$D0				;\
	STA !AA,x				;|
	PHY						;|
	LDY !157C,x				;|give it speed
	LDA KillSprite_XSpeed,y	;|
	STA !B6,x				;|
	PLY						;/

	LDA !1626,y			;\
	INC					;|
	CMP #$08			;|
	BCC +				;|
	LDA #$08			;|increment the kill counter of killer sprite and score accordingly
+	STA !1626,y			;|
	JSL $02ACE5|!bank	;|
	LDA !1626,y			;/

	JMP BopSound

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;player interaction
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PlayerInteract:
	LDA $1490|!addr	;\
	BNE KillSprite	;/kill sprite if the player has a star

	LDA !154C,x		;\
	BEQ +			;/check timer so multiple interactions don't happen

	RTS

	+
	LDA #$08		;\
	STA !154C,x		;/reset timer

	LDA $7D			;\
	CMP #$10		;|don't hurt the player if they have enough downward speed
	BPL DoNotHurt	;/

HurtPlayer:
	LDY #$03			;\
-	LDA $17C0|!addr,y	;|
	CMP #$02			;|
	BEQ +				;|double stomp hit fix
	DEY					;|
	BPL -				;/

	LDA $1497|!addr		;\
	ORA $187A|!addr		;|if not invincible or on yoshi,
	BNE +				;/

	JSL $00F5B7|!bank	;hurt the player

	+
	RTS

DoNotHurt:
	LDA $140D|!addr		;\
	ORA $187A|!addr		;|branch if the player is spinjumping or riding yoshi
	BNE SpinJumpedOn	;/

;sprite has been normal jumped on
	JSL $01AA33|!bank	;show contact sprite
	JSL $01AB99|!bank	;bounce off

	LDA !C2,x			;\
	INC					;|
	CMP #$02			;|branch if the sprite is already flopping to kill it
	BEQ KillSprite		;/

	STA !C2,x			;otherwise, set it to flop now

;spawn the glasses extended sprite in the correct position
	LDY !157C,x
	LDA .XOffset,y
	STA $00
	STZ $01
	STZ $02
	LDA #$D0
	STA $03
	LDA #!ExtendedSprNum+!ExtendedOffset
	%SpawnExtended()

	PHY					;\
	LDY !157C,x			;|
	LDA .XFlip,y		;|set its x flip
	PLY					;|
	STA $1765|!addr,y	;/

	BRA BounceScore

.XOffset
	db $10,$00
.XFlip
	db $40,$00

KillSprite:
	PLA					;\
	PLA					;/don't let the rest of the sprite code run this frame

	LDA #$02			;\
	STA !14C8,x			;/set as dead
	STZ !B6,x			;normally, nullify the x speed

	LDA $1490|!addr		;\
	BEQ BounceScore		;/branch if the sprite hasn't been killed by a star

	LDA #$D0			;\
	STA !AA,x			;|
	%SubHorzPos()		;|specify speeds to kill it with
	LDA .XSpeed,y		;|
	STA !B6,x			;/

	LDA $18D2|!addr		;\
	INC					;|
	CMP #$08			;|
	BCC +				;|
	LDA #$08			;|increment star counter and score accordingly
+	STA $18D2|!addr		;|
	JSL $02ACE5|!bank	;|
	LDA $18D2|!addr		;/

	BRA BopSound

.XSpeed:
	db $F0,$10

SpinJumpedOn:
	LDA #$F8			;\
	LDY $187A|!addr		;|
	BEQ +				;|bounce up, higher if on yoshi
	LDA #$A8			;|
+	STA $7D				;/

	LDA #$04			;\
	STA !14C8,x			;|
	LDA #$1F			;|
	STA !1540,x			;|
	JSL $07FC3B|!bank	;|set spinjumped status, timer, draw stars and make sound
	LDA #$08			;|
	STA $1DF9|!addr		;|
	BRA BounceScore		;/

BounceScore:
	LDA $1697|!addr		;\
	INC					;|
	CMP #$08			;|
	BCC +				;|increment bounce counter and score accordingly
	LDA #$08			;|
+	STA $1697|!addr		;|
	JSL $02ACE5|!bank	;/

	LDA !14C8,x			;\
	CMP #$04			;|branch if been spin jumped on
	BEQ InteractEnd		;/

	LDA $1697|!addr

BopSound:
	CLC				;\
	ADC #$12		;|
	CMP #$1A		;|
	BNE +			;|
	LDA #$02		;|make bop sound for normal bouncing or star killing (A = kill counter)
	LDY $1490|!addr	;|
	BEQ +			;|
	INC				;|
+	STA $1DF9|!addr	;/

InteractEnd:
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;graphics
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Graphics:
    lda #!GFX_FileNum
    %FindAndQueueGFX()
    bcs .gfx_loaded
    rts
.gfx_loaded
	%GetDrawInfo()

	LDA $00				;\
	STA $0300|!addr,y	;|
	CLC					;|xpos
	ADC #$10			;|
	STA $0304|!addr,y	;/

	LDA $01				;\
	STA $0301|!addr,y	;|ypos
	STA $0305|!addr,y	;/

	LDA !157C,x			;\
	EOR #$01			;|$02 = sprite direction, flipped
	STA $02				;/

	LDA $64				;\
	STA $03				;|
	LDA !1558,x			;|$03 = level priority
	BEQ +				;|
	STZ $03				;/

	+
	LDA !1602,x			;\
	ASL					;/get current frame times 2
	ORA $02				;operate with direction
	TAX					;\
	LDA .Tilemap,x		;/use as index
	TAX
	lda !dss_tile_buffer,x
	STA $0302|!addr,y	;tilemap, left tile
	TXA					;\
	EOR #$01			;|get the other tile from the table now
	TAX					;/
	LDA .Tilemap,x		;tilemap, right tile
	TAX
	lda !dss_tile_buffer,x
	STA $0306|!addr,y	;

	LDX $02				;\
	LDA .XFlip,x		;/get x flip

	LDX $15E9|!addr		;restore sprite index

	ORA !15F6,x			;get properties from .json + y flip if dead
	ORA $03				;get stuff
	STA $0303|!addr,y	;\
	STA $0307|!addr,y	;/properties

	LDY #$02			;16x16
	LDA #$01			;2 tiles
	%FinishOAMWrite()	;thanks and goodbye

	RTS

.XDisp
	db $F0,$10
.XFlip
	db $00,$40
.Tilemap
	db !Tilemap