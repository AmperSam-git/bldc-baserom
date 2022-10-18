;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Tricky Magikoopa
; Both standart and stationary variants.
; This magikoopa casts magic that teleports player to a different level/entrance.
; By RussianMan, requested by Anorakun. Based on disasssembly + stationary variant by yoshicookiezeus
;
; uses extra bit. if set, it'll act as stationary, otherwise act like vanilla (don't use both at the same time)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!MagicNumber = $22              ; The not vanilla sprite to generate (custom Magikoopa magic).
!WandTile = $14                 ; The sprite tile to use for the wand.

!MagicSFX = $10                 ; Sound effect to play when shooting magic.
!MagicBank = $1DF9

!sprite_state = !C2
!sprite_direction = !157C

!StationaryFlag = !1534,x

!StationaryShootTime = $70

!RAM_FrameCounter = $13
!RAM_ScreenBndryXLo = $1A
!RAM_ScreenBndryXHi = $1B
!RAM_ScreenBndryYLo = $1C
!RAM_ScreenBndryYHi = $1D
!RAM_SpritesLocked = $9D
!OAM_DispX = $0300|!Base2
!OAM_DispY = $0301|!Base2
!OAM_Tile = $0302|!Base2
!OAM_Prop = $0303|!Base2
!OAM_Tile3DispX = $0308|!Base2
!OAM_Tile3DispY = $0309|!Base2
!OAM_Tile3 = $030A|!Base2
!OAM_Tile3Prop = $030B|!Base2

!RAM_SmokeNum           = $17C0|!Base2
!RAM_SmokeYLo           = $17C4|!Base2
!RAM_SmokeXLo           = $17C8|!Base2
!RAM_SmokeTimer         = $17CC|!Base2

!RAM_SpriteYLo          = !D8
!RAM_SpriteXLo          = !E4

!RAM_OffscreenHorz      = !15A0
!RAM_OffscreenVert      = !186C

Tilemap:
db $00,$02,$00,$02,$01,$04,$01,$04,$00,$02,$00,$02

Y_Disp:
    db $10,$00

offset:
db $00,$01,$10,$11
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite init JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
    PHB : PHK : PLB
  LDA !extra_bits,x		;\
  AND #$04			;|
  STA !StationaryFlag		;|
  BNE .Stationary		;/extra bit set = stationary

    LDY.b #!SprSize-3           ; setup loop
.loop
    CPY $15E9|!Base2            ;\ if sprite being checked is this one,
    BEQ .next                   ;/ branch
    LDA !14C8,y                 ;\ if sprite being checked is non-existant,
    BEQ .next                   ;/ branch
    PHX
    TYX
    LDA !7FAB9E,x               ;\ if sprite being checked isn't Magikoopa,
    PLX                         ; |    
    CMP !7FAB9E,x               ; |
    BNE .next                   ;/ branch

;PHX
;TYX
;LDA !extra_bits,x		;probably don't need this if the user isn't going to use both
;PLX
;CMP !extra_bits,x
;BNE .next

    STZ !14C8,x                 ; if code gets here, there is another Magikoopa active, so this one is destroyed

.Skip
    PLB
    RTL

.Stationary
LDA #$04			;\start as gone
STA !sprite_state,x		;/
PLB
RTL

.next
    DEY                         ; decrease loop counter
    BPL .loop                   ; if sprites left to check, branch
    STZ $18BF|!Base2            ; activate sprite
    PLB
    RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite code JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
    PHB : PHK : PLB
    JSR Magikoopa
    PLB
    RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Magikoopa:
    LDA #$01
    STA !15D0,x

LDA !sprite_state,x			;
LDY !StationaryFlag			;is stationary?
BNE .CutToTheChase			;cut to the chase then

    LDA !sprite_off_screen_horz,x       ;\ if sprite not offscreen,
    BEQ +                               ;/ branch
    STZ !sprite_state,x             	; else, reset sprite state
+   LDA !sprite_state,x
    AND #$03

.CutToTheChase
    JSL $0086DF|!BankB

MagiKoopaPtrs:
    dw StateSearching               ; searching for a spot
    dw StateAppearing               ; appearing
    dw StateAttacking               ; attacking
    dw StateDisappearing            ; disappearing
    dw StationaryGone		    ; stationary invisible
    dw StateAttacking		    ; stationary attacking

StateSearching:
    LDA $18BF|!Base2                ;\ if sprite not deactivated,
    BEQ .active                     ;/ branch
    STZ !14C8,x                     ; else, destroy sprite
    RTS                             ; return

.active
    LDA !RAM_SpritesLocked          ;\ if sprites locked,
    BNE .return                     ;/ return
    LDY #$24                        ;\ something to do with colour addition?
    STY $40                         ;/
    LDA !1540,x                     ;\ if still waiting after disappearing,
    BNE .return                     ;/ return
    JSL $01ACF9|!BankB              ; get random number
    CMP #$D1                        ;\ if random number more than D1,
    BCS .return                     ;/ return
    CLC                             ;\ else, use it to determine sprite y position
    ADC !RAM_ScreenBndryYLo         ; |
    AND #$F0                        ; |
    STA !sprite_y_low,x             ; |
    LDA !RAM_ScreenBndryYHi         ; |
    ADC #$00                        ; |
    STA !sprite_y_high,x            ;/
    JSL $01ACF9|!BankB              ;\ get another random number
    CLC                             ; | and use it to determine sprite x position
    ADC !RAM_ScreenBndryXLo         ; |
    AND #$F0                        ; |
    STA !sprite_x_low,x             ; |
    LDA !RAM_ScreenBndryXHi         ; |
    ADC #$00                        ; |
    STA !sprite_x_high,x            ;/
    %SubHorzPos()                   ;\ if sprite closer to Mario than 0x20 pixels,
    LDA $0E                         ; |
    CLC                             ; |
    ADC #$20                        ; |
    CMP #$40                        ; |
    BCC .return                     ;/ return
    STZ !sprite_speed_y,x           ; clear sprite y speed
    LDA #$01                        ;\ set sprite x speed
    STA !sprite_speed_x,x           ;/
    JSL $019138|!BankB              ; interact with objects
    LDA !sprite_blocked_status,x    ;\ if sprite not on ground,
    AND #$04                        ; |
    BEQ .return                     ;/ return
    LDA $1862|!Base2                ;\ if high byte of "acts like" setting of the block that sprite is touching isn't 0 (if block solid),
    BNE .return                     ;/ return
    INC !sprite_state,x             ; go to next sprite state
    STZ !1570,x
    JSR CheckMagic
    %SubHorzPos()                   ;\ make sprite face Mario
    TYA                             ; |
    STA !sprite_direction,x         ;/
.return
    RTS                             ; return

StateAppearing:
    JSR CheckPalette
    STZ !1602,x                     ; set graphics frame to use
    JSR Graphics
    RTS                             ; return

FrameBit:
    db $04,$02,$00

Wand_X_Offset:
    db $10,$F8

StateAttacking:
    STZ !15D0,X
    JSL $01803A|!BankB              ; interact with Mario and with other sprites
    %SubHorzPos()                   ;\ make sprite face Mario
    TYA                             ; |
    STA !sprite_direction,x         ;/

LDA !StationaryFlag			;stationary?
BNE .StationaryChecks			;do stationary things

    LDA !1540,x                     ;\ if not time to change sprite state,
    BNE +                           ;/ branch

    INC !sprite_state,x             ; go to next sprite state
BRA CheckMagic

.StationaryChecks
LDA !1540,x				;reset animation and magic spawn?
BNE .CheckProximity			;no

LDA #!StationaryShootTime		;yes
STA !1540,x

.CheckProximity
JSR CheckProximityMario			;is mario close?
BCS .NoDisappear			;no

LDA #$04				;:begone:
STA !sprite_state,x			;

JSR MagikoopaSpawnSmoke
BRA ++

.NoDisappear
LDA !1540,x
BRA +					;after which the code should be the same

CheckMagic:
    LDY #$34                        ;\ more colour addition stuff
    STY $40                         ;/
+   CMP #$40                        ;\ if not time to generate magic,
    BNE ++                          ;/ branch
    PHA                             ; preserve sprite state timer
    LDA !RAM_SpritesLocked          ;\ if sprites locked
    ORA !sprite_off_screen_horz,x   ; | or sprite is offscreen,
    BNE +                           ;/ branch
        JSR SpawnMagic              ; generate magic
+   PLA                             ; retrieve sprite state timer
++  LSR A                           ;\ use sprite state timer to determine graphics frame to use
    LSR A                           ; | in some very complicated manner
    LSR A                           ; |
    LSR A                           ; |
    LSR A                           ; |
    LSR A                           ; |
    TAY                             ; | get seventh bit of sprite state timer into y register
    PHY                             ; | and preserve it
    LDA !1540,x                     ; |
    LSR #3                          ; |
    AND #$01                        ; | get fourth bit of sprite state timer
    ORA FrameBit,y               ; | add in seventh bit
    STA !1602,x                     ;/ and use it to determine sprite graphics frame to use
    JSR Graphics
    LDA !1602,x                     ;\ if sprite graphics frame less than 0x4,
    SEC : SBC #$02                  ; |
    CMP #$02                        ; |
    BCC +                           ;/ branch
    LSR A                           ;\ if it's less than 
    BCC +                           ;/ branch
    LDA !sprite_oam_index,x         ;\ place head tile one pixel lower
    TAX                             ; |
    INC !OAM_DispY,x                ;/
    LDX $15E9|!Base2                ; load sprite index
+   PLY                             ;\ retrieve seventh bit of sprite state timer
    CPY #$01                        ; | if it's clear,
    BNE +                           ;/ branch
        JSR SparkleEffect           ; sparkle effect
+   LDA !1602,x                     ;\ if sprite graphics frame less than 0x4,
    CMP #$04                        ; |
    BCC .return                     ;/ return
    LDY !sprite_direction,x         ;\ use sprite direction to determine x position of wand tile
    LDA !sprite_x_low,x             ; |
    CLC                             ; |
    ADC Wand_X_Offset,y               ; |
    SEC                             ; |
    SBC !RAM_ScreenBndryXLo         ; |
    LDY !sprite_oam_index,x         ; |
    STA !OAM_Tile3DispX,y           ;/
    LDA !sprite_y_low,x             ;\ set y position of wand tile
    SEC                             ; |
    SBC !RAM_ScreenBndryYLo         ; |
    CLC : ADC #$10                  ; |
    STA !OAM_Tile3DispY,y           ;/
    LDA !sprite_direction,x         ;\ set properties of wand tile
    LSR A                           ; |
    LDA #$00                        ; |
    BCS +                           ; |
        ORA #$40                    ; |
+   ORA $64                         ; |
    ORA !sprite_oam_properties,x    ; |
    STA !OAM_Tile3Prop,y            ;/
	PHX
    LDA.b #!WandTile                ;\ set wand tile number
	pha
	and #$03
	tax 
	lda.l offset,x
	sta $0F
	pla
	lsr #2
	tax 
	lda.l !dss_tile_buffer,x
	ora $0F
	plx 
    STA !OAM_Tile3,y                ;/
    TYA                             ;\ ...divide OAM index by four?
    LSR A                           ; |
    LSR A                           ; |
    TAY                             ;/
    LDA #$00                        ;\ set wand tile size
    ORA !sprite_off_screen_horz,x   ; |
    STA $0462|!Base2,y              ;/
.return
    RTS                             ; return

StateDisappearing:
    JSR Disappear
    JSR Graphics
    RTS                             ; return

SpawnMagic:
LDA #$0A
STA $01				;offset a little bit vertically
STZ $00
STZ $02				;\
STZ $03				;/speed set after
LDA #!MagicNumber
SEC				;custom sprite!
%SpawnSprite()

LDA.b #!MagicSFX                ;\ sound effect
    STA.w !MagicBank|!Base2         ;/ 

    LDA #$08                        ;\ set sprite status
    STA !14C8,y                     ;/ 

    LDA #$20			    ;speed
    JSR Aiming                      ; aiming routine
    LDX $15E9|!Base2                ; load sprite index
    LDA $00                         ;\ set sprite speeds
    STA.w !AA,y                     ; |
    LDA $01                         ; |
    STA.w !B6,y                     ;/
    RTS                             ; return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; aiming routine
; input: accumulator should be set to total speed (x+y)
; output: $00 = y speed, $01 = x speed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Aiming:
    STA $01
    PHX                     ;\ preserve sprite indexes of Magikoopa and magic
    PHY                     ;/
    %SubVertPos()           ; $0E = vertical distance to Mario
    STY $02                 ; $02 = vertical direction to Mario
    LDA $0F                 ;\ $0C = vertical distance to Mario, positive
    BPL +                   ; |
        EOR #$FF            ; |
        CLC : ADC #$01      ; |
+   STA $0C                 ;/
    %SubHorzPos()           ; $0F = horizontal distance to Mario
    STY $03                 ; $03 = horizontal direction to Mario
    LDA $0E                 ;\ $0D = horizontal distance to Mario, positive
    BPL +                   ; |
        EOR #$FF            ; |
        CLC : ADC #$01      ; |
+   STA $0D
    LDY #$00
    LDA $0D                 ;\ if vertical distance less than horizontal distance,
    CMP $0C                 ; |
    BCS +                   ;/ branch
        INY                 ; set y register
        PHA                 ;\ switch $0C and $0D
        LDA $0C             ; |
        STA $0D             ; |
        PLA                 ; |
        STA $0C             ;/
+   STZ $0B                 ;\ zero out $00 and $0B
    STZ $00                 ;/
    LDX $01                 ;\ divide $0C by $0D?
-   LDA $0B                 ; |\ if $0C + loop counter is less than $0D,
    CLC : ADC $0C           ; | |
    CMP $0D                 ; | |
    BCC +                   ; |/ branch
        SBC $0D             ; | else, subtract $0D
        INC $00             ; | and increase $00
+   STA $0B                 ; |
    DEX                     ; |\ if still cycles left to run,
    BNE -                   ;/ / go to start of loop
    TYA                     ;\ if $0C and $0D was not switched,
    BEQ +                   ;/ branch
        LDA $00             ;\ else, switch $00 and $01
        PHA                 ; |
        LDA $01             ; |
        STA $00             ; |
        PLA                 ; |
        STA $01             ;/
+   LDA $00                 ;\ if horizontal distance was inverted,
    LDY $02                 ; | invert $00
    BEQ +                   ; |
        EOR #$FF            ; |
        CLC : ADC #$01      ; |
        STA $00             ;/
+   LDA $01                 ;\ if vertical distance was inverted,
    LDY $03                 ; | invert $01
    BEQ +                   ; |
        EOR #$FF            ; |
        CLC : ADC #$01      ; |
        STA $01             ;/
+   PLY                     ;\ retrieve Magikoopa and magic sprite indexes
    PLX                     ;/
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Disappear:
    LDA !1540,x                 ;\ only run code every third frame
    BNE .return                 ; |
    LDA #$02                    ; |
    STA !1540,x                 ;/
    DEC !1570,x 
    LDA !1570,x                 ;\ if palette changing done,
    BNE .palette                ;/ branch
    INC !sprite_state,x         ; go to next sprite state
    LDA #$10                    ;\ set time until next appeareance
    STA !1540,x                 ;/
    PLA                         ;\ return directly from main routine, skipping graphics routine
    PLA                         ;/
.return 
    RTS                         ; return

.palette
    ;JMP ChangePalette		;optimization............................

CheckPalette:
    LDA !1540,x                     ;\ only run code every fifth frame
    BNE .return                     ; |
    LDA #$04                        ; |
    STA !1540,x                     ;/
    INC !1570,x                
    LDA !1570,x                     ;\ if palette changing done,
    CMP #$09                        ; |
    BNE +                           ;/ branch
        LDY #$24                    ;\ again, colour addition stuff
        STY $40                     ;/
+   CMP #$09                        ;\ if palette changing done, (...again?)
    BNE ChangePalette               ;/ branch
    INC !sprite_state,x             ; go to next sprite state
    LDA #$70                        ;\ set time before appearing again
    STA !1540,x                     ;/
.return
    RTS                             ; return

ChangePalette:
    LDA !1570,x                 ;\ get colour table offset
    DEC A                       ; |
    ASL #4                      ; |
    TAX                         ;/
    STZ $00                     ; setup loop
    LDY $0681|!Base2            ; get initial palette offset
-   LDA Palettes,x              ;\ set new colour
    STA $0684|!Base2,y          ;/
    INY                         ; increase palette offset
    INX                         ; increase colour table offset
    INC $00                     ; increase loop counter
    LDA $00                     ;\ if still colours left to change,
    CMP #$10                    ; |
    BNE -                       ;/ go to start of loop
    LDX $0681|!Base2            ;\ yay for doing stuff to unknown RAM addresses! (buffer shenanigans)
    LDA #$10                    ; |
    STA $0682|!Base2,x          ; |
    LDA #$F0                    ; |
    STA $0683|!Base2,x          ; |
    STZ $0694|!Base2,x          ; |
    TXA                         ; |
    CLC : ADC #$12              ; |
    STA $0681|!Base2            ;/
    LDX $15E9|!Base2            ; retrieve sprite index
    RTS                         ; return

Palettes:
    dw $7FFF,$294A,$0000,$1024,$1C49,$1446,$000A,$002A              ; 8 palettes of 8 colors each, including the transparent color.
    dw $7FFF,$35AD,$0000,$1845,$246B,$1C6A,$000D,$00AD		    ; order: transparent, white, black (all $0000), 3 robe colors, 2 skin colors
    dw $7FFF,$4210,$0000,$2046,$2C8D,$206B,$0050,$0110		    ; unfortunately a little complicated to edit, just try experimenting with the values
    dw $7FFF,$4E73,$0000,$2867,$308E,$308F,$00B3,$0173		    ; you can use LM's palette editor to get color values (SNES RGB Value at the bottom-right)
    dw $7FFF,$5AD6,$0000,$2C68,$34B0,$3490,$0116,$01D6
    dw $7FFF,$6739,$0000,$3069,$38B1,$40B3,$0179,$0239
    dw $7FFF,$739C,$0000,$386B,$3CB3,$48D6,$01DC,$029C
    dw $7FFF,$7FFF,$0000,$3C6C,$40B4,$4CD8,$023F,$02FF

StationaryGone:
    LDA !RAM_SpritesLocked          ;\ if sprites locked,
    BNE Gone_Return                 ;/ return

    JSR CheckProximityMario
    BCC Gone_Return

    INC !sprite_state,x          ; go to next sprite state
    STZ !1570,x

    %SubHorzPos()                   ;\ make sprite face Mario
    TYA                             ; |
    STA !sprite_direction,x         ;/

    JSR MagikoopaSpawnSmoke

    LDA #$70
    STA !1540,x

Gone_Return:
    RTS

CheckProximityMario:
    %SubHorzPos()           ;\ if sprite not closer to Mario than 0x20 pixels horizontally,
    LDA $0E                 ; |
    CLC : ADC #$30          ; |
    CMP #$60                ; |
    BCS +                   ;/ branch
    %SubVertPos()           ;\ if sprite not closer to Mario than 0x20 pixels horizontally,
    LDA $0F                 ; |
    CLC : ADC #$30          ; |
    CMP #$60                ; |
+
    RTS

MagikoopaSpawnSmoke:
    LDA !RAM_OffscreenVert,x
    ORA !RAM_OffscreenHorz,x
    BNE .Return

LDA #$08
STA $01
STZ $00
LDA #$1B
STA $02
LDA #$01
%SpawnSmoke()

.Return
    RTS     

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Graphics routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Graphics:
lda #$2D              ; find or queue GFX
%FindAndQueueGFX()
bcs .gfx_loaded
rts                      ; don't draw gfx if ExGFX isn't ready 

.gfx_loaded
lda !dss_tile_buffer+$00
sta !dss_tile_buffer+$05
lda #$2C                 ; find or queue GFX
%FindAndQueueGFX()
bcs .gfx_loaded2
rts                      ; don't draw gfx if ExGFX isn't ready

.gfx_loaded2
    %GetDrawInfo()
    LDA !1602,x                     ;\ use graphics frame to determine initial tile table offset
    ASL A                           ; |
    STA $03                         ;/
    LDA !sprite_direction,x
    STA $02
    PHX                             ; preserve sprite index
    LDX #$01                        ; setup loop counter
-   LDA $01                         ;\ set y position of tile
    CLC : ADC Y_Disp,x              ; |
    STA !OAM_DispY,y                ;/
    LDA $00                         ;\ set x position of tile
    STA !OAM_DispX,y                ;/
    PHX                             ; preserve loop counter
    LDX $03                         ; get tilemap index
    LDA Tilemap,x                   ;\ set tile number
	TAX
	lda !dss_tile_buffer,x
    STA !OAM_Tile,y                 ;/
    LDX $15E9|!Base2                ; load sprite index
    LDA !15F6,x                     ; load sprite graphics properties
    PLX                             ; retrieve loop counter
    PHY                             ; preserve OAM index
    LDY $02                         ;\ if sprite facing right,
    BNE +                           ; |
        EOR #$40                    ;/ flip tile
+   PLY                             ; retrieve OAM index
    ORA $64                         ; add in level properties
    STA !OAM_Prop,Y                 ; set tile properties
    INY #4
    INC $03
    DEX                             ; decrease loop counter
    BPL -                           ; if still tiles left to draw, go to start of loop
    PLX                             ; retrieve sprite index
    LDY #$02                        ; the tiles written were 16x16
    LDA #$01                        ; we wrote two tiles
    %FinishOAMWrite()
    RTS                             ; return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SparkleEffect:
    LDA !RAM_FrameCounter               ;\ only run code every fourth frame
    AND #$03                            ; |
    ORA !sprite_off_screen_vert,x       ; | if sprite offscreen vertically
    ORA !RAM_SpritesLocked              ; | or sprites locked,
    BNE .return                         ;/ return
    JSL $01ACF9|!BankB                  ;\ #$02 = sprite xpos low byte + random number between 0x-5 and 0xB
    AND #$0F                            ; |
    CLC                                 ; |
    LDY #$00                            ; |
    ADC #$FC                            ; |
    BPL +                               ; |
        DEY                             ; |
+   CLC                                 ; |
    ADC !sprite_x_low,x                 ; |
    STA $02                             ;/
    TYA                                 ;\ if $02 means an offscreen location?
    ADC !sprite_x_high,x                ; |
    PHA                                 ; |
    LDA $02                             ; |
    CMP !RAM_ScreenBndryXLo             ; |
    PLA                                 ; |
    SBC !RAM_ScreenBndryXHi             ; |
    BNE .return                         ;/ return
    LDA $148E|!Base2                    ;\ #$00 = sprite ypos low byte + random number between 0x-2 and 0xD
    AND #$0F                            ; |
    CLC : ADC #$FE                      ; |
    ADC !sprite_y_low,x                 ; |
    STA $00                             ;/
    LDA !sprite_y_high,x                ;\ #$01 = sprite ypos high byte with changes for earlier random number
    ADC #$00                            ; |
    STA $01                             ;/
    JSL $0285BA|!BankB                  ; sparkle effect
.return
    RTS
