!level	= $010B|!addr	;Patches rely on this, changing this is bad. Don't.

!level_flags = $140B|!addr; FreeRAM to activate certain UberASM code (cleared at level load)
!lr_reset = $140C|!addr ; FreeRAM to handle L&R reset

; OHKO defines
!ohko_death_sfx = $20

macro RunCode(code_id, code)
	LDA !level_flags
	AND.b #1<<<code_id>
	BEQ +
	JSR <code>
+
endmacro

ORG $05D8B7
	BRA +
	NOP #3		;the levelnum patch goes here in many ROMs, just skip over it
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
RTS

handle_main_codes:
    LDA $71
    CMP #$0A
	BEQ .Return
	print "Level codes: $",pc
	%RunCode(0, free_vert_scroll)
	%RunCode(1, insta_death)
	%RunCode(2, horz_level_wrap)
	%RunCode(3, vert_level_wrap)
	%RunCode(4, block_left)
	%RunCode(5, block_right)
	%RunCode(6, block_up)
	%RunCode(7, block_down)
	
	LDX !lr_reset
	BEQ .Return
	JMP (lr_ptrs-2,x)
.Return
RTS

free_vert_scroll:
	lda #$01
    sta $1404|!addr
RTS

insta_death:
	LDA $71
	CMP #$01
	BNE +

	LDA #!ohko_death_sfx
	STA $1DF9|!addr
	JSL $00F606|!bank
+
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

!wrap_topEdge = $00A0	; where the "top" wrap point is
!wrap_botEdge = $01A0	; where the "bottom" wrap point is


;; Code below this point ---------------------------------------
!horz_dist = !wrap_botEdge-!wrap_topEdge


HorzWrapMario:
	LDA $13E0|!addr		; don't wrap if dead
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

!wrap_leftEdge   = $0010		; where to actually wrap Mario, on the left
!wrap_rightEdge  = $0120		; where to actually wrap Mario, on the right

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
+	STY $1412|!addr
RTS

!EXLEVEL = 0
if (((read1($0FF0B4)-'0')*100)+((read1($0FF0B4+2)-'0')*10)+(read1($0FF0B4+3)-'0')) > 253
	!EXLEVEL = 1
endif

lr_ptrs:
dw lr_translevel
dw lr_current
dw lr_midpoint


lr_translevel:
    STZ $0D
    LDA $13BF|!addr
    CMP #$25
    BCC +
    SEC
    SBC #$24
    INC $0D
  +
    STA $0C
    JSR LRReset
    RTS

lr_current:
    LDA $010B|!addr
    STA $0C
    LDA $010C|!addr
    STA $0D
    JSR LRReset
    RTS

lr_midpoint:
    LDY #$00
    LDA $13CE|!addr
    BNE ++
    LDX $13BF|!addr
    BIT $1EA2|!addr,x
    BVC +
 ++ LDY #$0C
  +
    LDA $13BF|!addr
    CMP #$25
    BCC +
    SEC
    SBC #$24
    INY
  +
    STY $0D
    STA $0C
    JSR LRReset
    RTS

!timeToPlayDeathSFX     =   $1B

; Sound effect for resetting.
!resetSound     = $2A
!resetPort      = $1DFC

!arg1 = $0C
!arg2 = $0D

LRReset:
    LDA $17
    AND #$30
    CMP #$30
    BEQ .reloadLR       ; L+R pressed
  .return
    RTS

  .reloadLR
    LDA $71
    SEC : SBC #$09
    ORA $1493|!addr ; don't allow L+R reset on level end
    ORA $13D4|!addr ; ...or game paused
    ORA $1B89|!addr ; ...or message box
    BNE .return
    JSL $00F614|!bank     ; kill mario
  .reload
    LDA #!resetSound
    STA !resetPort|!addr
    
    STZ $1B93|!addr ; reload specified sublevel
if !EXLEVEL
	JSL $03BCDC|!bank
else
	LDA $5B
	AND #$01
	ASL 
	TAX 
	LDA $95,x
	TAX
endif
    LDA !arg1
    STA $19B8|!addr,x
    LDA !arg2
    STA $19D8|!addr,x
    LDA #$06
    STA $71
    STZ $88
    STZ $89
    
    STZ $1496|!addr ; clear death timer
    STZ $1493|!addr ; clear end level timer
    STZ $1497|!addr ; clear invulnerability timer
    
    REP #$20
    STZ $148B|!addr ; clear rng
    STZ $0FAE|!addr ; clear boo ring angles
    STZ $0FB0|!addr
    SEP #$20

    STZ $0DC1|!addr ; clear yoshi
    STZ $18E2|!addr
    STZ $19         ; clear powerup
    STZ $0DC2|!addr ; clear item box
    STZ $14AF|!addr ; clear on/off switch
    STZ $1432|!addr ; clear directional coin flag

    LDA $13BE|!addr ; clear item memory
    CMP #$03
    BCS .noTrack
    ASL
    TAX
    REP #$21
    LDA $00BFFF|!bank,x
    ADC #$19F8
    STA $00
    LDA #$0000
    LDY #$80
  .clearLoop
    STA ($00),y
    DEY
    DEY
    BPL .clearLoop
    SEP #$20
  .noTrack
RTS
