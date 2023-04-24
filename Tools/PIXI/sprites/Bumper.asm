;Bumper by Blind Devil (revision 2018-07-15)
;When the player touches this sprite, they're bumped away.

;(Many thanks to imamelia for the line guided Grinder disassembly!)

;Extra byte 1 values:
;$00 = stationary.
;$01 = line-guided, with slow speed.
;$02 = line-guided, with normal speed (like platforms).
;$03 = line-guided, with fast speed (like Grinders).
;$04 = line-guided, with very fast speed.
;anything else = stationary (falls on line guide).

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; defines and tables
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!GFX_FileNum = $A1      ;DSS EXGFX number for this sprite

if !EXLEVEL
	!LayerLookUp		= $0BF6|!Base2			; 256 bytes of free RAM. Must be on shadow RAM.
	!L1_Lookup_Lo	= !LayerLookUp+96+96		; 32 bytes
	!L2_Lookup_Lo	= !LayerLookUp+96+96+16		; 16 bytes (shared)
	!L1_Lookup_Hi	= !LayerLookUp+96+96+32		; 32 bytes
	!L2_Lookup_Hi	= !LayerLookUp+96+96+32+16	; 16 bytes (shared)
endif

!Tilemap = $00		;self-explanatory

!OfflineSpeed = $10	;main speed index for sprite going off the line guide

!BumpTime = $30		;amount of frames to activate animation after it's touched

!BumpSpdX = $38		;X speed to set for player when bounced
!BumpSpdY = $38		;Y speed to set for player when bounced

!BumpSFX = $08		;SFX to use for bumped player
!BumpPort = $1DFC	;port used for above SFX

;don't change this (or do it if you absolutely know what you're doing)
if read1($01D99C) == $5C
!LineGuideFixPatch = 1
else
!LineGuideFixPatch = 0
endif

XDisp:
db $F0,$00,$F0,$00	;normal
db $F1,$FF,$F1,$FF	;bumped

YDisp:
db $F0,$F0,$00,$00	;normal
db $F1,$F1,$FF,$FF	;bumped

TileProp:
db $30,$70,$B0,$F0

XOffsetLo:
db $FC,$04,$FC,$04

XOffsetHi:
db $FF,$00,$FF,$00

YOffsetLo:
db $FC,$FC,$04,$04

YOffsetHi:
db $FF,$FF,$00,$00

if !LineGuideFixPatch == 0
BitTable:
db $80,$40,$20,$10,$08,$04,$02,$01
endif

Data1:
db $15,$15,$15,$15,$0C,$10,$10,$10
db $10,$0C,$0C,$10,$10,$10,$10,$0C
db $15,$15,$10,$10,$10,$10,$10,$10
db $10,$10,$10,$10,$10,$10,$15,$15

Data2:
db $00,$00,$00,$00,$00,$00,$01,$02
db $00,$00,$00,$00,$02,$01,$00,$00
db $00,$00,$01,$02,$01,$02,$00,$00
db $00,$00,$02,$02,$00,$00,$00,$00

;Speed tables and autocalculated define values below.
;NOTE: THESE ARE THE SPEEDS FOR WHEN THE SPRITE LEAVES A LINE GUIDE.

!MainXSpd = !OfflineSpeed
!MainYSpd = !OfflineSpeed
!NegMainXSpd = $100-!MainXSpd
!NegMainYSpd = $100-!MainYSpd

!12XSpd = !MainXSpd/2
!12YSpd = !MainYSpd/2
!Neg12XSpd = $100-!12XSpd
!Neg12YSpd = $100-!12YSpd

!14XSpd = !MainXSpd/4
!14YSpd = !MainYSpd/4
!Neg14XSpd = $100-!14XSpd
!Neg14YSpd = $100-!14YSpd

!34XSpd = !12XSpd+!14XSpd
!34YSpd = !12YSpd+!14YSpd
!Neg34XSpd = $100-!34XSpd
!Neg34YSpd = $100-!34YSpd

SpeedTableX1:
db !MainXSpd,$00,!MainXSpd,$00,!34XSpd,!MainXSpd,!14XSpd,$00
db !MainXSpd,!34XSpd,!34XSpd,!MainXSpd,!14XSpd,$00,!MainXSpd,!34XSpd
db !MainXSpd,!MainXSpd,!12XSpd,!12XSpd,!12XSpd,!12XSpd,!MainXSpd,!MainXSpd
db !MainXSpd,!MainXSpd,$00,$00,!MainXSpd,!MainXSpd,!MainXSpd,!MainXSpd
db $00,!NegMainXSpd,$00,!NegMainXSpd,!Neg34XSpd,!NegMainXSpd,$00,!Neg14XSpd
db !NegMainXSpd,!Neg34XSpd,!Neg34XSpd,!NegMainXSpd,$00,!Neg14XSpd,!NegMainXSpd,!Neg34XSpd
db !NegMainXSpd,!NegMainXSpd,!Neg12XSpd,!Neg12XSpd,!Neg12XSpd,!Neg12XSpd,!NegMainXSpd,!NegMainXSpd
db !NegMainXSpd,!NegMainXSpd,$00,$00,!NegMainXSpd,!NegMainXSpd,!NegMainXSpd,!NegMainXSpd

SpeedTableY1:
db $00,!MainYSpd,$00,!NegMainYSpd,!Neg34YSpd,!Neg14YSpd,!NegMainYSpd,!MainYSpd
db !14YSpd,!34YSpd,!34YSpd,$00,!MainYSpd,!NegMainYSpd,!Neg14YSpd,!Neg34YSpd
db !NegMainYSpd,!MainYSpd,!NegMainYSpd,!MainYSpd,!NegMainYSpd,!MainYSpd,!Neg12YSpd,!Neg12YSpd
db !12YSpd,!12YSpd,!MainYSpd,!MainYSpd,$00,$00,!NegMainYSpd,!MainYSpd
db !MainYSpd,$00,!NegMainYSpd,!NegMainYSpd,!34YSpd,!14YSpd,!MainYSpd,!NegMainYSpd
db $00,!Neg34YSpd,!Neg34YSpd,!Neg14YSpd,!NegMainYSpd,!MainYSpd,$00,!34YSpd
db !MainYSpd,!NegMainYSpd,!MainYSpd,$00,!MainYSpd,!NegMainYSpd,!12YSpd,!12YSpd
db !Neg12YSpd,!Neg12YSpd,!NegMainYSpd,!NegMainYSpd,$00,$00,!MainYSpd,!NegMainYSpd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; init routine wrapper
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
JSR LineGrinderInit
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; init routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LineGrinderInit:
LDA !7FAB40,x		;load extra byte 1
CMP #$05		;compare to value
BCC +			;if lower, skip ahead.

INC !1626,x		;set flag to make sprite stationary on line guides.

+
LDA !E4,x
AND #$10		; sprite X position / $10
LSR #4			;
STA !157C,x		; into sprite direction

LDA #$02
STA !1540,x
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine wrapper
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
PHB
PHK
PLB
JSR LineGrinderMain
PLB
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LineGrinderMain:
JSR GrinderGFX		;draw the sprite

LDA !154C,x		;load timer to disable interaction with player
ORA $13F9|!Base2	;OR with player is behind layer 1 flag
BNE +			;if non-zero, don't process interaction.
JSL $01A7DC|!BankB	; interact with the player
BCC +			;if carry is not set, don't process interaction.

LDA #!BumpSpdX		;load bumping X speed
PHA			;preserve into stack

%SubHorzPos()
LDA $0E
CLC
ADC #$08		;center X offset
BMI .isleft

PLA			;restore speed value
BRA .storeX		;branch to store it

.isleft
PLA			;restore speed value
EOR #$FF		;invert all bits
INC			;increment by one - get correct negative value

.storeX
STA $7B			;store to player's X speed.

LDA #!BumpSpdY		;load bumping Y speed
PHA			;preserve into stack

%SubVertPos()
LDA $0F
CLC
ADC #$18		;center Y offset
BMI .isabove

PLA			;restore speed value
BRA .storeY		;branch to store it

.isabove
PLA			;restore speed value
EOR #$FF		;invert all bits
INC			;increment by one - get correct negative value

.storeY
STA $7D			;store to player's Y speed.

LDA #!BumpTime		;load amount of frames
STA !15AC,x		;store to bump animation timer.

LDA #$04		;load amount of frames
STA !154C,x		;store to disable interaction with player.

LDA #!BumpSFX		;load SFX value
STA !BumpPort|!Base2	;store to address to play it.

+
; progress directly to the line-guided sprite handler routine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; main line-guided sprite routine ($01D74D)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LineGuideHandlerMainRt:
LDA #$01
%SubOffScreen()

LDA !7FAB40,x	;load extra byte 1
BEQ Return00	;if zero, return.

LDA !1540,x	; if the move timer is set...
BNE RunStatePtr	; skip the next check
LDA $9D		; if sprites are locked...
ORA !1626,x	; or the stationary flag is set...
BNE Return00	; return

RunStatePtr:	;

LDA !C2,x		; sprite state
JSL $0086DF|!BankB	; 16-bit pointer routine

dw State00
dw State01
dw State02

Return00:
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; code for sprite state 00
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

State00:

LDY #$03		;

TileCheckLoop:	;

STY $1695|!Base2	;

LDA !E4,x	;
CLC		;
ADC XOffsetLo,y	;
STA $02		; set up an X position variable, 4 pixels left or right
LDA !14E0,x	;
ADC XOffsetHi,y	;
STA $03		;

LDA !D8,x	;
CLC		;
ADC YOffsetLo,y	;
STA $00		; set up a Y position variable, 4 pixels up or down
LDA !14D4,x	;
ADC YOffsetHi,y	;
STA $01		;

LDA !1540,x	; if the move timer is set...
BNE GoToPosSet	; skip the next part

LDA $00		;
AND #$F0	; sprite X position with the individual pixel nybble clear
STA $04		;
LDA !D8,x	;
AND #$F0	;
CMP $04		; if the sprite Y position is not the same as the X position...
BNE GoToPosSet	; go directly to the position setup routine

LDA $02		;
AND #$F0	; sprite Y position with the individual pixel nybble clear
STA $05		;
LDA !E4,x	;
AND #$F0	;
CMP $05		; if the sprite X position is not the same as the Y position...
BEQ DecAndLoop	; skip the position setup routine entirely and go to the end of the loop

GoToPosSet:

JSR PositionSetup	;
BNE AltIndex	;

LDA $1693|!Base2	; check the low byte of the "acts like" setting of the Map16 tile that the sprite is touching
CMP #$94		;
BEQ OnOffCheck2	; if it is 94 or 95...
CMP #$95		; then it is an on/off line guide slope
BNE Continue1	;

LDA $14AF|!Base2	;
BEQ DecAndLoop	;
BNE Continue1	;

OnOffCheck2:	;

LDA $14AF|!Base2	;
BNE DecAndLoop	;    

Continue1:	;

LDA $1693|!Base2	;
CMP #$76		; if the tile number is less than 76...
BCC DecAndLoop	;
CMP #$9A	; or greater than 99...
BCC LineGuideTiles	; then it is not a line guide tile

DecAndLoop:

LDY $1695|!Base2	;
DEY		;
BPL TileCheckLoop	; loop 4 times

LDA !C2,x	; if we're running this code in sprite state 02...
CMP #$02		;
BEQ Return01	; terminate the code
LDA #$02		; if not,
STA !C2,x	; set the sprite state to 02

LDY !160E,x	; speed index
LDA !157C,x	; depending on sprite direction
BEQ NoAddToIndex	; if the sprite is moving left...
TYA		;
CLC		;
ADC #$20	; add $20 to the speed index
TAY		;
NoAddToIndex:	;
LDA SpeedTableY1,y;
BPL $01		; if the value is negative...
ASL		; left-shift it
PHY		;
ASL		; left-shift it once more...
STA !AA,x	; and store it to the sprite Y speed
PLY		;
LDA SpeedTableX1,y;
ASL		;
STA !B6,x		; set the sprite X speed
LDA #$10		;
STA !1540,x	; set the time to pause

Return01:		;
RTS		;

LineGuideTiles:

PHA		;
SEC		;
SBC #$76		; subtract 76 from the tile number so that the index begins at 00
TAY		;
PLA		; but we still want the actual tile number in A
CMP #$96		; if the tile is a line-guide end...
BCC NoAltIndex	; 

AltIndex:

LDY !160E,x	; then do this
BRA SkipChangePos	;

NoAltIndex:	;

LDA !D8,x	;
STA $08		; back up sprite position
LDA !14D4,x	;
STA $09		;
LDA !E4,x	;
STA $0A		;
LDA !14E0,x	;
STA $0B		;

LDA $00		; and then set the sprite position
STA !D8,x	;
LDA $01		; to the offset values from before
STA !14D4,x	;
LDA $02		;
STA !E4,x		;
LDA $03		;
STA !14E0,x	;

SkipChangePos:

PHB		; preserve the data bank
LDA.b #$07|(!BankB>>16)		; set the data bank to 07 (or 87)
PHA		;
PLB		;
LDA $FBF3,y	; $07FBF3-$07FC12: low byte of 16-bit pointer to line guide behaviors
STA !151C,x	;
LDA $FC13,y	; $07FC13-$07FC32: high byte of 16-bit pointer to line guide behaviors
STA !1528,x	;
PLB		;

LDA Data1,y	;
STA !1570,x	; not sure what this does

STZ !1534,x	;
TYA		; save the tile index
STA !160E,x	;

LDA !1540,x	; if the wait timer is set...
BNE SetState01	; change the sprite state to 01

STZ !157C,x	; set the sprite direction to right
LDA Data2,y	;
BEQ MoreSetups	;
TAY		;
LDA !D8,x	;
CPY #$01		;
BNE NoEORPixels	;
EOR #$0F		;
NoEORPixels:	;

BRA SkipLoadX	;

MoreSetups:	;

LDA !E4,x	;

SkipLoadX:

AND #$0F	;
CMP #$0A	;
BCC NoLeftDir	;
LDA !C2,x	;
CMP #$02		;
BEQ NoLeftDir	;
INC !157C,x	;
NoLeftDir:	;

LDA !D8,x	;
STA $0C		;
LDA !E4,x	;
STA $0D		;

JSR State01	;

LDA $0C		;
SEC		;
SBC !D8,x	;
CLC		;
ADC #$08	;
CMP #$10		;
BCS RestorePos2	;

LDA $0D		;
SEC		;
SBC !E4,x		;
CLC		;
ADC #$08	;
CMP #$10		;
BCS RestorePos2	;

SetState01:	;

LDA #$01		;
STA !C2,x	;
RTS		;

RestorePos2:

LDA $08		;
STA !D8,x	; set the sprite position
LDA $09		; to the values we stored before
STA !14D4,x	;
LDA $0A		;
STA !E4,x		;
LDA $0B		;
STA !14E0,x	;  

JMP DecAndLoop

PositionSetup:	; Some Map16-checking stuff.  I'm not even going to bother trying to comment this.
    LDA $00                     ;$01D94D    |\ 
    AND.b #$F0                  ;$01D94F    ||
    STA $06                     ;$01D951    ||
    LDA $02                     ;$01D953    ||
    LSR                         ;$01D955    || First push: $0X
    LSR                         ;$01D956    || Second push: $YX
    LSR                         ;$01D957    || (where Y/X are the tile's position)
    LSR                         ;$01D958    ||
    PHA                         ;$01D959    ||
    ORA $06                     ;$01D95A    ||
    PHA                         ;$01D95C    |/
    LDA $5B                     ;$01D95D    |
    AND.b #$01                  ;$01D95F    |
	
    BEQ .horizontal             ;$01D961    |
    PLA                         ;$01D963    |\ 
    LDX $01                     ;$01D964    ||
    CLC                         ;$01D966    ||
    ADC.l $00BA80|!BankB,X      ;$01D967    ||
    STA $05                     ;$01D96B    || Get tile pointer (vertical level).
    LDA.l $00BABC|!BankB,X      ;$01D96D    ||
    ADC $03                     ;$01D971    ||
    STA $06                     ;$01D973    ||
    BRA .getmap16               ;$01D975    |/
.horizontal                     ;           |
    PLA                         ;$01D977    |\ 
    LDX $03                     ;$01D978    ||
    CLC                         ;$01D97A    ||
if !EXLEVEL
	ADC.L !L1_Lookup_Lo,x
else
    ADC.l $00BA60|!BankB,X      ;$01D97B    || Get tile pointer (horizontal level).
endif
    STA $05                     ;$01D97F    ||
if !EXLEVEL
	LDA.L !L1_Lookup_Hi,x
else
    LDA.l $00BA9C|!BankB,X      ;$01D981    ||
endif
    ADC $01                     ;$01D985    ||
    STA $06                     ;$01D987    |/
.getmap16                       ;           |
if !SA1
	LDA #$40		            ; bank byte of pointer to tile low byte = $7E
else
	LDA #$7E		            ; bank byte of pointer to tile low byte = $7E
endif
    STA $07                     ;$01D98B    ||
    LDX.w $15E9|!Base2          ;$01D98D    ||
    LDA [$05]                   ;$01D990    ||
    STA.w $1693|!Base2          ;$01D992    ||
    INC $07                     ;$01D995    ||
    LDA [$05]                   ;$01D997    || Get tile number in $1693, high byte in A?
    PLY                         ;$01D999    ||  Seems to only work in certain X positions...?
    STY $05                     ;$01D99A    ||
if !LineGuideFixPatch == 0
	PHA		;
	LDA $05		;
	AND #$07	;
	TAY		;
	PLA		;
	AND BitTable,y	; $018000
else
-
	XBA
	LDA $1693|!Base2
	REP #$30
	ASL
	ADC $06F624|!BankB
	STA $0D
	SEP #$20
	LDA $06F626|!BankB
	STA $0F
	REP #$20
	LDA [$0D]
	SEP #$30
	STA $1693|!Base2
	XBA
	CMP #$02
	BCS -
	CMP #$00
endif
    RTS                         ;$01D9A6    |
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; code for sprite state 01
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

State01:

LDA $9D		;
BNE Return02	; return if sprites are locked
LDA !157C,x	;
BNE State01Left	; run a slightly different routine if the sprite is facing left

State01Right:

LDY !1534,x	;

JSR MoveSprPos

LDA !7FAB40,x		;load extra byte 1
CMP #$01		;compare to value
BEQ .slowchk1		;if equal, branch.
CMP #$02		;compare to value
BEQ .medchk1		;if equal, branch.
CMP #$03		;compare to value
BEQ .fastchk1		;if equal, branch.
CMP #$04		;compare to value
BNE SkipFrameChk1	;if not equal, branch.

INC !1534,x
BRA .medchk1

.fastchk1
INC !1534,x

.slowchk1
LDA $13
LSR
BCC SkipFrameChk1

.medchk1
INC !1534,x

SkipFrameChk1:
LDA !1534,x	;
CMP !1570,x	; if the first counter equals the second...
BCC Return02	;
STZ !C2,x	; reset the sprite state

Return02:
RTS

State01Left:

LDY !1570,x
DEY

JSR MoveSprPos

LDA !7FAB40,x		;load extra byte 1
CMP #$01		;compare to value
BEQ .slowchk2		;if equal, branch.
CMP #$02		;compare to value
BEQ .medchk2		;if equal, branch.
CMP #$03		;compare to value
BEQ .fastchk2		;if equal, branch.
CMP #$04		;compare to value
BNE SetState00		;if not equal, branch.

DEC !1570,x
BEQ SetState00
DEC !1570,x
BEQ SetState00
RTS

.fastchk2
DEC !1570,x
BEQ SetState00

.slowchk2
LDA $13
LSR
BCC Return02

.medchk2
DEC !1570,x
BNE Return02

SetState00:
STZ !C2,x	;
RTS		;

MoveSprPos:	;

PHB		;
LDA.b #$07|(!BankB>>16)		; once again, the data bank should be 07/87
PHA		;
PLB		;
LDA !151C,x	; low byte of pointer
STA $04		;
LDA !1528,x	; high byte of pointer
STA $05		;

LDA ($04),y	;
AND #$0F	; low byte of the pointed-to address: amount to move the sprite on the X-axis
STA $06		;
LDA ($04),y	;
PLB		;
LSR #4		;
STA $07		;

LDA !D8,x	;
AND #$F0	;
CLC		;
ADC $07		; change the sprite's Y position
STA !D8,x	;

LDA !E4,x	;
AND #$F0	;
CLC		;
ADC $06		; change the sprite's X position
STA !E4,x		;

RTS		;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; code for sprite state 02
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

State02:

LDA $9D		; if spites are locked...
BNE Return03	; return

JSL $01802A|!BankB	; update sprite position

LDA !1540,x	; if the wait timer is set...
BNE Return03	;
LDA !AA,x	;
CMP #$20		; or the sprite speed is less than 20 (actually, between A0 and 1F)...
BMI Return03	;

JSR State00	; return

Return03:		;
RTS		;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; graphics routine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrinderGFX:
    lda #!GFX_FileNum
    %FindAndQueueGFX()
    bcs .gfx_loaded
    rts
.gfx_loaded

%GetDrawInfo()

LDA !15F6,x		;load palette/gfx page from CFG
STA $02			;store to scratch RAM.

STZ $03			;reset scratch RAM

LDA !15AC,x		;load sprite timer
BEQ +			;if zero, skip ahead.

LDA $14			;load effective frame counter
LSR			;divide by 2
AND #$01		;preserve bit 0
ASL #2			;multiply by 2 twice
STA $03			;store to scratch RAM.

+
PHX			; preserve the sprite index
LDX #$03		; 4 tiles to draw

GFXLoop:
PHX
TXA
CLC
ADC $03
TAX

LDA $00			;
CLC			;
ADC XDisp,x		; set the X displacement of the tile
STA $0300|!Base2,y	;

LDA $01			;
CLC			;
ADC YDisp,x		; set the Y displacement of the tile
STA $0301|!Base2,y	;

LDA.l !dss_tile_buffer+!Tilemap
STA $0302|!Base2,y

PLX
LDA $02
ORA TileProp,x		;
STA $0303|!Base2,y	; set the tile properties

INY #4		; increment the OAM index
DEX		; decrement the tilemap index
BPL GFXLoop

PLX			; sprite index -> X
LDY #$02		; all tiles were 16x16
LDA #$03		; and 4 tiles were drawn
JSL $01B7B3|!BankB	;
RTS