;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Albatoss, by mikeyk
;;
;; Description: This is a flying bird that can drop Bob-ombs.
;;
;; Uses first extra bit: YES
;; If the first extra bit is set, the Albatoss will drop Bob-ombs
;;
;; Extension Byte 1 (At $7FAB40)
;;    bit 0 - enable spin killing (if ridable)
;;    bit 2 - pause when dropping bob-ombs
;;    bit 7 - spawn custom bomb
;;
;; Values that you can use: 00, 01, 04, 05, 80, 81, 84 and 85
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!GFX_FileNum = $A3 ; DSS ExGFX
!GFX_FileNum_Torpedo = $A4 ; DSS ExGFX

!ExtraProp      = !7FAB40
!ExtraBits      = !7FAB10
!DropTimer      = !1540
!TimeTilDrop    = $64
!TimeTilExplode = $58
!TimeToPause  = $18
!BombPal        = $05
!SpriteToDrop = $0D			; Number of the normal sprite that the albatoss will drop (Bob-Omb)
!CustomSpriteToDrop = $B9	; Number of the custom sprite that the albatoss will drop (Torpedo)
!TorpedoTile = $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT and MAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT "INIT ",pc
       PHY
       %SubHorzPos()
       TYA
       STA !157C,x
       PLY
       RTL

PRINT "MAIN ",pc
       PHB                     ; \
       PHK                     ;  | main sprite function, just calls local subroutine
       PLB                     ;  |
       JSR SpriteCodeStart     ;  |
       PLB                     ;  |
       RTL                     ; /


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

XSpeeds:           db $10,$F0
KilledXSpeed:      db $F0,$10

Return:
       RTS
SpriteCodeStart:
       JSR SpriteGraphics     ; Graphics routine
       LDA !14C8,x             ; \
       CMP #$08                ;  | if status != 8, return
       BNE Return              ; /
       %SubOffScreen()         ; Handle off screen situation

       LDA !ExtraBits,x        ; Only drop if extra bit is set
       AND #$04
       BEQ Move

       LDA !DropTimer,x
       CMP #!TimeToPause
       BCS Move
       CMP #$00
       BNE NoReset3           ;Reset timer if it equals 0
       LDA #!TimeTilDrop
       STA !DropTimer,x

NoReset3:
       CMP #$01
       BNE DontDrop
       JSR SubHammerThrow      ;Drop code

DontDrop:
       STZ !B6,x
       LDA !ExtraProp,x
       AND #$04
       BNE DontMove

Move:
       LDY !157C,x             ; \ Set x speed based on direction
       LDA XSpeeds,y           ;  |
       STA !B6,x               ; /
       LDA $9D                 ; \ if sprites locked, return
       BNE Return              ; /

DontMove:
       STZ !AA,x
       JSL $01802A             ; update position based on speed values
       LDA !1588,x             ; \ if sprite is in contact with an object...
       AND #$03                ;  |
       BEQ NoContact          ;  |
       LDA !157C,x             ;  | flip the direction status
       EOR #$01                ;  |
       STA !157C,x             ; /

NoContact:
       JSL $01A7DC             ; check for mario/sprite contact (carry set = contact)

       BCC Return_24           ; return if no contact
       %SubVertPos()           ;
       LDA $0E                 ; \ if mario isn't above sprite, and there's vertical contact...
       CMP #$E6                ;  |     ... sprite wins
       BPL SPRITE_WINS         ; /
       LDA $7D                 ; \if mario speed is upward, return
       BMI Return_24           ; /
       LDA !ExtraProp,x
       AND #$01
       BEQ SpinKillDisabled  ;
       LDA $140D|!Base2        ; \ if mario is spin jumping, goto SpinKill
       BNE SpinKill           ; /

SpinKillDisabled:
       LDA #$01                ; \ set "on sprite" flag
       STA $1471|!Base2        ; /
       LDA #$06                ; \ set riding sprite
       STA !154C,x             ; /
       STZ $7D                 ; y speed = 0
       LDA #$E2                ; \
       LDY $187A|!Base2        ;  | mario's y position += E2 or D2 depending if on yoshi
       BEQ NoYoshi            ;  |
       LDA #$D2                ;  |

NoYoshi:
       CLC                     ;  |
       ADC !D8,x               ;  |
       STA $96                 ;  |
       LDA !14D4,x             ;  |
       ADC #$FF                ;  |
       STA $97                 ; /
       LDY #$00                ; \
       LDA $1491|!Base2        ;  | $1491 == 01 or FF, depending on direction
       BPL Label9              ;  | set mario's new x position
       DEY                     ;  |

Label9:
       CLC                     ;  |
       ADC $94                 ;  |
       STA $94                 ;  |
       TYA                     ;  |
       ADC $95                 ;  |
       STA $95                 ; /
RETURN_24B:
       RTS                     ;

SPRITE_WINS:
       LDA !154C,x             ; \ if riding sprite...
       ORA !15D0,x             ;  |   ...or sprite being eaten...
       BNE Return_24           ; /   ...return
       LDA $1490|!Base2        ; \ if mario star timer > 0, goto HAS_STAR
       BNE HasStar            ; / NOTE: branch to Return_24 to disable star killing
       JSL $00F5B7             ; hurt mario

Return_24:
       RTS                     ; final return

SpinKill:
       JSR SubStompPts       ; give mario points
       ;JSL $01AA33            ; set mario speed, NOTE: remove call to not bounce off sprite
       JSL $01AB99             ; display contact graphic
       LDA #$04                ; \ status = 4 (being killed by spin jump)
       STA !14C8,x             ; /
       LDA #$1F                ; \ set spin jump animation timer
       STA !1540,x             ; /
       JSL $07FC3B             ; show star animation
       LDA #$08                ; \ play sound effect
       STA $1DF9|!Base2        ; /
       RTS                     ; return

HasStar:
       %Star()
	   RTS

NoReset2:
       JSL $02ACE5             ; give mario points
       LDY $18D2|!Base2        ; \
       CPY #$08                ;  | if consecutive enemies stomped < 8 ...
       BCS NoSound2            ;  |
       LDA StarSounds,y       ;  |    ... play sound effect
       STA $1DF9|!Base2        ; /

NoSound2:
	   RTS                     ; final return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Hammer routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

XOffset:            db $0A,$07
; XOffset2:           db $00,$00
!YOffset = $0C

RETURN68:
       RTS

SubHammerThrow:
       LDA !15A0,x             ; \ no egg if off screen
       ORA !186C,x             ;  |
       ORA !15D0,x
       BNE RETURN68

	   ldy #!SpriteToDrop
	   lda !ExtraProp,x
	   bpl .isnormal
	   ldy #!CustomSpriteToDrop
.isnormal
	   phy
	   ldy !157C,x
	   lda XOffset,y
	   sta $00
	   ply
	   lda #!YOffset
	   sta $01
	   stz $02
	   stz $03
	   lda !ExtraProp,x
	   rol
	   php
	   tya
	   plp
	   %SpawnSprite()
	   bcs RETURN67
       ;JSL $02A9DE             ; \ get an index to an unused sprite slot, return if all slots full
       ;BMI RETURN68            ; / after: Y has index of sprite being generated
       ;LDA #$08                ; \ set sprite status for new sprite
       ;STA !14C8,y             ; /
       ;LDA #!SpriteToDrop
       ;STA.w !9E,y
       ;PHY                     ; set x position for new sprite
       ;LDA !157C,x
       ;TAY
       ;LDA !E4,x
       ;CLC
       ;ADC XOffset,y
       ;PLY
       ;STA.w !E4,y
       ;PHY                     ; set x position for new sprite
       ;LDA !157C,x
       ;TAY
       ;LDA !14E0,x
       ;ADC XOffset2,y
       ;PLY
       ;STA !14E0,y
       ;LDA !D8,x               ; \ set y position for new sprite
       ;CLC                     ;  | (y position of generator - 1)
       ;ADC #!YOffset           ;  |
       ;STA.w !D8,y             ;  |
       ;LDA !14D4,x             ;  |
       ;ADC #$00                ;  |
       ;STA !14D4,y             ; /
       ;PHY
       ;PHX                     ; \ before: X must have index of sprite being generated
       ;TYX                     ;  | routine clears *all* old sprite values...
       ;JSL $07F7D2             ;  | ...and loads in new values for the 6 main sprite tables
	   phy
	   phx
	   tyx
       %SubHorzPos()
       PLX                     ; /
       TYA
       PLY
       STA !157C,y
       LDA #$0C
       STA !1564,y
	   lda !ExtraProp,x
	   bmi RETURN67
       LDA !TimeTilExplode
       STA !1540,y

RETURN67:
       RTS                     ; return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite graphics routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TILEMAP:
       db $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F
       db $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F
HORZ_DISP:
       db $10,$00,$10,$00,$10,$00,$10,$00,$10,$00,$10,$00,$10,$00,$10,$00
       db $00,$10,$00,$10,$00,$10,$00,$10,$00,$10,$00,$10,$00,$10,$00,$10


SpriteGraphics:
       lda #!GFX_FileNum
       %FindAndQueueGFX()
       bcs .gfx_loaded
       rts
.gfx_loaded
       %GetDrawInfo()          ; sets y = OAM offset
       PHX
       LDA !157C,x             ; \ $02 = direction
       STA $02                 ; /
       LDA !14C8,x
       CMP #$02
       BNE NoStar
       LDA !15F6,x
       ORA #$80
       STA !15F6,x
       LDA #$00
       STA $03
       BRA CheckPos
NoStar:
       LDA $14                 ; \
       LSR A                   ;  |
       LSR A                   ;  |
       LSR A                   ;  |
       CLC                     ;  |
       ADC $15E9|!Base2        ;  |
       AND #$07                ;  |
       ASL A

CheckPos:
       PHY
       LDY $02
       BEQ Store
       CLC
       ADC #$10

Store:
       STA $03                 ; $03 = index to frame start (0 or 1)
       PLY
       LDX #$01

LoopStart:
       PHX
       TXA
       ORA $03
       TAX
       LDA $00                 ; tile x position = sprite x location ($00)
       CLC
       ADC HORZ_DISP,x
       STA $0300|!Base2,y
       LDA $01                 ; tile y position = sprite y location ($01)
       STA $0301|!Base2,y
       LDA TILEMAP,x
       TAX
       lda.l !dss_tile_buffer,x
       STA $0302|!Base2,y
       LDX $15E9|!Base2
       LDA !15F6,x             ; tile properties xyppccct, format
       LDX $02                 ; \ if direction == 0...
       BNE NO_FLIP             ;  |
       ORA #$40                ; /    ...flip tile
NO_FLIP:
       ORA $64                 ; add in tile priority of level
       STA $0303|!Base2,y      ; store tile properties
       PLX
       INY                     ; \ increase index to sprite tile map ($300)...
       INY                     ;  |    ...we wrote 4 bytes...
       INY                     ;  |
       INY                     ; /    ...so increment 4 times
       DEX                     ;  | go to next tile of frame and loop
       BPL LoopStart           ; /
       PLX
       LDA !14C8,x
       CMP #$08
       BNE NO_SHOW
       LDA !DropTimer,x
       CMP #$20
       BCS NO_SHOW
       CMP #$01
       BCC NO_SHOW
       BRA SHOW

NO_SHOW:
       LDY #$02                ; \ FF, because we wrote to 460
       LDA #$02                ;  | A = number of tiles drawn - 1

       JSL $01B7B3             ; / don't draw if offscreen
       RTS
SHOW:
       lda !ExtraProp,x
       bpl .oldtile
       lda #!TorpedoTile
       sta $0302|!Base2,y
.oldtile
       LDA !BombPal
       PHX
       LDX $02
       BNE NO_FLIP2
       ORA #$40

NO_FLIP2:
       PLX
       ORA $64                 ; add in tile priority of level
       STA $0303|!Base2,y
       LDY #$02                ; \ FF, because we wrote to 460
       LDA #$03                ;  | A = number of tiles drawn - 1

       JSL $01B7B3             ; / don't draw if offscreen
       RTS                     ; return



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; routines below can be shared by all sprites.  they are ripped from original
; SMW and poorly documented
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; points routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StarSounds:         db $00,$13,$14,$15,$16,$17,$18,$19

SubStompPts:
        PHY                     ;
        LDA $1697|!Base2        ; \
        CLC                     ;  |
        ADC !1626,x             ; / some enemies give higher pts/1ups quicker??
        INC $1697|!Base2        ; increase consecutive enemies stomped
        TAY                     ;
        INY                     ;
        CPY #$08                ; \ if consecutive enemies stomped >= 8 ...
        BCS NoSound            ; /    ... don't play sound
        LDA StarSounds,y       ; \ play sound effect
        STA $1DF9|!Base2        ; /

NoSound:
       TYA                     ; \
       CMP #$08                ;  | if consecutive enemies stomped >= 8, reset to 8
       BCC NoReset            ;  |
       LDA #$08                ; /

NoReset:
       JSL $02ACE5             ; give mario points
       PLY                     ;
       RTS                     ; return

