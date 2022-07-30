;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Any Sprite Line-Guided v1.2 by dtothefourth
; Optimizations, fixes and extra stuff by KevinM
;
; Acts as a wrapper for any normal or custom sprite, allowing
; it to easily be made line-guided at the cost of an extra
; sprite slot.
;
; Extra bit: if set, the spawned sprite is custom.
;
; Options are set using the extension box in LM using 8 bytes
;
; SS XX YY CC SP E1 E2 E3 E4
; 
; SS = Sprite number
; XX = X offset for position sprite ($80-$FF = negative offset)
; YY = Y offset for position sprite ($80-$FF = negative offset)
; CC = Custom settings. Format: epP-SSSS
;  - SSSS: the state the sprite will be spawned in (using the $14C8 format).
;    (0 acts as 1 because state 0 doesn't make sense here).
;    State 1 (set with either 0 or 1) is init, which is what you usually want.
;    State 9 is carryable, useful for sprites like shells or throwblocks.
;  - e: if 1 (i.e. add 80 to the number), will set the extra bit for the spawned sprite.
;  - p: to be used with platforms: if set (i.e. add 40 to the number)
;    Mario will move with the platform instead of sliding on it.
;    Note: it doesn't work with Carrot Lifts, Keys and Boo Blocks.
;  - P: second platform option, which does the same thing as the p option
;    but it's recommended for sprites that use custom solid sprite code
;    (for example, MarioFanGamer's Numbered Platform sprite).
;    Note: this option doesn't work for sprites that naturally move horizontally.
;    Also, this option is overriden by the p option: don't use them together.
; SP = speed multiplier (+1)
;  00 = normal speed, 01 = double speed, etc. (max 7F)
;  FF (or any negative value) = stationary (the sprite won't move at all)
; E1-E4 = these 4 values set the 4 extra bytes for the other sprite (if custom).
;
; Note:
;  - To spawn a Shell, don't use numbers DA-DF. Use instead 04-09,
;    and set the state as carryable (extra byte 4 = 09).
;  - To spawn a throw block, use sprite number 53 and spawn it in
;    carryable state (or it won't appear).
;  - To spawn a P-Switch, use 0 or 1 for extra byte 4, or its color will be wrong.
;  - When inserting the sprite through the custom collection menu in LM, the last 4 bytes
;    will have random values in them (because the list only supports up to 4).
;    If the sprite you need is vanilla or it's custom but doesn't use the extra bytes, you
;    can ignore them and leave them random. Otherwise, you'll have to change them manually
;    (but in this case you'd have to change them anyway most of the time).
;    NOTE: this problem is fixed in PIXI v1.3.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
macro StoreExtraByte(addr)
    lda [$00],y
    sta <addr>
    iny
endmacro

macro StoreExtraByteX(addr)
    lda [$00],y
    sta <addr>,x
    iny
endmacro

!XOffset   = !1602
!YOffset   = !1594
!Slot      = !1504
!Settings  = !1626
!SpeedMult = !1510

print "INIT ",pc
ExtraBytesSetup:
    lda !extra_byte_1,x
    sta $00
    lda !extra_byte_2,x
    sta $01
    lda !extra_byte_3,x
    sta $02
    ldy #$00
    %StoreExtraByte($04)        ; $04 = sprite number.
    %StoreExtraByteX(!XOffset)  ; $1602,x = X offset.
    %StoreExtraByteX(!YOffset)  ; $1594,x = Y offset.
    %StoreExtraByteX(!Settings) ; $05 = additional settings.
    %StoreExtraByteX(!SpeedMult); $1510,x = speed multiplier
    %StoreExtraByte($05)        ; $06 = extra byte 1
    %StoreExtraByte($06)        ; $07 = extra byte 2
    %StoreExtraByte($07)        ; $08 = extra byte 3
    %StoreExtraByte($08)        ; $09 = extra byte 4               
Spawn:
    stz $00
    stz $01
    stz $02
    stz $03
    lda !extra_bits,x           ;\
    and #$04                    ;| Extra bit set = custom
    lsr #3                      ;/
    lda $04
    %SpawnSprite()
    bcc +                       ;\ If spawn failed, kill the sprite
    jmp AllowRespawn            ;/ but allow it to respawn.
+   
    tya                         ;\ Save slot in RAM.
    sta !Slot,x                 ;/
    
    lda !Settings,x             ;\
    and #$0F                    ;| Set the sprite state
    beq +                       ;|
    sta !14C8,y                 ;/
+
    lda !Settings,x             ;\
    bpl +                       ;|
    tyx                         ;|
    lda !extra_bits,x           ;| Set the extra bit
    ora #$04                    ;|
    sta !extra_bits,x           ;|
    ldx $15E9|!Base2            ;/
+
    lda #$01                    ;\ Disable object interaction
    sta !15DC,y                 ;/

    %BEC(+)                     ;\
    tyx                         ;|
    lda $05                     ;|
    sta !extra_byte_1,x         ;|
    lda $06                     ;|
    sta !extra_byte_2,x         ;| If the sprite is custom, set the extra bytes.
    lda $07                     ;|
    sta !extra_byte_3,x         ;|
    lda $08                     ;|
    sta !extra_byte_4,x         ;|
    ldx $15E9|!Base2            ;/
+
    inc !1540,x                 ;\ Run line-guided routine twice
    jsr HandleLineGuide         ;| (why? idk, vanilla does it).
    jsr HandleLineGuide         ;/

    jmp Offset                  ; Offset the position also on spawn (prevents unintended despawns when using non-zero offsets)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
Main:
    lda !SpeedMult,x
    bmi +
-   pha
    jsr HandleLineGuide     ; Run line-guided routine.
    pla
    dec
    bpl -
+
    
    lda !Slot,x             ;\ Retrieve slot of the other sprite.
    tay                     ;/
    
    lda !14C8,y             ;\ If the sprite died, kill this one too.
    bne CheckState          ;/

Despawn:
    lda !15A0,y             ;\ If it's offscreen, assume it was killed by SubOffScreen().
    ora !186C,y             ;| (This still allows powerups to respawn if grabbed offscreen, for example, but still better than nothing).
    beq Kill                ;/
AllowRespawn:
    lda !161A,x             ;\
    tax                     ;|
    lda #$00                ;| Kill the sprite but allow it to respawn.
    sta !1938,x             ;|
    ldx $15E9|!Base2        ;|
    stz !14C8,x             ;/
    rtl

Kill2:
    lda #$00                ;\ Re-enable object interaction.
    sta !15DC,y             ;/
Kill:
    stz !14C8,x
    lda #$FF                ;\ Make it not respawn.
    sta !161A,x             ;/
    rtl

CheckState:
    cmp #$02                ;\
    bcc Alive               ;| If the sprite is dead, kill this one too.
    cmp #$07                ;|
    bcc Kill                ;/

    cmp #$0B                ;\
    beq Kill2               ;| If Mario or Yoshi grabbed the sprite,
    cmp #$07                ;| make it interact with objects and kill this sprite.
    beq Kill2               ;/

    lda !15D0,y             ;\ If on Yoshi's tongue, kill
    bne Kill2               ;/ (but make it interact with objects again).

    ldx #!SprSize-1         ;\
-   lda !14C8,x             ;|
    cmp #$08                ;|
    bcc +                   ;|
    lda !9E,x               ;|
    cmp #$2D                ;|
    bne +                   ;| If the sprite is being eaten by Baby Yoshi, kill.
    tya                     ;|
    cmp !160E,x             ;|
    bne +                   ;|
    ldx $15E9|!Base2        ;|
    bra Kill                ;|
+   dex                     ;|
    bpl -                   ;|
    ldx $15E9|!Base2        ;/

Alive:
    lda.w !9E,y             ;\
    cmp #$35                ;| If it's Yoshi and he's not idle anymore,
    bne +                   ;| kill this sprite and enable object interaction for Yoshi.
    lda.w !C2,y             ;|
    bne Kill2               ;/
+
    lda $14AE|!Base2        ;\
    beq +                   ;|
    lda !190F,y             ;|
    and #$40                ;|
    bne +                   ;|
    lda.w !9E,y             ;| If the silver switch is active and the sprite is not a silver coin,
    cmp.b #read1($02B9DA)   ;| turn it into a silver coin (if the tweaker is not set).
    bne ++                  ;| This both fixes the issue where sprites spawned in the
    lda !15F6,y             ;| 2 highest slots don't turn into silver coins, and
    and #$02                ;| the issue where spawning after hitting the switch
    bne +                   ;| wouldn't make it spawn as a silver coin.
++  phk                     ;|
    pea.w .jslrtsreturn-1   ;|
    pea.w $02B889-1         ;|
    jml $02B9D9|!BankB      ;|
.jslrtsreturn               ;/

+   lda !Settings,x         ;\ If sprite not set to move Mario with it, skip.
    and #$60                ;|
    beq ++                  ;/
    lda $1491|!Base2        ;\ Store how much the sprite moved horizontally
    sta !1528,y             ;/ in the other sprite's table.
    bit !Settings,x         ;\ If not using the p option, skip running vanilla solid sprite routine.
    bvc ++                  ;/
    phy                     ; Backup Y.
    tyx                     ; Switch to other sprite.
    jsl $01B44F|!BankB      ; Run "Solid sprite" routine.
    stz !1528,x             ; Make sure Mario's position isn't updated twice.
    stz !sprite_speed_x,x   ;\ Reset other sprite's speeds.
    stz !sprite_speed_y,x   ;/ This reduced the jank with some horizontal moving platforms.
    stz !sprite_speed_x_frac,x  ;\ Also reset the fraction bits for good measure.
    stz !sprite_speed_y_frac,x  ;/
    lda !9E,x               ;\
    cmp #$BB                ;| Dumb fix for the grey castle block.
    bne +                   ;|
    stz !C2,x               ;/
+   ply                     ; Restore Y.
    ldx $15E9|!Base2        ; Restore X.
    stz $1491|!Base2
++

Offset:
    stz $00                 ;\
    lda !XOffset,x          ;|
    bpl +                   ;|
    dec $00                 ;|
+   clc                     ;| Offset the sprite horizontally.
    adc !E4,x               ;|
    sta.w !E4,y             ;|
    lda !14E0,x             ;|
    adc $00                 ;|
    sta !14E0,y             ;/

    stz $00                 ;\
    lda !YOffset,x          ;|
    bpl +                   ;|
    dec $00                 ;|
+   clc                     ;| Offset the sprite vertically.
    adc !D8,x               ;|
    sta.w !D8,y             ;|
    lda !14D4,x             ;|
    adc $00                 ;|
    sta !14D4,y             ;/
    rtl

HandleLineGuide:
    lda !1540,x             ;\ This is used to make the routine run during init.
    bne .RunStatePtr        ;/
    lda $9D                 ;\ If sprites are locked, return.
    bne .Return             ;/
.RunStatePtr:
    lda !sprite_x_low,x     ;\ Backup initial X position for later.
    pha                     ;/
    phb
    lda #$01
    pha
    plb
    phk
    pea.w ..jslrtsreturn-1
    pea.w $0180CA-1
    jml $01D75C|!BankB
..jslrtsreturn
    plb
    pla                     ;\
    sec                     ;|
    sbc !sprite_x_low,x     ;| Track how much the sprite moved horizontally.
    eor #$FF                ;|
    inc                     ;|
    clc                     ;|
    adc $1491|!Base2        ;|
    sta $1491|!Base2        ;/
.Return
    rts
