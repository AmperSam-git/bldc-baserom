;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Customizable Moving Hole by dtothefourth
;
; A version of the moving ghost house hole with added options
;
; Uses 4 extra bytes, set as follows:
; 
; SP TT WD DD
;
;	SP - Speed
;	TT - Turn Time - How many frames before changing direction
;	WD
;		W - Width of hole in tiles (1-6 recommended, doesn't cound the end tiles, 1 is vanilla)
;		D - Depth of hole in tiles (1-6 recommended)
;
;	DD - Direction 0=horizontal, 1=vertical
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


!ForceBack = 1		 ;0 = normal, 1 = try to force behind all other sprites (Requires no more sprite tile limits to be applied and active)

;Horizontal Graphics
Tiles:   db $01,$00,$01
Props:   db $71,$31,$31

;Vertical Graphics
TilesV:   db $02,$00,$02
PropsV:   db $31,$31,$B1




print "INIT ",pc


	if !ForceBack
	TXA
	CMP #$00
	BNE ++
	JMP +
	++
	
	LDY #$00
	LDA !14C8 
	BEQ ++

	TXA
	CMP #$01
	BNE ++
	JMP +
	++
	
	LDY #$01
	LDA !14C8+1 
	BEQ ++

	JMP +
	++



	LDA !7FAB9E,x
	PHX
	TYX
	STA !7FAB9E,x
	PLX

	LDA !7FAB10,x
	STA $00
		
	LDA !E4,x
	STA !E4,y
	LDA !14E0,x
	STA !14E0,y
	LDA !D8,x
	STA !D8,y	
	LDA !14D4,x
	STA !14D4,y	
	PHX
	TYX
	LDA $00
	PHA
	JSL $07F7D2|!BankB
	PLA
	STA !7FAB10,x
	JSL $0187A7|!BankB
	PLX

	LDA #$01
	STA !14C8,y

	STZ !14C8,x		

	LDA !161A,x
	STA !161A,y
	LDA #$FF
	STA !161A,x

	LDA !extra_byte_1,x
	STA $00
	LDA !extra_byte_2,x
	STA $01
	LDA !extra_byte_3,x
	STA $02
	LDA !extra_byte_4,x
	STA $03

	PHX
	TYX
	LDA $00
	STA !extra_byte_1,x
	LDA $01
	STA !extra_byte_2,x
	LDA $02
	STA !extra_byte_3,x
	LDA $03
	STA !extra_byte_4,x
	PLX

	RTL
	+
	endif

	LDA !D8,x
	SEC
	SBC #$01
	STA !D8,x
	LDA !14D4,x
	SBC #$00
	STA !14D4,x

	LDA !extra_byte_4,x
	AND #$0F
	BNE +

	LDA !extra_byte_1,x
	STA !B6,x
	RTL
	+
	LDA !extra_byte_1,x
	STA !AA,x	

	RTL	

print "MAIN ",pc
	PHB
	PHK
	PLB
	JSR Main
	PLB
	RTL

Main:
  	LDA !extra_byte_3,x
	AND #$F0
	CMP #$30
	BCC ++
    LDA !14E0,x
    XBA
    LDA !E4,x
    REP #$20
    SEC
    SBC $1A
    CLC
    ADC #$0100
    CMP #$0300
    SEP #$20
    BCC +
    STZ !14C8,x
    PHX
    LDA !161A,x
    TAX
    LDA #$00
    STA !1938,x
    PLX
    +
    LDA !14D4,x
    XBA
    LDA !D8,x
    REP #$20
    SEC
    SBC $1C
    CLC
    ADC #$0100
    CMP #$0300
    SEP #$20
    BCC +++
    STZ !14C8,x
    PHX
    LDA !161A,x
    TAX
    LDA #$00
    STA !1938,x
    PLX
	BRA +++
    ++
    LDA #$04
    %SubOffScreen() 
    +++

	LDA $9D   		
	BNE Locked 

	JSR Movement

Locked:
	LDA !extra_byte_4,x
	AND #$0F
	BNE +
	JSR GFX
	BRA ++
	+
	JSR GFXV
	++
	        
	JSR SpriteInteract      
	LDA $185C|!Base2            
	BEQ CheckMario
	DEC A			                     
	CMP $15E9|!Base2               
	BNE Return          
CheckMario:

	JSL $03B664|!BankB
	JSL $03B69F|!BankB

	JSR UpdateHitbox

	LDA !extra_byte_4,x
	AND #$0F
	BNE +

	LDA $7D
	BPL ++
	LDA $07
	CLC
	ADC #$0A
	STA $07
	BRA +++
	+
	LDA $07
	CLC
	ADC #$04
	STA $07
	
	++	

	LDA $05
	SEC
	SBC #$04
	STA $05
	LDA $0B
	SBC #$00
	STA $0B

	+++
	JSL $03B72B|!BankB


	STZ $185C|!Base2              
	BCC Return          
	INX              
	STX $185C|!Base2   
	DEX

	LDA !extra_byte_4,x
	AND #$0F
	BEQ +

	JSR PlatformV
	RTS

	+
	JSR Platform


Return:
	RTS

GFX:

    LDA !14E0,x
    XBA
    LDA !E4,x
    REP #$20
    SEC
    SBC $1A
    CMP #$0100
    SEP #$20
    BMI +
    BCC ++
    -
	RTS
    +
	REP #$20
	CLC
	ADC #$0080
	SEP #$20
	BMI -
	++
    LDA !14D4,x
    XBA
    LDA !D8,x
    REP #$20
    SEC
    SBC $1C
    CMP #$00E0
    SEP #$20
    BMI +
    BCC +
    RTS
    + 

	LDA !14E0,x
	PHA
	XBA
	LDA !E4,x
	PHA

	STZ $0C


	REP #$20
	SEC
	SBC $1A
	SEP #$20

	BPL +

	LDA !extra_byte_3,x
	AND #$F0
	LSR
	STA $0C
	CLC
	ADC !E4,x
	STA !E4,x
	LDA !14E0,x
	ADC #$00
	STA !14E0,x

	+
	lda #$6E        ; find or queue GFX
	%FindAndQueueGFX()
	bcs .gfx_loaded
	rts                      ; don't draw gfx if ExGFX isn't ready	
.gfx_loaded
	JSR GetDrawInfo   
 
	LDA #$FF
	STA $0F

	LDA $00
	SEC
	SBC $0C
	STA $00
	STA $0D

	LDA !extra_byte_3,x
	AND #$0F
	DEC
	STA $0E

	--

	LDA $00            
	STA $0300|!Base2,Y        
	LDA $01                   
	STA $0301|!Base2,Y 	
	PHX
	LDX Tiles
	lda !dss_tile_buffer,x
	PLX
	STA $0302|!Base2,Y   
	LDA Props 
	STA $0303|!Base2,Y     
	INY #4 

	LDA $00
	CLC
	ADC #$10
	STA $00

	INC $0F

	PHX  

	LDA !extra_byte_3,x
	AND #$F0
	LSR #4
	TAX
	
	DEX  
	-   

	LDA $00            
	STA $0300|!Base2,Y        
	LDA $01                   
	STA $0301|!Base2,Y 	     
	PHX
	LDX Tiles+1
	lda !dss_tile_buffer,x
	PLX
	STA $0302|!Base2,Y   
	LDA Props+1
	STA $0303|!Base2,Y     
	INY #4   

	LDA $00
	CLC
	ADC #$10
	STA $00

	INC $0F

	DEX 		                  
	BPL -        
	PLX    

	
	LDA $00            
	STA $0300|!Base2,Y        
	LDA $01                   
	STA $0301|!Base2,Y 	     
	PHX
	LDX Tiles+2
	lda !dss_tile_buffer,x
	PLX
	STA $0302|!Base2,Y   
	LDA Props+2
	STA $0303|!Base2,Y     
	INY #4   

	INC $0F

	LDA $01
	CLC
	ADC #$10
	STA $01

	LDA $0D
	STA $00

	DEC $0E
	BMI +
	JMP --
	+

	LDA $0F         
	LDY #$02   
	JSL $01B7B3|!BankB

	PLA
	STA !E4,x
	PLA
	STA !14E0,x


	RTS         


GFXV: 
	lda #$6E        ; find or queue GFX
	%FindAndQueueGFX()
	bcs .gfx_loaded2
	rts                      ; don't draw gfx if ExGFX isn't ready	
.gfx_loaded2                     
	JSR GetDrawInfo   
 
	LDA #$FF
	STA $0F

	LDA $01
	STA $0D

	LDA !extra_byte_3,x
	AND #$0F

	DEC
	STA $0E

	--

	LDA $00            
	STA $0300|!Base2,Y        
	LDA $01                   
	STA $0301|!Base2,Y 	     
	PHX
	LDX TilesV
	lda !dss_tile_buffer,x
	PLX
	STA $0302|!Base2,Y   
	LDA PropsV 
	STA $0303|!Base2,Y     
	INY #4 

	LDA $01
	CLC
	ADC #$10
	STA $01

	INC $0F

	PHX  
	LDA !extra_byte_3,x
	AND #$F0
	LSR #4
	TAX
	DEX  
	-   

	LDA $00            
	STA $0300|!Base2,Y        
	LDA $01                   
	STA $0301|!Base2,Y 	     
	PHX
	LDX TilesV+1
	lda !dss_tile_buffer,x
	PLX
	STA $0302|!Base2,Y   
	LDA PropsV+1
	STA $0303|!Base2,Y     
	INY #4   

	LDA $01
	CLC
	ADC #$10
	STA $01

	INC $0F

	DEX 		                  
	BPL -        
	PLX    

	
	LDA $00            
	STA $0300|!Base2,Y        
	LDA $01                   
	STA $0301|!Base2,Y 	     
	PHX
	LDX TilesV+2
	lda !dss_tile_buffer,x
	PLX
	STA $0302|!Base2,Y   
	LDA PropsV+2
	STA $0303|!Base2,Y     
	INY #4   

	INC $0F

	LDA $00
	CLC
	ADC #$10
	STA $00

	LDA $0D
	STA $01

	DEC $0E
	BMI +
	JMP --
	+

	LDA $0F         
	LDY #$02   
	JSL $01B7B3|!BankB
	RTS       

print "sprite ",pc

SpriteInteract:
	JSL $03B69F|!BankB

	JSR UpdateHitbox




	LDY #!SprSize-1   
	-             
	CPY $15E9|!Base2     
	BNE +     
	JMP Next
	+          
	TYA                       
	;EOR $13      
	;AND #$03                
	;BNE Next           
	LDA !14C8,Y             
	CMP #$08                
	BCC Next
	LDA !1686,Y
	BMI Next           
	LDA !15DC,Y             
	BEQ HitCheck           
	DEC A                     
	CMP $15E9|!Base2               
	BNE Next           
HitCheck:

	

	LDA $05
	PHA
	LDA $0B
	PHA
	LDA $07
	PHA

	LDA !extra_byte_4,x
	AND #$0F
	BNE ++

	LDA !AA,Y
	BMI +

	LDA $05
	SEC
	SBC #$04
	STA $05
	LDA $0B
	SBC #$00
	STA $0B

	LDA $07
	SEC
	SBC #$03
	STA $07
	BRA ++
	+
	LDA $07
	CLC
	ADC #$08
	STA $07
	++

	TYX                       
	JSL $03B6E5|!BankB
	LDX $15E9|!Base2

	JSL $03B72B|!BankB
	LDA #$00          
	STA !15DC,Y 
	BCC NextPre       
	TXA                       
	INC A                    
	STA !15DC,Y

	JSR PlatformSpr

NextPre:
	PLA
	STA $07
	PLA
	STA $0B
	PLA
	STA $05

Next:
	DEY                       
	BMI + 
	JMP -
	+           
	RTS

UpdateHitbox:

	LDA !extra_byte_4,x
	AND #$0F
	BNE +

	LDA !extra_byte_3,x
	AND #$F0
	LSR #4
	DEC
	ASL #4
	CLC
	ADC $06
	STA $06

	LDA $04
	SEC
	SBC #$02
	STA $04
	LDA $0A
	SBC #$00
	STA $0A	

	LDA $06
	CLC
	ADC #$04
	STA $06

	LDA !extra_byte_3,x
	AND #$0F
	DEC
	ASL #4
	CLC
	ADC $07
	STA $07
	RTS
	+

	LDA $06
	CLC
	ADC #$06
	STA $06

	LDA $04
	SEC
	SBC #$13
	STA $04
	LDA $0A
	SBC #$00
	STA $0A

	LDA $05
	CLC
	ADC #$10
	STA $05
	LDA $0B
	ADC #$00
	STA $0B

	LDA !extra_byte_3,x
	AND #$F0
	LSR #4
	DEC
	ASL #4
	CLC
	ADC $07
	STA $07

	LDA !extra_byte_3,x
	AND #$0F
	DEC
	ASL #4
	CLC
	ADC $06
	STA $06

	RTS

GetDrawInfo:
STZ !186C,x
   LDA !14E0,x
   XBA
   LDA !E4,x
   REP #$20
   SEC : SBC $1A
   STA $00
   CLC
   ADC.w #$0040
   CMP.w #$0180
   SEP #$20
   LDA $01
   BEQ +
     LDA #$01
   +
   STA !15A0,x
   TDC
   ROL A
   STA !15C4,x

   LDA !14D4,x
   XBA
   LDA !190F,x
   AND #$20
   BEQ .CheckOnce
.CheckTwice
   LDA !D8,x
   REP #$21
   ADC.w #$001C
   SEC : SBC $1C
   SEP #$20
   LDA !14D4,x
   XBA
   BEQ .CheckOnce
   LDA #$02
.CheckOnce
   STA !186C,x
   LDA !D8,x
   REP #$21
   ADC.w #$000C
   SEC : SBC $1C
   SEP #$21
   SBC #$0C
   STA $01
   XBA
   BEQ .OnScreenY
   INC !186C,x
.OnScreenY
   LDY !15EA,x
   RTS	



Platform:

	LDA !14E0,x
	XBA
	LDA !E4,x
	REP #$20
	STA $00
	CLC
	ADC #$0006
	CMP $94
	BCC +
	STA $94

	SEP #$20
	LDA $7B
	BPL +
	STZ $7B
	+

	REP #$20
	LDA !extra_byte_3,x
	AND #$00F0
	CLC
	ADC #$000A
	CLC
	ADC $00
	CMP $94
	BCS +
	STA $94
	SEP #$20
	LDA $7B
	BMI +
	STZ $7B	
	+

	SEP #$20




	RTS

PlatformV:

	LDA !14E0,x
	PHA
	LDA !E4,x
	PHA

	LDA !14D4,x
	PHA
	LDA !D8,x
	PHA

	LDA $94
	SEC
	SBC #$10
	STA !E4,x
	LDA $95
	SBC #$00
	STA !14E0,x

	LDA !D8,x
	SEC
	SBC #$06
	STA !D8,x
	LDA !14D4,x
	SBC #$00
	STA !14D4,x


	JSL $01B44F|!BankB
	BCS +

	LDA !extra_byte_3,x
	AND #$F0
	CLC
	ADC #$06
	CLC
	ADC #$18
	CLC
	ADC !D8,x
	STA !D8,x
	LDA !14D4,x
	ADC #$00
	STA !14D4,x

	JSL $01B44F|!BankB

	+

	PLA
	STA !D8,x
	PLA
	STA !14D4,x

	PLA
	STA !E4,x
	PLA
	STA !14E0,x


	RTS

Movement:
	LDA.w !1570,X             
	INC
	CMP !extra_byte_2,x
	BNE +


	LDA !extra_byte_4,x
	AND #$0F
	BNE ++

	LDA !B6,x
	EOR #$FF
	INC
	STA !B6,x
	BRA +++
	++
	LDA !AA,x
	EOR #$FF
	INC
	STA !AA,x

	+++

	LDA #$00
	+
	STA !1570,x
								
	LDA !extra_byte_4,x
	AND #$0F
	BNE +
	JSL $018022|!BankB
	BRA ++
	+
	JSL $01801A|!BankB
	++
	RTS

PlatformSpr:

	

	LDA !extra_byte_4,x
	AND #$0F
	BNE ++

	LDA !14E0,Y
	STA $01
	LDA !E4,Y
	STA $00

	LDA !14E0,x
	XBA
	LDA !E4,x
	REP #$20
	STA $02
	CLC
	ADC #$0006
	CMP $00
	BCC +
	SEP #$20
	STA !E4,y
	XBA
	STA !14E0,y
	
	LDA !B6,y
	BPL +
	EOR #$FF
	INC
	STA !B6,y
	+

	REP #$20
	LDA !extra_byte_3,x
	AND #$00F0
	CLC
	ADC #$000C
	CLC
	ADC $02
	CMP $00
	BCS +
	SEP #$20
	STA !E4,y
	XBA
	STA !14E0,y
	
	LDA !B6,y
	BMI +
	EOR #$FF
	INC
	STA !B6,y
	+

	SEP #$20
	RTS

	++

	LDA !14D4,Y
	STA $01
	LDA !D8,Y
	STA $00

	LDA !14D4,x
	XBA
	LDA !D8,x
	REP #$20
	STA $02
	CLC
	ADC #$0008
	CMP $00
	BCC +
	INC
	SEP #$20
	STA !D8,y
	XBA
	STA !14D4,y
	
	LDA !AA,y
	BPL +
	LDA #$10
	STA !AA,y
	+

	REP #$20
	LDA !extra_byte_3,x
	AND #$00F0
	CLC
	ADC #$0008
	CLC
	ADC $02
	CMP $00
	BCS +
	SEP #$20
	STA !D8,y
	XBA
	STA !14D4,y
	
	LDA !AA,y
	BMI +
	LDA #$06
	STA !AA,y

	LDA !14C8,y
	CMP #$09
	BNE +

	LDA #$00
	STA !B6,y

	+

	SEP #$20
	RTS
