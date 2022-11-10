;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Pot Sprite
;; by wiiqwertyuiop
;;
;; This sprite will break if you throw it at a wall or on the ground at a certain speed.
;;
;; Credit not required, but it is appreciated! :D
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!GFX_FileNum = $88		;EXGFX number for this sprite

!PushingSpeed = $10         ; The speed at which the player pushes the sprite
!GrabButton = $40           ; Button to press to pick sprite up. Check $7E0015 in the RAM map for more information.

!Tile = $00                 ; Sprite tile to use for the pot

!SmashSFX = $07             ; Sound effect to play when the pot breaks
!SmashBank = $1DFC

print "INIT ",pc
    LDA #$09            ;\ sprite status = stationary/carryable
    STA !14C8,x         ;/

    STZ !C2,x               ;\ if not clear everything
    STZ !1510,x             ;|
    STZ !1528,X             ;|
    STZ !1504,x             ;|
    STZ $15                 ;/
    RTL

print "MAIN ",pc
    PHB : PHK : PLB
    JSR Random                  ;  Get a random number to use for later
    JSR SpriteCode              ;  Jump to sprite code
    LDA !C2,x                   ; \
    BNE +                       ;  | Check if we are carying the sprite
        JSL $01B44F|!BankB      ;  | if so don't make it solid
+   PLB                         ; /
    RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite not being carried
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SpriteCode:
    JSR Graphics

    LDA !1510,x             ;\ Keep running the carried code if we have been picked up already
    BNE Carried             ;/

    LDA !14C8,x             ;\
    CMP #$0B                ;| If we are being carried go to the next part of the code
    BEQ Carried             ;/

    JSL $01A7DC|!BankB      ;\ Are we touching Mario?
    BCC Return              ;/ If not return

    LDA $15                 ;\
    AND.b #!GrabButton      ;| Are we pressing X/Y? If not, check if we are pushing it.
    BEQ Pushing             ;/

    LDA !14C8,x             ;\ If the sprite is dead, return
    BEQ Return              ;/

    LDA $187A|!Base2        ;\ If we're on Yoshi, return
    BNE Return              ;/

    LDY.b #!SprSize-1       ;\
-   LDA !14C8,y             ;| loop to see if we're holding anything
    CMP #$0B                ;| not my code
    BEQ Return              ;|
    DEY                     ;|
    BPL -                   ;/

    LDA #$0B                ;\
    STA !14C8,x             ;| The sprite is now being carried! :D
    STA !C2,x               ;/
Return:
    LDA !1534,x
    CMP #$FF
    BNE ThatsAll

    LDA !1534,x             ;\  Break the sprite if we started in the air
    BNE JumpDown            ;/

    LDA !1588,x             ;\
    AND #$04                ;| If we are not on the ground branch
    BEQ BreakAlready        ;/
ThatsAll:
    RTS

BreakAlready:
    LDA #$01                ;\ Set a flag
    STA !1534,x             ;/
    RTS

Pushing:
    LDA $0E
    CMP #$E6
    BMI Return
    LDA $15
    AND #$01
    BNE PushingRight
    LDA $15
    AND #$02
    BNE PushingLeft
    JMP Return

PushingRight:
    LDA.b #!PushingSpeed
    STA !B6,x
ShareTheX:
    JSL $01802A|!BankB
    JMP Return

PushingLeft:
    LDA.b #!PushingSpeed^$FF+$01
    STA !B6,x
    JMP ShareTheX

JumpDown:
    JMP BreakAirborne

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite being carried
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Carried:
    LDA #$0B            ;\ Keep this set otherwise the sprite will alsways be solid
    STA !C2,x           ;/
    LDA #$01            ;\ This tells us to keep running this code even after we let go of the sprite
    STA !1510,x         ;/
    LDA !1504,x         ;\ If we are off the ground and going up branch
    BNE GoingUp         ;/
    LDA !1588,x         ;\
    AND #$04            ;| If we are not on the ground branch
    BEQ BreakOrNot      ;/
    LDA #$FF
    STA !1534,x

ToRTS:
    LDA $15                 ;\
    AND.b #!GrabButton      ;| check if we're still holding the sprite
    BEQ Check               ;/
    JSL $01A7DC|!BankB      ;\ Are we touching Mario
    BCC Check               ;/ If not return

Nothing:
    RTS

Check:
    LDA !AA,x               ;\
    BNE Nothing             ;| Is the sprite moving?
    LDA !B6,x               ;|
    BNE Nothing             ;/
    LDA #$09                ;\
    STA !14C8,x             ;|
    STZ !C2,x               ;| if not clear everything
    STZ !1510,x             ;|
    STZ !1528,X             ;|
    STZ !1504,x             ;|
    STZ $15                 ;/
    RTS

BreakOrNot:
    LDA !1588,x             ;\
    AND #$04                ;| If we are not on the ground branch
    BNE Check               ;/

    LDA !AA,x               ;\ Are we moving up?
    CMP #$FA                ;|
    BCC GoingUp             ;/ if so branch

    LDA !B6,x
    BPL Right
    BMI Left

NowBack:
    LDA !1588,x             ;\
    AND #$03                ;| Are we touching a wall?
    BEQ Skip                ;/
    JMP SmashCode

Skip:
    RTS

Right:
    LDA #$0A
    BCC Skip
    JMP NowBack

Left:
    LDA #$F5
    BCS Skip
    JMP NowBack

GoingUp:
    LDA !AA,x               ;\ Are we moving up?
    CMP #$FA                ;|
    BCS ToRTS               ;/ if so branch
    LDA #$04                ;\ Set a flag
    STA !1504,x             ;/
    LDA !1588,x             ;\
    AND #$04                ;| If we are not on the ground branch
    BEQ Skip                ;/
    BRA SmashCode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite being smashed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SmashCode:
    LDA.b #!SmashSFX            ;\ Sound effect to play
    STA.w !SmashBank|!Base2     ;/

    LDA !E4,x                   ;\
    STA $9A                     ;|
    LDA !14E0,x                 ;|
    STA $9B                     ;|
    LDA !D8,x                   ;|
    STA $98                     ;|
    LDA !14D4,x                 ;|
    STA $99                     ;| Shatter code
    PHB                         ;|
    LDA #$02                    ;|
    PHA                         ;|
    PLB                         ;|
    LDA #$00                    ;|
    JSL $028663|!BankB          ;|
    PLB                         ;/

    %BES(SpawnRandom)

    LDA !extra_byte_1,x : STA $03
    LDA !extra_byte_2,x : STA $04
    JMP SpawnSprite

SpawnRandom:
    LDA !1594,x
    BEQ .nothing
    CMP #$01
    BEQ .first
.second
    LDA !extra_byte_3,x : STA $03
    LDA !extra_byte_4,x : STA $04
    JMP SpawnSprite

.first
    LDA !extra_byte_1,x : STA $03
    LDA !extra_byte_2,x : STA $04
    JMP SpawnSprite

.nothing
    STZ !14C8,x
    RTS

SpawnSprite:
    LDA $03                 ; Spawn nothing if sprite == $FF
    CMP #$FF
    BEQ SpawnRandom_nothing

    LDA $04                 ; Check if extra bits == 2 or 3
    BIT #$02
    BNE .custom

    LDA $03                 ; Replace ourselves with the new sprite
    STA !9E,x
    JSL $07F7D2|!BankB      ; Clear all sprite tables
    LDA $04                 ; Set the new sprite's state
    LSR #4
    AND #$0F
    STA !14C8,x
    LDA $04                 ; Set the extra bits
    AND #$01
    STA !extra_bits,x
    RTS

.custom
    LDA $03                 ; Replace ourselves with the new sprite
    STA !7FAB9E,x
    JSL $07F7D2|!BankB      ; Clear all sprite tables (clobbers $00-$02)
    JSL $0187A7|!BankB      ; Set new sprite to custom
    LDA $04                 ; Set the new sprite's state
    LSR #4
    AND #$0F
    STA !14C8,x
    LDA $04                 ; Set the extra bits and the custom sprite flag
    AND #$01
    ASL #2
    ORA.b #!CustomBit
    STA !extra_bits,x
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite GFX code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Graphics:
	lda #!GFX_FileNum        ; find or queue GFX
	%FindAndQueueGFX()
	bcs .gfx_loaded
	rts                      ; don't draw gfx if ExGFX isn't ready
.gfx_loaded
    %GetDrawInfo()

    LDA $00                 ;\ Set the X position of the tile
    STA $0300|!Base2,y      ;/
    LDA $01                 ;\ Set the Y position of the tile
    STA $0301|!Base2,y      ;/
	PHX
    LDX.b #!Tile            ;\ Set the tile number.
	lda !dss_tile_buffer,x
	PLX
    STA $0302|!Base2,y      ;/

    LDA #$F0                ; Discard the sprite two slots below in OAM.
    STA $0309|!Base2,y      ; Fixes visual garbage from $14C8,x == $09

    LDA !15F6,x             ; Write the YXPPCCCT property byte of the tile
    ORA $64
    STA $0303|!Base2,y

    INY #4

    LDY #$02                ; Y ends with the tile size .. 02 means it's 16x16
    LDA #$00                ; A -> number of tiles drawn - 1.
    JSL $01B7B3|!BankB      ; Finish OAM write.
    RTS

Random:
    JSL $01ACF9|!BankB
    AND #$03
    CMP #$03
    BEQ Random
    STA !1594,x
BorneDone:
    RTS

BreakAirborne:
    LDA !1588,x             ;\
    AND #$04                ;| If we are not on the ground branch
    BEQ BorneDone           ;/
    JMP SmashCode
