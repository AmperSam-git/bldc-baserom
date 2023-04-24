;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Falling Icicle
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite main code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!GFX_FileNum = $A5 ; DSS ExGFX

print "MAIN ",pc
    PHB
    PHK
    PLB
    JSR FallingSpike
    PLB

print "INIT ",pc
    RTL

Tilemap:
    db $00,$01
YDisp:
    db $EF,$FF


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite code JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FallingSpike:
    JSR SubGFX           ; Draw sprite
    LDA $9D              ;\ Fall if sprites locked..?
    BNE Fall             ;/
    JSL $01802A          ; Update speed
	LDA !C2,x            ;\ Branch to fall code based on state
	BNE Fall             ;/
    JSR SubOffscreen0Bnk3
    STZ !AA,x            ; Freeze the sprite
    JSR SubHorzPosBnk3
	XBA
    LDA $0F              ;\
	REP #$20
    CLC                  ; |
    ADC #$0040             ; | If player not near enough of sprite, return
    CMP #$0080             ; |
	SEP #$20
    BCS Return           ;/
    INC !C2,x            ; Increase sprite state
    LDA #$40             ;\ Set a timer
    STA !1540,x          ;/
Return:
    RTS

Fall:
    LDA !1540,x          ;\ If timer not done yet, freeze sprite
    BNE Freeze           ;/
    JSL $01A7DC          ; Interact with the player
    LDA !1588,x          ;\ If not touching the ground, return
    AND #$04             ; |
    BEQ Return           ;/
	LDA !E4,x	;\
	STA $9A		; |
	LDA !14E0,x	; |
	STA $9B		; | Set coords (from 02E476 in all.log)
	LDA !D8,x	; |
	STA $98		; |
	LDA !14D4,x	; |
	STA $99		;/
    PHB                  ; Preserve data bank
    LDA #$02             ;\
    PHA                  ; | Set new data bank
    PLB                  ;/
    LDA #$FF             ;\ Randomly replace the shatter with a flashing one
    JSL $028663          ;/
    PLB                  ; Retrieve data bank
    STZ !14C8,x          ; Kill sprite
    BRA Return

Freeze:
    STZ !AA,x            ; Freeze the sprite
    BRA Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sub Horizontal Position Bank 3
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubHorzPosBnk3:     LDY #$00
                    LDA $94
                    SEC
                    SBC !E4,X
                    STA $0F
                    LDA $95
                    SBC !14E0,X
                    BPL Return03B828
                    INY
Return03B828:       RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sprite Graphics Routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubGFX:
    lda #!GFX_FileNum
    %FindAndQueueGFX()
    bcs .gfx_loaded
    rts
.gfx_loaded
    %GetDrawInfo()
    PHX
    LDX #$01
Loop:
    PHX

    LDA $00
    STA $0300|!Base2,y

    LDA $01
    CLC
    ADC YDisp,x
    STA $0301|!Base2,y

    PHX
    LDA Tilemap,x
    TAX
    lda.l !dss_tile_buffer,x
    PLX
    STA $0302|!Base2,y

    LDX $15E9|!Base2
    LDA !1540,x
    BEQ .NoShaking
    LSR
    LSR
    AND #$01
    CLC
    ADC $0300|!Base2,y
    STA $0300|!Base2,y
.NoShaking
    LDA !15F6,x
    ORA $64
    STA $0303|!Base2,y
    PLX

    INY #4
    DEX
    BPL Loop

    PLX
    LDY #$02
    LDA #$01
    JSL $01B7B3
    RTS

DATA_03B83B:                      db $40,$B0
DATA_03B83D:                      db $01,$FF
DATA_03B83F:                      db $30,$C0,$A0,$80,$A0,$40,$60,$B0
DATA_03B847:                      db $01,$FF,$01,$FF,$01,$00,$01,$FF
SubOffscreen0Bnk3:   STZ $03                     ; /
                    JSR IsSprOffScreenBnk3      ; \ if sprite is not off screen, return
                    BEQ RETURNONE               ; /
                    LDA $5B                     ; \  vertical level
                    AND #$01                    ;  |
                    BNE VerticalLevelBnk3       ; /
                    LDA !D8,X                   ; \
                    CLC                         ;  |
                    ADC #$50                    ;  | if the sprite has gone off the bottom of the level...
                    LDA !14D4,X                 ;  |
                    ADC #$00                    ;  |
                    CMP #$02                    ;  |
                    BPL OffScrEraseSprBnk3      ; /    ...erase the sprite
                    LDA !167A,X                 ; \ if "process offscreen" flag is set, return
                    AND #$04                    ;  |
                    BNE RETURNONE               ; /
                    LDA $13
                    AND #$01
                    ORA $03
                    STA $01
                    TAY
                    LDA $1A
                    CLC
                    ADC DATA_03B83F,Y
                    ROL $00
                    CMP !E4,X
                    PHP
                    LDA $1B
                    LSR $00
                    ADC DATA_03B847,Y
                    PLP
                    SBC !14E0,X
                    STA $00
                    LSR $01
                    BCC CODE_03B8A8
                    EOR #$80
                    STA $00

CODE_03B8A8:        LDA $00
                    BPL RETURNONE

OffScrEraseSprBnk3: LDA !14C8,X                 ; \ If sprite status < 8, permanently erase sprite
                    CMP #$08                    ;  |
                    BCC OffScrKillSprBnk3       ; /
                    LDY !161A,X                 ; \ Branch if should permanently erase sprite
                    CPY #$FF                    ;  |
                    BEQ OffScrKillSprBnk3       ; /
                    PHX
                    TYX
                    LDA #$00                    ; \ Allow sprite to be reloaded by level loading routine
                    STA !1938,X                 ; /
                    PLX
OffScrKillSprBnk3:  STZ !14C8,X

RETURNONE:          RTS                         ; Return

VerticalLevelBnk3:  LDA !167A,X                 ; \ If "process offscreen" flag is set, return
                    AND #$04                    ;  |
                    BNE RETURNONE               ; /
                    LDA $13                     ; \ Return every other frame
                    LSR                         ;  |
                    BCS RETURNONE               ; /
                    AND #$01
                    STA $01
                    TAY
                    LDA $1C
                    CLC
                    ADC DATA_03B83B,Y
                    ROL $00
                    CMP !D8,X
                    PHP
                    LDA $1D
                    LSR $00
                    ADC DATA_03B83D,Y
                    PLP
                    SBC !14D4,X
                    STA $00
                    LDY $01
                    BEQ CODE_03B8F5
                    EOR #$80
                    STA $00

CODE_03B8F5:        LDA $00
                    BPL RETURNONE
                    BMI OffScrEraseSprBnk3

IsSprOffScreenBnk3: LDA !15A0,X                 ; \ If sprite is on screen, A = 0
                    ORA !186C,X                 ;  |
                    RTS                         ; / Return