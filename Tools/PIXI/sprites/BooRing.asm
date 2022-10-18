;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Boo Ring
; by 33953YoShI (Akaginite)
;
; IMPORTANT NOTE:
; - This sprite requires the No More Sprite Tile Limits patch.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Uses first extra bit: YES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Extra Bit:    Rotation direction (clockwise, counter-clockwise)
; Extra Byte 1: Number of Boos ($0A: vanilla)
; Extra Byte 2: Space between each Boo ($28: vailla)
; Extra Byte 3: Radius ($50: vanilla)
; Extra Byte 4: Speed ($10: vanilla)
; 
; Extension 0A285010 recreates the original Boo Ring.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!DispX = $03
!DispY = $03
!Width = $0A
!Height = $0A

if !SA1 == 0
    !Buffer = $0100
else
    !Buffer = $3700
endif

!GetSin = $07F7DB|!BankB
!GetCos = $07F7DB|!BankB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
    LDA !extra_byte_3,x
    STA !187B,x
    LDA !extra_byte_4,x
    STA !1504,x
    %BEC(+)
        LDA !1504,x
        EOR #$FF : INC A
        STA !1504,x
+   STZ !1510,x
    STZ !151C,x
    STZ !1528,x
    LDA !extra_byte_2,x
    STA !1602,x
    LDA #$00
    STA !extra_byte_2,x
    RTL

print "MAIN ",pc
    PHB : PHK : PLB
    JSR SpriteCode
    PLB
    RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Makes sure sublabels work.
; If a shared subroutine is used for the first time (among all sprites), it changes
; the main label, which breaks sublabels.
; This ensures that won't happen.
%SubOffScreen()

SpriteCode:
lda #$3C                ; find or queue ExGFX
%FindAndQueueGFX()
bcs gfx_loaded
rts                      ; don't draw gfx if ExGFX isn't ready
gfx_loaded:
    JSR GetDrawInfo
    LDA $9D
    BNE .Start
    LDA #$05
    %SubOffScreen()
    LDA !1504,x
    TAY
    ASL #4
    CLC : ADC !1510,x
    STA !1510,x
    TYA
    PHP
    LSR #4
    LDY #$00
    PLP
    BPL .IfPlus
    ORA #$F0
    DEY
.IfPlus
    ADC !151C,x
    STA !151C,x
    TYA
    ADC !1528,x
    AND #$01
    STA !1528,x
.Start
    if !SA1 == 0
        LDA !151C,x
        STA $04
        LDA !1528,x
        STA $05
        LDA !187B,x
        STA $0C
        STA $4202
    else
        STZ $2250
        LDA !151C,x
        STA $0E
        LDA !1528,x
        STA $0F
    endif

    LDA !extra_byte_1,x
    DEC A
    AND #$3F

    if !SA1 == 0
        STA $0D
        STA $0F
        TAY
    else
        STA $3110
        STA $0C
        STZ $0D
    endif

    LDA !E4,x
    STA $08
    LDA !14E0,x
    STA $09
    LDA !D8,x
    STA $0A
    LDA !14D4,x
    STA $0B
    LDA !1602,x

    if !SA1 == 0
        STA $06
        STZ $07
        REP #$30
    .PositionLoop
        LDA $04
        STA $00
    else
        STA $00
        STZ $01
        LDA !187B,x
        REP #$30
        AND.w #$00FF
        STA $2251
    .PositionLoop
        LDA $0E
    endif

    CLC : ADC.w #$0080
    AND.w #$01FF

    if !SA1 == 0
        STA $02
    else
        TAY
    endif

    AND.w #$00FF
    ASL A
    TAX
    LDA.l !GetCos,x

    if !SA1 == 0
        CMP.w #$0100
        AND.w #$00FF
        SEP #$30
        STA $4203
        LDX $00        ; pre-load angle
        LDA $0C
        BCS .SkipCos
        ASL $4216
        LDA $4217
        ADC #$00
    .SkipCos
        LSR $03
        REP #$30
    else
        CPY.w #$0100
    endif

    BCC .NotNegCos
    EOR.w #$FFFF

    if !SA1 == 0
    .NotNegCos
        ADC $08
        PHA

        TXA
    else
        INC A
    .NotNegCos
        STA $2253

        LDA $0E
        TAY
        AND.w #$00FF
    endif

    ASL A
    TAX

    if !SA1 == 0
        LDA.l !GetSin,x
        CMP.w #$0100
        AND.w #$00FF
        SEP #$30
        STA $4203
        LDA $0C
        BCS .SkipSin
        LDA $0C        ; wait 3 cycles...
        ASL $4216
        LDA $4217
        ADC #$00
    .SkipSin
        LSR $01
        REP #$30
        BCC .NotNegSin
        EOR.w #$FFFF
    .NotNegSin
        ADC $0A
        PHA

        LDA $04
        CLC : ADC $06
        AND.w #$01FF
        STA $04
        DEY
        BPL .PositionLoop

    .LoopEnd
        SEP #$30
        LDX $15E9|!Base2
        LDA !15C4,x
        BNE +
            JSR SubGFX
+       LDA $71
        BNE .PullLoop
    else
        LDA $2305
        ASL A
        LDA $2307
        ADC $08
        PHA
        LDA.l !GetSin,x
        CPY.w #$0100
        BCC .NotNegSin
        EOR.w #$FFFF
        INC A
        CLC
    .NotNegSin
        STA $2253

        LDA $0E
        ADC $00
        AND.w #$01FF
        STA $0E

        LDA $2305
        ASL A
        LDA $2307
        ADC $0A
        PHA

        DEC $0C
        BPL .PositionLoop
        SEP #$30
    .LoopEnd
        LDX $15E9|!Base2
        LDA $3110
        STA $0D
        LDY !15C4,x
        BNE +
            STA $0F
            JSR SubGFX
+       LDA $71
        BNE .PullLoop
    endif

    LDA $13F9|!Base2
    EOR !1632,x
    BEQ .GetCollision
.PullLoop
    REP #$20
    LDA $0D
    INC A
    AND.w #$00FF
    ASL #2
    STA $0D
    TSC
    ADC $0D
    TCS
    SEP #$20
    RTS

.GetCollision
    LDA.b #!Width
    STA $06
    LDA.b #!Height
    STA $07
    JSL $03B664|!BankB

.CollisionLoop
    LDA $0D
    EOR $14
    LSR A
    BCC .PullNext
    LDA $94
    SBC $03,s
    CLC : ADC #$20
    CMP #$40
    BCS .PullNext
    LDA $96
    ADC #$18
    SEC : SBC $01,s
    CMP #$60
    BCS .PullNext
    PLA
    PLY
    ADC.b #!DispY
    STA $05
    BCC +
        INY
        CLC
+   STY $0B
    PLA
    PLY
    ADC.b #!DispX
    STA $04
    BCC +
        INY
+   STY $0A
    JSL $03B72B|!BankB
    BCC .Next
    LDA $1497|!Base2
    ORA $1490|!Base2
    BNE .Next
    LDA $187A|!Base2
    BEQ +
        JSR LoseYoshi
        BRA .Next

+   JSL $00F5B7|!BankB
    BRA .Next

.PullNext
    PLA
    PLA
    PLA
    PLA
.Next
    DEC $0D
    BPL .CollisionLoop
    RTS

LoseYoshi:
    LDX $18E2|!Base2
    DEX
    BMI +
    LDA #$10
    STA !163E,x
    LDA #$03
    STA $1DFA|!Base2
    LDA #$13
    STA $1DFC|!Base2
    LDA #$02
    STA !C2,x
    STZ $187A|!Base2
    STZ $0DC1|!Base2
    LDA #$C0
    STA $7D
    STZ $7B
    LDY !157C,x
    LDA .SetXspeed,y
    STA !B6,x
    STZ !1594,x
    STZ !151C,x
    STZ $18AE|!Base2
    LDA #$30
    STA $1497|!Base2
+   LDX $15E9|!Base2
    RTS

.SetXspeed
    db $20,$E0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TileMap:
    db $05,$04
    db $01,$00
    db $01,$00
    db $02,$03

SubGFX:

    LDA $14
    LSR #3
    AND #$01
    
    if !SA1 == 0
        TAY
    else
        STA $05
    endif

    LDA !15F6,x
    ORA $64
    EOR #$40
    STA $04

    if !SA1 == 0
        STZ $2183
        LDA #$03
        STA $2182
        LDA !15EA,x
        STA $2181
        LSR #2
        ADC #$60
        STA $02
        LDA #$04
        STA $03
    else
        LDA !15EA,x
        STA $06
        LSR #2
        ADC #$60
        STA $02
        LDA #$64
        STA $03
    endif

    TSX
.Loop
    REP #$21
    LDA !Buffer+$03,x
    ADC.w #$000F
    SEC : SBC $1C
    CMP.w #$00EF
    BCS .Next
    STA $00
    LDA !Buffer+$05,x
    ADC.w #$000F
    SEC : SBC $1A

    if !SA1 == 0
        CMP.w #$011F
    else
        CMP.w #$010F
    endif

    BCS .Next
    SBC.w #$000E
    SEP #$21
    if !SA1 == 0 : STA $2180
    XBA
    AND #$01
    ORA #$02
    STA ($02)
    INC $02

    if !SA1 == 0
        LDA $00
        SBC #$0F
        STA $2180
        LDA.w TileMap,y
        STA $2180
        LDA $04
        STA $2180
    else
        LDY $05
        LDA.w TileMap,y
		PHX
		TAX
		LDA !dss_tile_buffer,x
		PLX
        LDY $06
        STA $0302|!Base2,y
        LDA $04
        STA $0303|!Base2,y
        LDA $00
        SBC #$0F
        REP #$21
        XBA
        STA $0300|!Base2,y
        TYA
        ADC.w #$0004
        STA $06
    endif
.Next
    SEP #$21
    TXA             ;\ 
    ADC #$03        ; | X += 4
    TAX             ;/

    if !SA1 == 0
        TYA
        ADC #$02
        AND #$07
        TAY
    else
        LDA $05
        ADC #$02
        AND #$07
        STA $05
    endif

    DEC $0F
    BPL .Loop
    LDX $15E9|!Base2
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetDrawInfo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DON'T REPLACE WITH SHARED ROUTINE.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDrawInfo:
    LDA !E4,x
    CMP $1A
    LDA !14E0,x
    SBC $1B
    BEQ .OnScreenX
    LDA #$01
.OnScreenX
    STA !15A0,x

    LDA !14E0,x
    PHA
    LDA !E4,x
    PHA
    LDY !187B,x
    REP #$20
    TYA
    STA $00
    ASL A
    ADC.w #$0110
    STA $02
    PLA
    ADC $00
    CLC
    ADC.w #$0010
    SEC
    SBC $1A
    CMP $02
    SEP #$20
    TDC
    ROL A
    STA !15C4,x
    BNE .Invalid

    LDA !14D4,x
    XBA
    LDA !D8,x
    REP #$21
    ADC.w #$000C
    SEC : SBC $1C
    SEP #$20
    XBA
    BEQ .OnScreenY
    LDA #$01
.OnScreenY
    STA !186C,x
.Invalid
    RTS
