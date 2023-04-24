;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Pokey but moves like football (bounces around with it's RNG glory)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; defines and tables
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;easier segment setting. replace 0 with 1 for more segments from the very right (e.g. 00000001 will start with 1 segment, 00011111 will start with 5)
;You can't add more than 5 segments, because there's no code support for more (vanilla pokey would vanish if there were more than 5 segments)
!Segments1 = %00000111		; number of segments the Pokey will have if the extra bit is clear and the player is not on Yoshi
!Segments2 = %00011111		; number of segments the Pokey will have if the extra bit is clear and the player is on Yoshi
!Segments3 = %00001111		; number of segments the Pokey will have if the extra bit is set and the player is not on Yoshi
!Segments4 = %00001111		; number of segments the Pokey will have if the extra bit is set and the player is on Yoshi

!HeadTile = $00			;
!BodyTile = $01			;

!PokeyFix = 1			;fix pokey dupe when trying to hit the top segment from above (it erroneously destroys non-existant segment)

Clipping:			; the sprite clipping value indexed by the number of sections Pokey has
db $1B,$1B,$1A,$19,$18,$17	; 0, 1, 2, 3, 4, 5

PokeyPresentSegment:
db $01,$02,$04,$08		;from top to bottom, highest to lowest

BitTable2:
db $00,$01,$03,$07

BitTable3:
db $FF,$FE,$FC,$F8

PokeyUnsetBit:
db $EF,$F7,$FB,$FD,$FE

BitTable5:
db $E0,$F0,$F8,$FC,$FE

;implemented pokey segment fix while at it
;lowest to highest
PokeySetBit:
db $10,$08,$04,$02,$01

XDisp:
db $00,$01,$00,$FF

Data1:
db $00,$05,$09,$0C,$0E,$0F,$10,$10,$10,$10,$10,$10,$10

YSpeeds:		db $A0,$D0,$C0,$D0			;DATA_03800E

;depending on slope (this is added each time the sprite lands on a slope)
XSpeeds:		db -$10,-$08,-$04,$00,$04,$08,$10

!MaxRightwardSpeed = $20
!MaxLeftwardSpeed = -$20

			!RAM_SpritesLocked	= $9D
			!RAM_SpriteSpeedY	= !AA
			!RAM_SpriteSpeedX	= !B6
			!OAM_DispX		= $0300|!Base2
			!OAM_DispY		= $0301|!Base2
			!OAM_Tile		= $0302|!Base2
			!OAM_Prop		= $0303|!Base2
			!OAM_TileSize		= $0460|!Base2
			!RAM_SpriteDir		= !157C
			!RAM_SprObjStatus	= !1588
			!RAM_OffscreenHorz	= !15A0
			!RAM_SpritePal		= !15F6

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; init routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
LDA !7FAB10,x			;
AND #$04			; if the extra bit is set...
BNE Init2			; use the other two values for the segment count

LDA #!Segments2			; if the player is on Yoshi, then the Pokey has 5 segments ($C2,x = #$1F = #%00011111)
LDY $187A|!addr			;
BNE StoreSegments		;
LDA #!Segments1			; if the player is not on Yoshi, then the Pokey has 3 segments ($C2,x = #$07 = #%00000111)
BRA StoreSegments		;

Init2:				;
LDA #!Segments4			; if the player is on Yoshi, then the Pokey has 4 segments ($C2,x = #$0F = #%00001111)
LDY $187A|!addr			;
BNE StoreSegments		;
LDA #!Segments3			; if the player is not on Yoshi, then the Pokey...still has 4 segments ($C2,x = #$0F = #%00001111)

StoreSegments:			;
STA !C2,x			;

%SubHorzPos()
TYA				; face the player initially
STA !157C,x			;
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine wrapper
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
PHB
PHK
PLB
JSR PokeyMain

;PHX
LDA !C2,x			; $C2,x has a bit for each segment
LDX #$04			; start X at 04 because 5 segments is the max
LDY #$00			;

PokeyLoopStart:			;
LSR				; shift the sprite state to the right
BCC PokeyBitClear		; if the shifted bit was clear, the carry flag will be clear
INY				; if the shifted bit was set, increment the number of segments (contained in Y)

PokeyBitClear:			;
DEX				;
BPL PokeyLoopStart		;
;PLX

LDX $15E9|!addr

LDA Clipping,y			; set the sprite clipping value depending on how many segments it has
STA !1662,x			;
PLB
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PokeyMain:
LDA !1534,x			; if the sprite is dead...
BNE DeadSegment			; run the routine for that

LDA !14C8,x			;
CMP #$08			; if the sprite is in normal status...
BEQ NormalRt			; run that code
JMP PokeyGFX			; else, just run the GFX routine

DeadSegment:
lda #!dss_id_pokey
%FindAndQueueGFX()    ; find or queue GFX
bcs .gfx_loaded
rts                     ; don't draw gfx if ExGFX isn't ready
.gfx_loaded
JSL $0190B2|!bank		; generic single 16x16 sprite GFX routine

LDY !15EA,x			; load the sprite OAM index back into Y
LDA !C2,x			;
CMP #$01			; if the sprite state is not 00...
LDA.l !dss_tile_buffer+!HeadTile			; use the head tile
BCC StoreDeadTile		;
LDA.l !dss_tile_buffer+!BodyTile			; if the sprite state is 00, use the body tile

StoreDeadTile:			;
STA $0302|!addr,y		;

LDA !14C8,x			;
CMP #$08			; if the sprite is not in normal status...
BNE Return00			; return

JSL $01801A|!bank		; update sprite Y position without gravity
INC !AA,x			;
INC !AA,x			; make the sprite accelerate

LDA #$00
%SubOffScreen()

Return00:			;
RTS				;

NormalRt:
LDA !C2,x			; if there are still sections left...
BNE PokeyAlive			; then the Pokey is still alive

EraseSprite2:			;
STZ !14C8,x			; if not, erase the sprite
RTS				;

PokeyAlive:			;
;CMP #$20			; erase if more than 5 segments? wot
;BCS EraseSprite2		; erase the sprite immediately

LDA $9D				; if sprites are locked...
BEQ .Run			; skip ahead to the GFX routine
JMP SkipToGFX

.Run
%SubOffScreen()

JSL $01A7DC|!bank		; interact with the player

;can't move in player's direction anymore
;INC !1570,x			; increment the sprite frame counter
;LDA !1570,x			;
;AND #$7F			; every 80 frames...
;BNE NoFace			;
;%SubHorzPos()			;
;TYA				;
;STA !157C,x			;

NoFace:				;

;football code
			JSL $01802A|!BankB     		; update sprite position
CODE_038031:
			LDA !RAM_SprObjStatus,x		;\ If no horizontal contact, branch
			AND #$03			; |
			BEQ CODE_03803F			;/
			LDA !RAM_SpriteSpeedX,x		;\ else, invert horizontal speed
			EOR #$FF			; |
			INC A				; |
			STA !RAM_SpriteSpeedX,x		;/
CODE_03803F:
			LDA !RAM_SprObjStatus,x		;\ if sprite not touching ceiling, branch
			AND #$08			; |
			BEQ CODE_038048			;/
			STZ !RAM_SpriteSpeedY,x		; else, set y speed to zero
CODE_038048:
			LDA !RAM_SprObjStatus,x		;\ if sprite not on ground, branch
			AND #$04			; |
			BEQ NoFlipDir			;/
			;LDA !RAM_SpriteDir,x		;\ flip sprite graphics
			;EOR #$01			; |
			;STA !RAM_SpriteDir,x		;/
			JSL $01ACF9|!BankB		;\ use random number generator to
			AND #$03			; | determine new y speed
			TAY				; |
			LDA YSpeeds,y			; |
			STA !RAM_SpriteSpeedY,x		;/
			LDY !15B8,X			;\ change x speed depending on what type of slope sprite is on (?)
			INY #3				; |
			LDA XSpeeds,y			; |
			CLC				; |
			ADC !RAM_SpriteSpeedX,x		;/
			BPL CODE_03807E			; if sprite going to the left, branch
			CMP #!MaxLeftwardSpeed		;\ if sprite x speed slower than #$E0,
			BCS CODE_038084			; |
			LDA #!MaxLeftwardSpeed		; | load #$E0,
			BRA CODE_038084			;/
CODE_03807E:
			CMP #!MaxRightwardSpeed		;\ if sprite x speed slower than #$20,
			BCC CODE_038084			; |
			LDA #!MaxRightwardSpeed		;/ load #$20,
CODE_038084:
			STA !RAM_SpriteSpeedX,X		; and set new sprite x speed (to prevent sprite from going slower than #$20 or #$E0)

NoFlipDir:			;
JSR SpriteInteract		; interact with sprites; check if sections need to be removed

LDY #$00			; start Y at 00

CheckLoop:			;
LDA !C2,x			;
AND PokeyPresentSegment,y	; if a particular bit is set...
BNE EndOfLoop			; then the sprite has that section

LDA !C2,x			;
PHA				;
AND BitTable2,y			; clear the top bit
STA $00				; and save the result
PLA				;
LSR				;
AND BitTable3,y			; I'm honestly not sure what the heck the purpose of this subroutine is.
ORA $00				; It's, like, clearing bits and then setting them again or something...
STA !C2,x			;

EndOfLoop:			;
INY				; increment the bit index
CPY #$04			; if we've reached the 5th index...
BNE CheckLoop			; break the loop

SkipToGFX:
JMP PokeyGFX			; I separated this from the main routine to make things simpler.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; sprite interaction routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SpriteInteract:

LDY #!SprSize-3			; 0A sprites to loop through (why not 0C, SMW?)

SprCheckLoop:
TYA				;
EOR $13				; every other frame depending on whether the
LSR				; contacting sprite has an even or odd index...
BCS EndOfLoop2			; skip interaction

LDA !14C8,y			; check the sprite status of the second sprite
CMP #$0A			; if the second sprite isn't kicked...
BNE EndOfLoop2			; skip interaction

;PHB				; preserve the current data bank
;LDA #$03			; set the data bank to 03
;PHA				; which, of course, is completely pointless,
;PLB				; since these subroutines load all ROM tables in 24-bit mode anyway
PHX				; preserve the Pokey sprite index
TYX				; get the second sprite index into X
JSL $03B6E5|!bank		; get clipping values for the second sprite
PLX				; get the first sprite index back into X
JSL $03B69F|!bank		; get clipping values for the first sprite
JSL $03B72B|!bank		; check for contact between the two
;PLB				;
BCS IsContact			; if the carry flag is set, then the sprites made contact

EndOfLoop2:
DEY				; decrement the sprite index
BPL SprCheckLoop		; if still positive, there are more sprites to check
RTS				;

IsContact:
LDA !1558,x			; if the sprite is sinking in lava (see, this is why this shouldn't be used as a misc. table)...
BNE Return01			; return

LDA !D8,y			; Y position of the contacting sprite
SEC				;
SBC !D8,x			; minus Y position of the Pokey
PHY				;
STY $1695|!addr			; preserve the second sprite index

JSR RemoveSegment		; remove one or more of Pokey's segments
;JSL $82B81C			; odd, this routine could actually have been JSL'd to...I wonder why they didn't use that?

PLY				; pull back the contacting sprite index
JSR SpawnSegment		; the segments flying off Pokey when it gets hit are actually new Pokeys that are already dead

Return01:			;
RTS				;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; segment-removing routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveSegment:			; This subroutine does exactly what you'd expect it to do, in case the header wasn't clear enough.
LDY #$00			; start Y off at 00
CMP #$09			; if the result of the position subtraction operation was less than 09...
BMI ClearBit			; keep the current Y-index
INY				; if the result was 09 or greater, increment the index
CMP #$19			; if the result of the position subtraction operation was between 09 and 18...
BMI ClearBit			; keep the current Y-index
INY				; if the result was 19 or greater, increment the index
CMP #$29			; if the result of the position subtraction operation was between 19 and 28...
BMI ClearBit			; keep the current Y-index
INY				; if the result was 29 or greater, increment the index
CMP #$39			; if the result of the position subtraction operation was between 29 and 38...
BMI ClearBit			; keep the current Y-index
INY				; if the result was 39 or greater, increment the index

ClearBit:			;
if !PokeyFix
  LDA !C2,x			; sprite state (section counter)
  AND PokeySetBit,y		; check if the segmet is actually there
  BNE .NotLower			;
  INY				;
endif

.NotLower
LDA !C2,x
AND PokeyUnsetBit,y		; clear a specific bit, which effectively removes the segment it represents
STA !C2,x			;
STA !151C,X			;

LDA BitTable5,y			; this table is the inverse of the section counter
STA $0D				;

LDA #$0C			;
STA !1540,x			; set...a timer
ASL				;
STA !1558,x			;

Return02:			;
RTS				;

SpawnSegment:
JSL $02A9E4|!bank		; find a free sprite slot for the dead Pokey head
BMI Return02			; return if none are free

LDA #$02			; set the sprite status as dead
STA !14C8,y			; (seriously, how many other spawning routines have you seen that do this?)

PHX				;
LDA !7FAB9E,x			; same sprite number
TYX				;
STA !7FAB9E,x			;
PLX				;

LDA !E4,x			;
STA !E4,y			; new sprite X position = the same as the old one
LDA !14E0,x			;
STA !14E0,y			;

PHX				;
TYX				;
JSL $07F7D2|!bank		; initialize sprite tables
JSL $0187A7|!bank		;

LDX $1695|!addr			; load the index of the kicked sprite into X
LDA !D8,x			;
STA !D8,y			; set the sprite Y position
LDA !14D4,x			; relative to the kicked sprite rather than the Pokey
STA !14D4,y			;

LDA !B6,x			;
STA $00				;
ASL				;
ROR $00				;
LDA $00				;
STA !B6,y			; set the dead sprite X speed
LDA #$E0			;
STA !AA,y			; set its Y speed

PLX				;
LDA !C2,x			; sprite state of the old sprite
AND $0D				; the bits that we set earlier
STA !C2,y			;

LDA #$01			; set the "dead" flag
STA !1534,y			;

LDA #$01			; give 200 points
JSL $02ACE1|!bank		;
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; graphics routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PokeyGFX:

lda #!dss_id_pokey
%FindAndQueueGFX()    ; find or queue GFX
bcs .gfx_loaded
rts                     ; don't draw gfx if ExGFX isn't ready
.gfx_loaded

%GetDrawInfo()

LDA $01				;
CLC				;
ADC #$40			; offset the sprite Y position by 40 pixels
STA $01				;

LDA !C2,x			; sprite state
STA $02				; into *two* bytes of scratch RAM?
STA $07				;

LDA !151C,x			; you thought this table is unused? boy you were very wrong.
STA $04				;

LDY !1540,x			;
LDA Data1,y			;
STA $03				;
STZ $05				;

LDA !15F6,x			;
ORA $64
STA $08				;

LDY !15EA,x			; get OAM slot
PHX				;
LDX #$04			; 5 tiles to draw

GFXLoop:

STX $06				;
LDA $14				;
LSR #3				;
CLC				;
ADC $06				;
AND #$03			;
TAX				;
LDA $07				;
CMP #$01			; if the sprite has only 1 segment left, or we're drawing the bottom segment
BNE Not1Segment			;
LDX #$00			; the X displacement index is 00

Not1Segment:			;
LDA $00				;
CLC				;
ADC XDisp,x			; set the tile X displacement
STA $0300|!addr,y		;

LDX $06				;
LDA $01				;
LSR $02				;
BCC Label00			;
LSR $04				; ...what?
BCS Label01			;
PHA				;
LDA $03				;
STA $05				;
PLA				;

Label01:			;
SEC				;
SBC $05				;
STA $0301|!addr,y		;

Label00:			;
LDA $01				;
SEC				;
SBC #$10			;
STA $01				;

LDA $02				;
LSR				;
LDA.l !dss_tile_buffer+!BodyTile			;
BCS StoreTile			;

LDA.l !dss_tile_buffer+!HeadTile			;

StoreTile:			;
STA $0302|!addr,y		;

;LDA #$05			;uses hardcoded props. but no more!
LDA $08
;ORA $64			;small optimization, don't need to run every time
STA $0303|!addr,y		;

INY #4				;
DEX				;
BPL GFXLoop			;

PLX				;
LDA #$04			;
LDY #$02			;
JSL $01B7B3|!bank		;
RTS				;