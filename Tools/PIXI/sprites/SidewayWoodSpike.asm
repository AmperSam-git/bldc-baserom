;Wooden Spike but it's sideways
;extra bit - clear - facing right, set - facing left
;extra byte 1 - moving out speed. if 0-7F - moves right, 80-FF - moves left. depending on the facing, it'll look like it'll actually move in first
;extra byte 2 - moving in speed (returning to its position). must be between 0-7F
;extra byte 3 - moving out time (moving in won't depend on timer, instead it'll return to its spawn point with set speed)
;extra byte 4 - stay in place time before moving
;extra byte 5 - stay in place time after moving

!GFX_FileNum = $9E		;DSS ExGFX number for this sprite

!BodyTile = $01
!EndTile = $00				;the pointy one

XDisp:
db $00,$10,$20,$30,$40

;i doubt you'll want to edit these (hitbox dimensions for player interaction)
!HitboxWidth = 80
!HitboxHeight = 16

!MoveState = !C2,x
!MoveInSpd = !1504,x
!MoveOutSpd = !1510,x
!FaceDir = !157C,x
!MoveTimer = !1540,x			;common timer, for movement and staying in place
!MoveOutTimer = !1534,x

!OrigPos = !1594,x
!OrigPosHi = !187B,x

!StayInPlaceBeforeMoveTimer = !1570,x	;\
!StayInPlaceAfterMoveTimer = !1602,x	;/manual timers

Print "INIT ",pc
Init:
LDA !extra_byte_1,x			;set up indirect addressing to access extra byte tables
STA $00

LDA !extra_byte_2,x
STA $01

LDA !extra_byte_3,x
STA $02

LDY #$00				;extra byte 1
LDA [$00],y
STA !MoveOutSpd

INY					;extra byte 2
LDA [$00],y
;AND #$7F				;i trust users will use a valid range. please?
STA !MoveInSpd

LDA !MoveOutSpd				;if set to move left first
BMI .NoChange				;no need to invert

LDA !MoveInSpd				;but if moves right first, second moves left
EOR #$FF
INC
STA !MoveInSpd

.NoChange
INY					;extra byte 3
LDA [$00],y
STA !MoveOutTimer

INY					;extra byte 4
LDA [$00],y
STA !StayInPlaceBeforeMoveTimer
STA !MoveTimer				;initialize to wait before moving

INY					;extra byte 5
LDA [$00],y
STA !StayInPlaceAfterMoveTimer

LDA !extra_bits,x
AND #$04
LSR
LSR
STA !FaceDir

LDA !E4,x				;remember its spawn point
STA !OrigPos

LDA !14E0,x
STA !OrigPosHi
RTL

Print "MAIN ",pc
PHB
PHK
PLB
JSR Spike
PLB
RTL

Spike:
JSR DemGrefix

LDA $9D					;don't do shit on freeze flag
BNE .Re
INC
%SubOffScreen()

JSR PlayerCollision

JSL $018022|!bank			;horizontal movement only

LDA !MoveTimer
BNE .Re

LDA !MoveState
BEQ .MoveOut				;state 0 - moving out
DEC
BEQ .Wait				;state 1 - wait before moving in again
;DEC
;BEQ .MoveIn

;state 2 - moving in (returning)
LDA !MoveInSpd
STA !sprite_speed_x,x

JSR ReturningPosCheck			;check if returned to the position (or slightly further)
BCC .Re					;

STZ !MoveState				;wait now

LDA !OrigPos				;snap to its original position in case of overshooting
STA !E4,x

LDA !OrigPosHi				;
STA !14E0,x				;

LDA !StayInPlaceBeforeMoveTimer		;wait a bit
STA !MoveTimer				;

STZ !sprite_speed_x,x			;don't move
STZ !sprite_speed_x_frac,x		;just in case to make it consistent

.Re
RTS

.MoveOut
LDA !MoveOutTimer			;move out for this long
STA !MoveTimer				;

LDA !MoveOutSpd				;move out this fast
STA !sprite_speed_x,x			;

INC !MoveState				;do move out
RTS					;

.Wait
LDA !StayInPlaceAfterMoveTimer		;wait this long
STA !MoveTimer				;

STZ !sprite_speed_x,x			;don't move
STZ !sprite_speed_x_frac,x		;just in case to make it consistent

INC !MoveState				;waiting...
RTS					;

DemGrefix:
lda #!GFX_FileNum        ; find or queue GFX
%FindAndQueueGFX()
bcs .gfx_loaded
rts                      ; don't draw gfx if ExGFX isn't ready
.gfx_loaded
%GetDrawInfo()

STZ $02
LDA !FaceDir				;check which direction we're facing
BNE .OK

LDA #$40				;x-flip
STA $02

.OK
LDA $02					;potentially X-flip
;ORA $64				;need low priority.
ORA !15F6,x				;cfg props
STA $04					;

STZ $03					;which tile is the pointy one? last

LDX #$04				;5 tiles to draw
LDA $02
BEQ .Loop
STX $03					;pointy tile is the first one

.Loop
LDA $00
CLC : ADC XDisp,x
STA $0300|!addr,y

LDA $01
STA $0301|!addr,y

LDA #!BodyTile
CPX $03					;if not pointy tile, no
BNE .StoreBodyTile				;

.StoreEndTile
PHX
LDX.b #!EndTile
lda !dss_tile_buffer,x
PLX
STA $0302|!addr,y
jmp .continueDraw

.StoreBodyTile
PHX
LDX.b #!BodyTile
lda !dss_tile_buffer,x
PLX
STA $0302|!addr,y

.continueDraw
LDA $04
STA $0303|!addr,y

INY #4

DEX
BPL .Loop

LDX $15E9|!addr

LDA #$04				;number of tiles, zero inclusive
LDY #$02				;16x16 size
%FinishOAMWrite()
RTS

ReturningPosCheck:
LDA !OrigPos				;setup position check
STA $00

LDA !OrigPosHi
STA $01

LDA !E4,x
STA $02

LDA !14E0,x
STA $03

LDA !B6,x				;moving left
BMI .ReturningLeft			;means returning position is to the left

;returning right
REP #$20
LDA $02
CMP $00
SEP #$20
BCS .Returned				;current position >= original position = returned to the position

.NotReturned
CLC
RTS

.ReturningLeft
REP #$20
LDA $02
CMP $00
SEP #$20
BEQ .Returned				;current position = original position = returned
BCS .NotReturned			;current position > original position != returned

;less - also returned

.Returned
SEC
RTS

PlayerCollision:
;set up custom collision maybe?
%SetPlayerClippingAlternate()	;get player's hitbox

STZ $08				;no hitbox dispostition at all
STZ $09				;
STZ $0A				;
STZ $0B				;

LDA #!HitboxWidth		;
STA $0C				;
STZ $0D				;

LDA #!HitboxHeight		;
STA $0E				;
STZ $0F				;

%SetSpriteClippingAlternate()	;check collision
%CheckForContactAlternate()
BCC .Return			;no contact = return

%SubVertPos()			;
LDA $0F				;
CMP #$E6			;if player below sprite, maybe hurt, idk
BPL .MaybeHurt			;

LDA $7D				; \ if mario speed is upward, return
BMI .Return			; /

LDA #$01			; \ set "on sprite" flag
STA $1471|!addr			; /

STZ $7D				;zero player gravity

;need yoshi check...

LDA #$E1			; \place above spike
LDY $187A|!addr
BEQ .NoOffset

LDA #$D1

.NoOffset
CLC                     	;  |
ADC !D8,x               	;  |
STA $96                 	;  |
LDA !14D4,x             	;  |
ADC #$FF                	;  |
STA $97                 	; /

.Return
RTS

.MaybeHurt
LDA $72				;check if grounded
BEQ .Hurt			;probably makes sense. if the player is big and the spike is 1 tile above player's body, it won't hurt for w/e reason, visually piercing player's head which is silly

;do we need yoshi check even?
LDA $187A|!addr			;no need to offset shit
;BEQ .OnYoshi
BEQ .NotYoshi

LDA $96
CLC : ADC #$0F			;position is actually higher
BRA .MoreCalc

.NotYoshi
LDA $73				;when ducking, always use small image (even when already small cuz doesnt matter)
BNE .SmallPlayerPosDisp

LDA $19
BNE .Set

.SmallPlayerPosDisp
LDA $96
CLC : ADC #$09			;re-calculate because of player's small image not matching actual pos

.MoreCalc
SEC : SBC !D8,x
STA $0F

.Set
.OnYoshi
LDA $0F
CMP #$0E			;was 12 before
BCC .HitBottom

.Hurt
;lose yoshi?
LDA $1490|!addr			;don't care if star powered
BNE .Return

LDA $187A|!addr			;lose yoshi instead if riding him
BNE .LoseYoshi

JSL $00F5B7|!BankB		;that'll teach em to touch pointy objects!
RTS

.LoseYoshi
%LoseYoshi()
RTS

.HitBottom
LDA $7D				;if going down, no hit and no sound
BPL .NoHit

LDA #$20			;send downward
STA $7D				;

LDA #$01			;play hit block snd
STA $1DF9|!addr			;

;place below the sprite! (or kinda below sprite, in reality just push the player down)

LDA $96
CLC : ADC #$02			;a couple of pixels down
STA $96

LDA $97
ADC #$00
STA $97

.NoHit
RTS