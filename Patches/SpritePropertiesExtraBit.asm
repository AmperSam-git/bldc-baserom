;===================================================================;
; Extra bit detection enable.                                       ;
; Set 0 for the sprites you want to keep vanilla.                   ;
; Some sprites share some initalization code so they're grouped.    ;
;===================================================================;
!Sprite09 = 1                   ; Green bouncing Koopa
!Sprite1E_4D_4E_AD_B1_C1 = 1    ; Lakitu / Ground dwelling Monty Mole / Ledge dwelling Monty Mole / Wooden spike / Creating/Eating block / Flying grey turnblocks
!Sprite22_23_24_25 = 1          ; Green/red vertical/horizontal net Koopas
!Sprite3A_3B_3C_A5_A6 = 1       ; Urchins / Wall-following fuzzy/sparky / Hothead
!Sprite3E = 1                   ; P-Switch
!Sprite63 = 1                   ; Line-guided platform
!Sprite64 = 1                   ; Line-guided rope mechanism
!Sprite65_66_67_68 = 1          ; Line-guided chainsaw / grinder / fuzzy
!Sprite73 = 1                   ; Super Koopa
!Sprite8C = 0                   ; Fireplace smoke / Side exit
!Sprite8F = 1                   ; Scale platforms
!Sprite94 = 1                   ; Whistlin' Chuck
!Sprite9E_A3_E0 = 1             ; Ball and Chain / Gray platform on chain / 3 Platforms on chains
!SpriteA4 = 1                   ; Floating spike ball
!SpriteB9 = 1                   ; Info box
!SpriteBA = 1                   ; Timed lift

;===============================;
; SA-1 detection and defines.   ;
;===============================;
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
    !bank = $000000
    !E4 = $322C
    !164A = $75BA
    !extra_bits = $6040
else
    lorom
    !addr = $0000
    !bank = $800000
    !E4 = $E4
    !164A = $164A
    !extra_bits = $7FAB10
endif

;===============================;
; Hijacks                       ;
;===============================;
if !Sprite09                ; Green bouncing Koopa
org $01856E
    autoclean jsl Sprite09
endif

if !Sprite1E_4D_4E_AD_B1_C1 ; Lakitu / Monty Moles / Wooden spike / Creating/Eating block / Grey flying turnblocks
org $0184CE
    autoclean jsl Sprite1E_4D_4E_AD_B1_C1
endif

if !Sprite22_23_24_25       ; Vertical/horizontal net Koopas
org $01B950
    autoclean jml Sprite22_23_24_25
endif

if !Sprite3A_3B_3C_A5_A6    ; Urchins / Wall-following fuzzy/sparky / Hothead
org $01841B
    autoclean jml Sprite3A_3B_3C_A5_A6

org $0183FC
    autoclean jml SpiketopFix
endif

if !Sprite3E                ; P-Switch
org $01844E
    autoclean jsl Sprite3E
endif

if !Sprite63                ; Line-guided platform
org $01D6D2
    autoclean jsl Sprite63
    nop #2
endif

if !Sprite64                ; Line-guided rope mechanism
org $01D6C4
    autoclean jsl Sprite64  ; This is used for the sprite's clipping
    bra $01

org $01DC71
    autoclean jsl Sprite64  ; This is used for the sprite's graphics
    bne +
    lda #$05
    bra ++
org $01DC7C
    +
org $01DC7E
    ++

org $01DCC1
    autoclean jsl Sprite64  ; This is used for the sprite's graphics
    bne +
    lda #$04
    bra ++
warnpc $01DCCC
org $01DCCC
    +
org $01DCCE
    ++

endif

if !Sprite65_66_67_68       ; Line-guided chainsaw / grinder / fuzzy
org $01D6F0
    autoclean jsl Sprite65_66_67_68
endif

if !Sprite73                ; Super Koopa
org $018531
    autoclean jsl Sprite73
endif

if !Sprite8C                ; Fireplace smoke / Side exit
org $02F4DA
    autoclean jsl Sprite8C
endif

if !Sprite8F                ; Scale platforms
org $0183C0
    autoclean jsl Sprite8F
    nop #2
endif

if !Sprite94                ; Whistlin' Chuck
org $02C3A1
    autoclean jsl Sprite94
endif

if !Sprite9E_A3_E0          ; Ball and Chain / Grey platform on chain / 3 Platforms on chains
org $02D631
    autoclean jml Sprite9E_A3

org $02AF41
    autoclean jml SpriteE0_1

org $02AF59
    autoclean jml SpriteE0_2
endif

if !SpriteA4                ; Floating spike ball
org $01B21C
    autoclean jsl SpriteA4
endif

if !SpriteB9                ; Info box
org $038D87
    autoclean jsl SpriteB9
endif

if !SpriteBA                ; Timed lift
org $018328
    autoclean jsl SpriteBA
endif

;===============================;
; Code                          ;
;===============================;
freedata

if !Sprite09 || !Sprite1E_4D_4E_AD_B1_C1 || !Sprite3E || !Sprite63 || !Sprite64 || !Sprite65_66_67_68 || !Sprite73 || !Sprite8C || !Sprite8F || !Sprite94 || !SpriteA4 || !SpriteB9 || !SpriteBA
Sprite09:
Sprite1E_4D_4E_AD_B1_C1:
Sprite3E:
Sprite63:
Sprite64:
Sprite65_66_67_68:
Sprite73:
Sprite8C:
Sprite8F:
Sprite94:
SpriteA4:
SpriteB9:
SpriteBA:
    lda !extra_bits,x
    and #$04
    rtl
endif

if !Sprite22_23_24_25
Sprite22_23_24_25:
    ldy #$00
    lda !extra_bits,x
    and #$04
    jml $01B956|!bank
endif

if !Sprite3A_3B_3C_A5_A6
Sprite3A_3B_3C_A5_A6:
    ldy #$00
    lda !extra_bits,x
    and #$04
    asl #2
    jml $018421|!bank

; This is needed since the spiketop uses part of the Urchin's init and we overwrote it
SpiketopFix:
    ldy #$00
    phk
    pea.w .jslrtsreturn-1
    pea.w $0180CA|!bank-1
    jml $01841F|!bank
.jslrtsreturn
    stz !164A,x
    jml $01840E|!bank
endif

if !Sprite9E_A3_E0
Sprite9E_A3:
    ldy #$02
    lda !extra_bits,x
    and #$04
    jml $02D637|!bank

SpriteE0_1:
    lda #$02
    sta $04
    lda [$CE],y
    sta $0A
    jml $02AF45|!bank

SpriteE0_2:
    lda $00
    sta !E4,x
    lda $0A
    sta !extra_bits,x
    jml $02AF5D|!bank
endif
