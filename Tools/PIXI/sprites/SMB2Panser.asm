;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Panser (improved), by imamelia (optimized by Blind Devil)
;;
;; This is a Panser, the fireball-spitting plant in SMB2 that stays in one place
;; or moves back and forth.  This one has different behaviors depending on its
;; palette; I tried to make it as close to the original sprite as possible.
;;
;; Uses first extra bit: NO
;;
;; Uses Extra Byte 1 (Extension). They determine the sprite's palette/behavior.
;; 00 = palette 8
;; 01 = palette 9
;; 02 = palette A
;; 03 = palette B
;; 04 = palette C
;; 05 = palette D
;; 06 = palette E
;; 07 = palette F
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; defines
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!GFX_FileNum = $9A      ;DSS EXGFX number for this sprite

Tilemap:
db $00,$01		; normal frame 1, normal frame 2/fireball-spitting frame

!Fireball = $23		; set this to the sprite number of the fireball

!InitialWaitTime = $60	; the time the sprite should wait before spitting the first fireball
!FireballYSpeed = $B8	; set this to the initial Y speed the fireball should have
!FireballXSpeed = $16	; set this to the initial X speed the fireball should have
!FireSound = $27	; the sound effect to play when spitting a fireball
!FireSoundBank = $1DFC	; the sound bank to use

!UpperBoundX = $31	; one more than the maximum random X speed
!LowerBoundX = $00	; the minimum random X speed
!UpperBoundY = $20	; the maximum random Y speed
!LowerBoundY = $59	; one more than the minimum random Y speed
; Note on the Y speeds: These are negative values, so they are INVERSED.
; Therefore, the lower boundary should actually be HIGHER then the upper one.
; Think of it this way: What would the values be if you set bit 7 of them both,
; i.e. ORA #$80?

FireSpitTimer:				; the time to wait before spitting each fireball
db $58,$20,$58,$20,$20,$58,$20,$58	; I made the table 8 values long so you could
					; have more leeway for the timers

BehavioralProperties:			; some behavior settings for each palette
db $04,$05,$02,$00,$01,$03,$10,$21	; palette 8, 9, A, B, C, D, E, F
; Bit 0 - no movement
; Bit 1 - no X speed for the spawned fireballs
; Bit 2 - *random* XY speeds for the spawned fireballs
; Bit 3 - stay on ledges
; Bit 4 - follow the player (if set to move)
; Bit 5 - jump every now and then

!XSpeed = $0A		; the X speed to give the sprite
!YSpeed = $D0		; the Y speed to give the sprite when it jumps (if set to do so)

;defines below aren't meant to be changed

!UBXRNGDiff = !UpperBoundX-!LowerBoundX
!UBYRNGDiff = !LowerBoundY-!UpperBoundY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; init routine wrapper
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc	; xkas-style init routine marker
PHB			; preserve the current data bank
PHK			; push the program bank onto the stack
PLB			; so we can pull it back as the new data bank
JSR SpriteInit		; jump to the sprite's init routine
PLB			; pull the previous data bank back
RTL			; and return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; init routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SpriteInit:
LDA !15F6,x
AND #$F1
STA !15F6,x

LDA !7FAB40,x
AND #$07
ASL
ORA !15F6,x
STA !15F6,x

LSR			; we still have the extra property byte in A, so...
AND #$07		; divide it by 2 and get an index from 00-07
TAY			; transfer this to Y
LDA BehavioralProperties,y	; load, well...it's pretty self-explanatory...
STA !1504,x		; store to a misc. sprite table for later

LDA #!InitialWaitTime	; start the fireball timer
STA !1540,x		; set the time before spitting the first fireball

JSL $01ACF9|!BankB	; semi-random number generator
PHA			;
ORA #$3F		; set the jump timer to a random number
STA !1570,x		; (but it has to be at least 3F)
PLA			;
AND #$07		; values 00-07 (clear the upper 5 bits)
STA !1534,x		; start the timer index at a random number as well

%SubHorzPos()		;
TYA			;
STA !157C,x		; make the sprite face the player initially

RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine wrapper
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc	; xkas-style main routine marker
PHB		; preserve the current data bank
PHK		; push the program bank onto the stack
PLB		; so we can pull it back as the new data bank
JSR SpriteMain	; jump to the main sprite routine
PLB		; pull the previous data bank back
RTL		; and return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SpriteMain:

JSR SubPanserGFX	; draw the sprite

LDA !14C8,x	; check the sprite status
CMP #$08		; if it is not in its normal status...
BNE Return0	; return
LDA $9D		; check the sprite lock timer
BNE Return0	; if sprites are locked, return

LDA #$00
%SubOffScreen()

JSR SubBPH	; a lame abbreviation of "behavioral property handler"

LDA $14		; take the sprite frame counter
LSR #3		; and divide it by 8
AND #$01	;
STA !1602,x	; to set the animation frame

LDY !1540,x	; BUT if the fireball timer
CPY #$11		; has dropped to 10 or lower...
BCS NotThereYet	; the Panser is about to spit a fireball,
LDA #$01		; so set a constant frame,
STA !1602,x	; the spitting one
NotThereYet:	;
CPY #$00		; if the timer has dropped to zero...
BNE EndMain	; reset it

LDA !1534,x	; take the timer table offset
INC		; increment it once
AND #$07	; clear out the top 5 bits, since we have only 8 values in the table
STA !1534,x	; and set the new table offset
TAY		; transfer this to Y...
LDA FireSpitTimer,y	; and set a new timer depending on this
STA !1540,x	;

JSR SubFireSpit	; jump to the fireball-spitting routine

EndMain:

JSL $01A7DC|!BankB	; interact with the player
JSL $018032|!BankB	; interact with other sprites

Return0:

RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; graphics routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubPanserGFX:

lda #!GFX_FileNum
%FindAndQueueGFX()
bcs .gfx_loaded
rts
.gfx_loaded

STZ $07

LDA !14C8,x
CMP #$08
BCS NotDead

LDA #$80
STA $07

NotDead:
LDY !1602,x
LDA Tilemap,y
STA $02

LDA !15F6,x
ORA $64
ORA $07
STA $03

%GetDrawInfo()

REP #$20
LDA $00
STA $0300|!Base2,y
SEP #$20

PHX
LDA $02
TAX
lda.l !dss_tile_buffer,x
PLX
STA $0302|!Base2,y

LDA $03
STA $0303|!Base2,y

LDY #$02
LDA #$00
JSL $01B7B3|!BankB
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; sprite-spawning routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubFireSpit:
LDA !1504,x		; first check:
AND #$04		; if bit 2 is set...
BEQ NoRandomSpeeds	; give the fireballs semi-random XY speeds

LDA #!UBXRNGDiff
JSR RangedRNG
CLC
ADC #!LowerBoundX
PHA

%SubHorzPos()
CPY #$00
BNE +

PLA
BRA StoreleXSpd

+
PLA
EOR #$FF
INC A

StoreleXSpd:
STA $02

LDA #!UBYRNGDiff
JSR RangedRNG
CLC
ADC #!UpperBoundY
ORA #$80
STA $03
BRA SetSpawnDisps

NoRandomSpeeds:
LDA !1504,x	; check the behavioral settings
AND #$02	; if bit 1 is set...
BNE NoXFireball	; don't set any X speed for the fireballs

LDA #!FireballXSpeed
PHA

%SubHorzPos()
CPY #$00
BNE +

PLA
BRA StoreleXSpd2

+
PLA
EOR #$FF
INC A
BRA StoreleXSpd2

NoXFireball:
LDA #$00

StoreleXSpd2:
STA $02

LDA #!FireballYSpeed
STA $03

SetSpawnDisps:
STZ $00
LDA #$F8
STA $01

LDA #!Fireball
SEC
%SpawnSprite()
CPY #$FF
BEQ NoSFX

LDA #!FireSound			; play a sound effect
STA !FireSoundBank|!Base2	;

NoSFX:
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; behavioral property handler routine (also handles speed updating)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubBPH:		; I'll be using this acronym again in the future, so learn to love it.

LDA !1504,x	; behavioral properties
STA $00		; store to scratch RAM because they are used a lot here

AND #$10	; first, check to see if the sprite should follow the player
BEQ NoFollow	; if bit 4 of the BP table is set...
LDA !151C,x	;
BNE NoFollow	; and the sprite isn't already turning...
LDA $14		;
AND #$1F	; then check the frame counter
BNE NoFollow	;
%SubHorzPos()	; and switch direction to face the player
TYA		; every few frames
STA !157C,x	;

NoFollow:	;

LDA !1588,x	; next, check the sprite's contact
AND #$03	; with walls
BEQ NoWallTouch	; if the sprite is touching a wall...

LDA !157C,x	;
EOR #$01		; flip its direction
STA !157C,x	;

NoWallTouch:

LDA $00		; check the properties
AND #$08	; if bit 3 isn't set...
BEQ MaybeInAir	; don't make the sprite stay on ledges

LDA !1588,x	; if the sprite is on the ground...
ORA !151C,x	; or if it is already turning...
BNE NoFlip	; then don't change direction

LDA !157C,x	;
EOR #$01		; flip the sprite's direction
STA !157C,x	;

LDA !B6,x	; and its speed
EOR #$FF		;
INC		;
STA !B6,x		;

INC !151C,x	; set the turning flag

NoFlip:

LDA !1588,x	;
AND #$04	; check sprite contact with the ground
BEQ Skip1		; skip the next few parts if the sprite is in the air
STZ !AA,x	; zero out the sprite's Y speed
STZ !151C,x	; clear the turn flag
BRA SetXSpeed	;

MaybeInAir:

LDA !1588,x	;
AND #$04	; check sprite contact with the ground
BEQ Skip1		; skip the next few parts if the sprite is in the air
LDA #$10		; give the sprite a little Y speed
STA !AA,x	; so that is has gravity

LDA !1570,x	; if the sprite's jump timer has run out...
BNE SetXSpeed	;
LDA #!YSpeed	; make the sprite jump upward
STA !AA,x	;
JSL $01ACF9|!BankB	; get a random number
AND #$7F	;
CLC		;
ADC #$50	; from 50 to BF
STA !1570,x	; to use as a reset value for the jump timer

SetXSpeed:

LDA #!XSpeed	; load the sprite's X speed
LDY !157C,x	; load the sprite's direction
BEQ NoSwitchX	; if the sprite is facing left...
EOR #$FF		; then invert its X speed
INC		;
NoSwitchX:	;
STA !B6,x		; store the speed value to the X speed table

Skip1:

LDA $00		; check the property byte
AND #$20	; if bit 5 is not set...
BEQ NoJump	; then freeze the jump timer so that the sprite never jumps
DEC !1570,x	; if bit 5 is set, decrement the jump timer (we don't need to check
NoJump:		; to make sure it isn't zero, because the previous code already did)

LDA $00		; check the property byte again
AND #$01	; if bit 0 is set...
BEQ NoZeroX	; don't update the sprite's position

STZ !B6,x

NoZeroX:
JSL $01802A|!BankB	; update sprite position based on speed values
RTS

RangedRNG:
    PHX : PHP
    SEP #$30
    PHA
    JSL $01ACF9|!BankB
    PLX
    CPX #$FF
    BNE .normal
    LDA $148B|!Base2
    BRA .end

.normal
    INX
    LDA $148B|!Base2

if !SA1
        STZ $2250       ; Set multiplication mode.
        REP #$20        ; Accum (16-bit)
        AND #$00FF      ; Mask out high byte.
        STA $2251       ; Write first multiplicand.
        TXA             ; X -> A and mask out high byte.
        AND #$00FF
        STA $2253       ; Write second multiplicand.
        NOP             ; Wait 2 cycles (SEP takes 3, total of 5).
        SEP #$20        ; Accum (8-bit)
        LDA $2307       ; Read multiplication product.
else
        STA $4202       ; Write first multiplicand.
        STX $4203       ; Write second multiplicand.
        NOP #4          ; Wait 8 cycles.
        LDA $4217       ; Read multiplication product (high byte).
endif

.end
PLP : PLX
RTS