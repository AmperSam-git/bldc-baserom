!level  = $010B|!addr   ;Patches rely on this, changing this is bad. Don't.
!level_flags = $140B|!addr; FreeRAM to activate certain UberASM code (cleared at level load)

macro RunCode(code_id, code)
    REP #$20
    LDA !level_flags
    AND.w #1<<<code_id>
    SEP #$20
    BEQ +
    JSR <code>
+
endmacro

ORG $05D8B7
    BRA +
    NOP #3      ;the levelnum patch goes here in many ROMs, just skip over it
+
    REP #$30
    LDA $0E
    STA !level
    ASL
    CLC
    ADC $0E
    TAY
    LDA.w $E000,Y
    STA $65
    LDA.w $E001,Y
    STA $66
    LDA.w $E600,Y
    STA $68
    LDA.w $E601,Y
    STA $69
    BRA +
ORG $05D8E0
    +

ORG $00A242
    autoclean JML main
    NOP

ORG $00A295
    NOP #4

ORG $00A5EE
    autoclean JML init

freecode

;Editing or moving these tables breaks things. don't.
db "uber"
level_asm_table:
level_init_table:
level_nmi_table:
level_load_table:
db "tool"

main:
    PHB
    LDA $13D4|!addr
    BNE +
    JSL $7F8000
+
    REP #$30
    LDA !level
    ASL
    ADC !level
    TAX
    LDA.l level_asm_table,x
    STA $00
    LDA.l level_asm_table+1,x
    JSL run_code
    JSR handle_main_codes
    PLB

    LDA $13D4|!addr
    BEQ +
    JML $00A25B|!bank
+
    JML $00A28A|!bank

init:
    PHB
    LDA !level
    ASL
    ADC !level
    TAX
    LDA.l level_init_table,x
    STA $00
    LDA.l level_init_table+1,x
    JSL run_code
    JSR handle_init_codes
    PLB

    PHK
    PEA.w .return-1
    PEA $84CE
    JML $00919B|!bank
.return
    JML $00A5F3|!bank

run_code:
    STA $01
    PHA
    PLB
    PLB
    SEP #$30
    JML [!dp]

null_pointer:
    RTL

handle_init_codes:
    LDA $71
    CMP #$0A
    BNE +
    JMP .Return
+
    print "Level init codes: $",pc
    %RunCode(9, counter_break)
    %RunCode(10, no_powerups)
.Return
    RTS

handle_main_codes:
    LDA $71
    CMP #$0A
    BNE +
    JMP .Return
+
    print "Level main codes: $",pc
    %RunCode(0, free_vertical_scroll)
    %RunCode(1, insta_death)
    %RunCode(2, horz_level_wrap)
    %RunCode(3, vert_level_wrap)
    %RunCode(4, block_left)
    %RunCode(5, block_right)
    %RunCode(6, block_up)
    %RunCode(7, block_down)
    %RunCode(8, enable_sfx_echo)
.Return
    RTS

free_vertical_scroll:
    lda #$01 : sta $1404|!addr
    RTS

enable_sfx_echo:
    LDA #$06 : STA $1DFA|!addr
    RTS

insta_death:
    LDA $71
    CMP #$01
    BNE +

    LDA #$36
    STA $1DFC|!addr
    JSL $00F606|!bank
+
    RTS

no_powerups:
    ; Reset powerup.
    stz $19
    ; Reset item box.
    stz $0DC2|!addr
    RTS

counter_break:
    ; Reset coin counter.
    stz $0DBF|!addr
    ; Reset bonus stars counter.
    stz $0F48|!addr
    stz $0F49|!addr
    ; Reset score counter.
    rep #$20
    stz $0F34|!addr
    stz $0F36|!addr
    stz $0F38|!addr
    sep #$20
    RTS

horz_level_wrap:
    LDA $9D
    BNE .noWrap
    JSR HorzWrapMario
    JSR HorzWrapSprites
  .noWrap
    RTS

vert_level_wrap:
    LDA $9D
    BNE .noWrap
    JSR VertWrapMario
    JSR VertWrapSprites
    .noWrap
    RTS

!wrap_topEdge = $00A0   ; where the "top" wrap point is
!wrap_botEdge = $01A0   ; where the "bottom" wrap point is


;; Code below this point ---------------------------------------
!horz_dist = !wrap_botEdge-!wrap_topEdge


HorzWrapMario:
    LDA $13E0|!addr     ; don't wrap if dead
    CMP #$3E
    BEQ .noWrap
    REP #$20
    LDA $96
    CMP #!wrap_botEdge
    BMI .checkAbove
    SEC : SBC #!horz_dist
    STA $96
    BRA .noWrap
  .checkAbove
    CMP #!wrap_topEdge
    BPL .noWrap
    CLC : ADC #!horz_dist
    STA $96
  .noWrap
    SEP #$20
    RTS


HorzWrapSprites:
    LDX #!sprite_slots-1
  .loop
    LDA !14C8,x
    BEQ .skip
    CMP #$02
    BEQ .skip
    LDA !14D4,x
    XBA
    LDA !D8,x
    REP #$20
    CMP #!wrap_botEdge
    BMI .checkAbove
    SEC : SBC #!horz_dist
    SEP #$20
    STA !D8,x
    XBA
    STA !14D4,x
    BRA .skip
  .checkAbove
    CMP #!wrap_topEdge
    BPL .skip
    CLC : ADC #!horz_dist
    SEP #$20
    STA !D8,x
    XBA
    STA !14D4,x
  .skip
    SEP #$20
    DEX
    BPL .loop
    RTS

!wrap_leftEdge   = $0010        ; where to actually wrap Mario, on the left
!wrap_rightEdge  = $0120        ; where to actually wrap Mario, on the right

!vert_dist = !wrap_rightEdge-!wrap_leftEdge

VertWrapMario:
    REP #$20
    LDA $94
    CMP #!wrap_rightEdge
    BMI .checkLeft
    SEC : SBC #!vert_dist
    STA $94
    BRA .noWrap
  .checkLeft
    CMP #!wrap_leftEdge
    BPL .noWrap
    CLC : ADC #!vert_dist
    STA $94
  .noWrap
    SEP #$20
    RTS


VertWrapSprites:
    LDX #!sprite_slots-1
  .loop
    LDA !14C8,x
    BEQ .skip
    LDA !14E0,x
    XBA
    LDA !E4,x
    REP #$20
    CMP #!wrap_rightEdge
    BMI .checkLeft
    SEC : SBC #!vert_dist
    SEP #$20
    STA !E4,x
    XBA
    STA !14E0,x
    BRA .skip
  .checkLeft
    CMP #!wrap_leftEdge
    BPL .skip
    CLC : ADC #!vert_dist
    SEP #$20
    STA !E4,x
    XBA
    STA !14E0,x
  .skip
    SEP #$20
    DEX
    BPL .loop
    RTS

block_left:
    LDY #$00
    REP #$20
    STY $1401|!addr
    LDA $7E
    CMP $142A|!addr
    SEP #$20
    BMI +
    INY
+
    STY $1411|!addr
    RTS

block_right:
    LDY #$00
    REP #$20
    STY $1401|!addr
    LDA $7E
    CMP $142A|!addr
    SEP #$20
    BPL +
    INY
+
    STY $1411|!addr
    RTS

block_up:
    LDY #$00
    REP #$20
    LDA $80
    CMP #$0070
    SEP #$20
    BMI +
    INY
+
    STY $1412|!addr
    RTS

block_down:
    LDY #$00
    REP #$20
    LDA $80
    CMP #$0070
    SEP #$20
    BPL +
    INY
+   STY $1412|!addr
    RTS