!GFX_FileNum = $94		;EXGFX number for this sprite

!Tile = $00

!StillHurtAfterbump = 1				;original SMB2 sprite still hurts after hitting a wall, if you don't want that set to 0

;easy props forever (only edit !Prop)
!Palette8 = %00000000
!Palette9 = %00000010
!PaletteA = %00000100
!PaletteB = %00000110
!PaletteC = %00001000
!PaletteD = %00001010
!PaletteE = %00001100
!PaletteF = %00001110

!SP1SP2 = %00000000
!SP3SP4 = %00000001

!Prop = !Palette9|!SP3SP4

;don't edit
!HitSmthFlag = $1765|!addr			;when the ball hits an object it falls down with slight backward speed

Print "MAIN ",pc
LDA $9D
BNE .GFX

LDA !HitSmthFlag,x
BNE .AlmostGFXWSpeed

.Normal
LDA #$02
%ExtendedSpeed()			;only x-speed

JSR ObjInteraction
BCC .AlmostGFX

INC !HitSmthFlag,x

STZ !extended_y_speed,x			;no y-speed on initial hit

;when hit first, it should move down 2 pixels (just like in SMB2)
LDA !extended_y_low,x
CLC : ADC #$02
STA !extended_y_low,x

LDA !extended_y_high,x
ADC #$00
STA !extended_y_high,x

;slow down
LDA !extended_x_speed,x
EOR #$FF
INC
STA !extended_x_speed,x

LDA !extended_x_speed,x			;straight from SMB2 (or at least SMAS version, it should be identical)
;STA $00
ASL
ROR !extended_x_speed,x

LDA !extended_x_speed,x			;straight from SMB2 (or at least SMAS version, it should be identical)
;STA $00
ASL
ROR !extended_x_speed,x			;yes, repeated twice

.AlmostGFXWSpeed
LDA #$01
%ExtendedSpeed()			;x+y with NO grabity (we apply custom gravity)

LDA !extended_y_speed,x			;gravity from SMB2
CMP #$3E
BPL .AlmostGFX
INC !extended_y_speed,x
INC !extended_y_speed,x

.AlmostGFX
;%ExtendedHurt()
if not(!StillHurtAfterbump)
  LDA !HitSmthFlag,x
  BNE .GFX
endif

JSR PlayerCollision

.GFX
;basic
	lda #!GFX_FileNum        ; find or queue GFX
	%FindAndQueueGFX()
	bcs .gfx_loaded
	rts                      ; don't draw gfx if ExGFX isn't ready	
.gfx_loaded
%ExtendedGetDrawInfo()	;

LDA $01			;
STA $0200|!Base2,y	;

LDA $02			;
STA $0201|!Base2,y	;

PHX
LDX #!Tile
lda !dss_tile_buffer,x
PLX
STA $0202|!Base2,y	;

PHY
LDY #!Prop|$30
LDA !HitSmthFlag,x
BEQ .NoFlip

LDY #!Prop|$80|$30		;now with vertical flip and highest priority

.NoFlip
TYA				;
ORA $64				;
PLY
STA $0203|!Base2,y		;OAM prop

TYA				;
LSR #2				;
TAX				;
LDA #$00			;8x8 size
STA $0420|!Base2,x		;tile size - checkmark

LDX $15E9|!addr
RTL

ObjInteraction:
PHK				;I still don't trust %ExtendedBlockInteraction
PEA.w .Re-1
PEA.w $02A772|!BankB-1
JML $02A56E|!BankB

.Re
RTS				;

;%ExtendedHurtMario bad
PlayerCollision:
JSR GetExClipping

JSL $03B664|!BankB		;get mario's clipping

JSL $03B72B|!BankB		;
BCC .DiffRe			;

PHB
LDA.b #$02			;	
PHA
PLB
PHK
PEA.w .return-1
PEA.w $B889-1
JML $02A469|!BankB
;hurt mario

.return
PLB

.DiffRe
RTS				;

GetExClipping:
LDA $171F|!Base2,x		;Get X position
;SEC				;Calculate hitbox
;SBC #$02			;
STA $04				;

LDA $1733|!Base2,x		;
;SBC #$00			;Take care of high byte
STA $0A				;

LDA #$06			;width
STA $06				;

LDA $1715|!Base2,x		;Y pos
CLC				;
ADC #$02			;
STA $05				;

LDA $1729|!Base2,x		;
ADC #$00			;
STA $0B				;

LDA #$06			;length
STA $07				;
RTS				;
