;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  A sprite (DO NOT INSERT AS SHOOTER) that spawns chains of block snakes, which
;;  will always follow the same set path as determined by your block placement.
;;     by leod
;;
;;  EXTRA BIT OFF = Continuously spawns Snakes
;;  EXTRA BIT OM  = Burst-spawns a set number of Snakes, then stops forever
;;                  This variant is best to use with non-despawning snakes (see defined below),
;;                  since not all slots can be filled up
;;
;;
;;
;;
;;  You can edit this sprite's cfg to check "Process when off-screen" if you want it to
;;  continuously shoot throughout the level
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define_sprite_table("00E4",$00E4,$322C)	; sadly, these defines are needed (Y-indexing, meh.)
%define_sprite_table("00D8",$00D8,$3216)	;

!SpriteNumber = $01     ;what sprite number did you insert the bettersnake.cfg as?

!Cooldown = $6F         ;how long to wait between spawning each snake part
                        ;don't use "flat" values like 10, 20, 30 etc.
                        ;use these odd values like 0F, 1F, 2F instead

!InitDir = $01          ;which direction should the snakes fly initially?
                          ;00 = up
                          ;01 = right
                          ;02 = down
                          ;03 = left

!InitSpeed = $01        ;which speed should the snakes fly at initially?
                          ;00 = slow
                          ;01 = normal
                          ;02 = fast

!InitFlip = $00         ;what type of snake to spawn first?
                          ;00 = creating snake
                          ;01 =   eating snake

!Offscreen1 = $A2       ;decides whether the sprites spawned by the normal variant should process
                        ;while off-screen
                          ;A6 = process while off-screen
                          ;A2 = don't
                        ;setting them to be processed off-screen might cause all your sprite slots
                        ;to get filled up quickly, which might despawn other sprites in the level
                        ;it's fine to use this in the one-shot burst variant
                        ;HOWEVER, setting them not to can lead to odd issues with a creating snake
                        ;despawning while leaving its eating partner alive, resulting in pointless
                        ;flying blocks that might cause cut-off, so don't make these too long
                        ;or put failsafe terminator blocks in a few spots, so stray snakes can
                        ;be ended gracefully (creating snakes ignore eating terminators and vice versa)



!Offscreen2 = $A6       ;same but for the burst variant

!MaxSpawns = $06        ;how many snakes to spawn in the burst variant


;don't change these defines.
!FlipBit = !1534      ;flips every time a snake is spawned, to create the alternating types

!Timer = !154C        ;timer to wait between shots

!Eating = !160E       ;depending on extra bit, 0 = creating, 1 = eating

!State = !1594        ;0 = don't bother checking for blocks; 1 = check for blocks and spawn

!Direction = !187B    ;sprite direction, directions are as follows:
                        ;0 sprite moves up
                        ;1 sprite moves right
                        ;2 sprite moves down
                        ;3 sprite moves left
                        ;4 sprite does not move

!Speed = !1602        ;sprite speed

!Spawns = !C2         ;counter for how many sprites have been spawned

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite INIT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
LDA #!Cooldown
STA !Timer,x

LDA #!InitFlip
STA !FlipBit,x

STZ !Spawns,x
RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite MAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
PHB                     ; \
PHK                     ;  | The same old
PLB                     ; /
JSR MainCode            ;  Jump to sprite code
PLB                     ; Yep
RTL                     ; Return1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite main code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  Return11:
RTS

  MainCode:
LDA $9D             ;if sprites are locked, Return1
BNE Return11

LDY #$06
%SubOffScreen()	;handle off screen situation

STZ !AA,x
STZ !B6,x

JSL $01801A         ;update x
JSL $018022         ;update y



LDA !7FAB10,x        ; check for extra bit
AND #$04             ; (bit 2 -> %100 -> $4)
BEQ .NoExtraIsSet     ; if not set, skip the following

LDA !Spawns,x
CMP #!MaxSpawns
BEQ NoSpawn

.NoExtraIsSet
LDA !Timer,x
BNE NoSpawn

LDA #!Cooldown
STA !Timer,x

JSR SpawnSnake

NoSpawn:
RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; spawning the snakes code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  SpawnSnake:
PHX             ;preserve X

LDX #!SprSize-1        ;#!SprSize times to loop
-
LDA !14C8,x     ;if any sprite state is #$00
BEQ .freeslot   ;its free
DEX
BPL -

BRA .NoEmpty

.freeslot

LDA #!SpriteNumber    ;set snake's speed to desired speed
STA !7FAB9E,x

JSL $07F7D2           ;reset sprite properties
JSL $0187A7

LDA !7FAB10,x
ORA #$08              ;mark the sprite as custom
STA !7FAB10,x

LDA #$08              ;sprite state 8, deliberately no init
STA !14C8,x


LDA #!InitSpeed       ;set snake's speed to desired speed
STA !Speed,x

LDA #!InitDir         ;move snake in direction immediately
STA !Direction,x

LDA #$01              ;make the snake be active immediately
STA !State,x

TXY
LDX $15E9|!Base2

LDA !FlipBit,x
STA !Eating,y
EOR #$01
STA !FlipBit,x

LDA !00E4,x
STA !00E4,y	      ;x lo
LDA !14E0,x
STA !14E0,y	      ;x hi
LDA !00D8,x
STA !00D8,y	      ;y lo
LDA !14D4,x
STA !14D4,y       ;y hi

INC !Spawns,x


LDA !7FAB10,x        ; check for extra bit
AND #$04             ; (bit 2 -> %100 -> $4)
BNE .ExtraIsSet    ; if not set, skip the following
LDA #!Offscreen1     ;edit the tweaker byte about offscreen processing
STA !167A,y
BRA .NoEmpty

.ExtraIsSet
LDA #!Offscreen2     ;edit the tweaker byte about offscreen processing
STA !167A,y

.NoEmpty
PLX
RTS