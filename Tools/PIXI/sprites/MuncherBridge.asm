;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Muncher Bridge by Abdu based of the
; Turn Block Bridge Horizontal (and vertical) Disassembly by RealLink
; ("Cleaned" up some of the code to try to make it somewhat readable for myself)
;
; USES FIRST EXTRA BIT: YES
; If set, it'll act like sprite 59, turn block bridge, horizontal and vertical, else it acts like sprite 5A.
;
; Extra Byte 1: If set it will start as vertical, if the extra bit is set while extra byte 1 is set it will start vertical then go horizontal.
; Extra Byte 2: If set will insta kill the player even if you have a star or riding yoshi.
;; Extra Byte 3:
;; if set to 00 then it will use the default palette set in the CFG editor
;; if set to 1 it will use palette 8, 2 palette 9, 3 palette A, ..., 8 palette F
;; if anything greater than 8 it will just do (value modulo 8)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Defines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!GFX_FileNum = $87		;EXGFX number for this sprite

!TileFlipFix 	= 0		;Change this to 1 to fix last bridge turn block which is x-fliped.
!Vert			= !extra_byte_1
!InstaKill		= !extra_byte_2
!Palette		= !extra_byte_3
!MuncherGFX		= $01
!MuncherGFX1	= $00

!Pal8 = $00 ; Same as flying blocked or brown for platform
!Pal9 = $02 ; Grey
!PalA = $04 ; Yellow
!PalB = $06 ; Purple
!PalC = $08	; Red
!PalD = $0A ; Green
!PalE = $0C ; Dark greyish
!PalF = $0E ; Dino color

BlkBridgeLength:                  db $20,$00	;Length - I don't recommend changing this. At least not to a bigger value than 20
TurnBlkBridgeSpeed:               db $01,$FF	;Folding speed - This can be changed, but be careful with big values
BlkBridgeTiming:                  db $40,$40	;Timer - This can be changed to any value

Tiles: db !MuncherGFX, !MuncherGFX1
Palettes: db !Pal8, !Pal9, !PalA, !PalB, !PalC, !PalD, !PalE, !PalF





			!RAM_MarioYPosHi	= $97
			!RAM_MarioYPos		= $96
			!RAM_MarioSpeedY	= $7D
			!RAM_MarioAnimation	= $71
			!RAM_MarioXPos		= $94
			!RAM_MarioXPosHi	= $95
			!RAM_SpritesLocked	= $9D
			!RAM_SpriteState	= !C2
			!RAM_SpriteYLo		= !D8
			!RAM_SpriteXLo		= !E4
			!OAM_DispX		= $0300|!Base2
			!OAM_DispY		= $0301|!Base2
			!OAM_Tile		= $0302|!Base2
			!OAM_Prop		= $0303|!Base2
			!OAM_TileSize		= $0460|!Base2
			!RAM_SpriteYHi		= !14D4
			!RAM_SpriteXHi		= !14E0
			!RAM_SpriteDir		= !157C
			!RAM_SprOAMIndex	= !15EA
			!RAM_ScreenBndryYLo	= $1C
			!OAM_Tile3DispY		= $0309|!Base2
			!OAM_Tile4DispY		= $030D|!Base2
			!OAM_Tile2DispY		= $0305|!Base2
			!RAM_ScreenBndryXLo	= $1A
			!OAM_Tile3DispX		= $0308|!Base2
			!OAM_Tile4DispX		= $030C|!Base2
			!OAM_Tile2DispX		= $0304|!Base2
			!OAM_Tile2		= $0306|!Base2
			!OAM_Tile3		= $030A|!Base2
			!OAM_Tile4		= $030E|!Base2
			!OAM_Tile4Prop		= $030F|!Base2
			!OAM_Tile2Prop		= $0307|!Base2
			!OAM_Tile3Prop		= $030B|!Base2
			!RAM_OnYoshi		= $187A|!Base2
			!EXTRA_BITS 		= !7FAB10 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;INIT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
	LDA !Vert,x
	BNE MoreChecks
	Return:
	RTL
	MoreChecks:
	LDA !EXTRA_BITS,x
	AND #$04
	BEQ Return
	LDA #$02			;Start expanding vertically by setting sprite state to
	STA !RAM_SpriteState,x		;02
RTL


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;MAIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
	PHB                     ; \
	PHK                     ;  | main sprite function, just calls local subroutine
	PLB                     ;  |
	JSR TurnBlkBridge       ;  |
	PLB                     ;  |
RTL                     	; /

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Sprite Code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TurnBlkBridge:                    
	LDA #$00
	%SubOffScreen()	   				; Off screen processing
    JSR Graphics         			; GFX Routine
	JSR Interaction         		; Mario interaction stuff
	LDA $14AF|!Base2
	BNE .Ret

	LDA !EXTRA_BITS,x				;\ Check if extra bit is set
	AND #$04						;|
	BNE .Vert						;/ just branch if thats the case
	LDY !RAM_SpriteState,X     		; Go out/in state
	BRA .checkLength
	.Vert			  
	LDA !RAM_SpriteState,X
	AND #$01                  		; 00->00 01->01 02->00 03->01 usw.
	TAY                       		; into Y
.checkLength
	LDA !151C,x             		;\ Length reached?
	CMP BlkBridgeLength,Y   		;| go set time
	BEQ .setTimer           		;/

	LDA !1540,X             		; Timer
	ORA !RAM_SpritesLocked    		; Sprites Locked
	BNE .Ret          				; not zero? Return

	LDA !151C,x             		;\ ?
	CLC                       		;| Add
	ADC TurnBlkBridgeSpeed,Y 		;| speed to
	STA !151C,X             		;/ length
	.Ret                     
	RTS                       		; Return 

	.setTimer:                      
	LDA BlkBridgeTiming,Y   		;\ Set timer
	STA !1540,X             		;/
	LDA !EXTRA_BITS,x
	AND #$04
	BNE .incState
	LDA !RAM_SpriteState,X     		;\ Change state around
	EOR #$01                		;|
	STA !RAM_SpriteState,X     		;/
	RTS
	.incState                     
	INC !RAM_SpriteState,X    		; Increase State
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Mario interaction code below
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Interaction:
	LDA !15C4,X             	; Sprite off screen
	BNE .Ret          			; Return
	LDA !RAM_MarioAnimation    	; Mario doing a special action?
	CMP #$01                	
	BCS .Ret          			; Return
	JSR ContactCheck         	
	BCC .Ret          			; No contact, return
	
	LDA !InstaKill,x			;\
	BEQ +						;|
	JSL $00F606|!BankB			;/ Die
	RTS
	
	+
	LDA !RAM_SpriteYLo,X
	SEC                       
	SBC !RAM_ScreenBndryYLo    	
	STA $02                       
	SEC                           
	SBC $0D                       
	STA $09                       
	LDA $80                       
	CLC                       	
	ADC #$18                	
	CMP $09                   	
	BCS TouchingBottom		
	LDA !RAM_MarioSpeedY          
	BMI .Ret              
	STZ !RAM_MarioSpeedY        ; Mario is on top of the sprite interaction(?)
	LDA #$01                	; platform type
	STA $1471|!Base2              
	LDA $0D                       
	CLC                       	
	ADC #$1F                	
	LDY !RAM_OnYoshi         	
	BEQ .notOnYoshi           	
	CLC                       	
	ADC #$10                	
	.notOnYoshi						
	STA $00                   	
	LDA !RAM_SpriteYLo,X       	
	SEC                       	
	SBC $00                   	
	STA !RAM_MarioYPos         	
	LDA !RAM_SpriteYHi,X     	
	SBC #$00                	
	STA !RAM_MarioYPosHi       	
	LDY #$00                	
	LDA $1491|!Base2            
	BPL +           			
	DEY                       	
	+							
	CLC                       	
	ADC !RAM_MarioXPos         	
	STA !RAM_MarioXPos         	
	TYA                       	
	ADC !RAM_MarioXPosHi       	
	STA !RAM_MarioXPosHi

	; on top of the sprite
	LDA $1490|!Base2		;\ Star
	ORA $1493|!Base2		;| end level timer
	ORA $1497|!Base2		;| I-Frames
    ORA $187A|!Base2		;/ On Yoshi
	BNE .Ret
	JSL $00F5B7|!BankB		; hurt the player                 		  
	.Ret 
RTS

TouchingBottom: 			; Touching bottom of the bridge.
	LDA $02                   
	CLC                      
	ADC $0D                  
	STA $02                  
	LDA #$FF               
	LDY $73         	
	BNE TouchingSides          
	LDY $19      		
	BNE .bigMario          
	.ducking	
	LDA #$08               
	.bigMario
	CLC                      
	ADC $80                  
	CMP $02                  
	BCC TouchingSides	
	LDA !RAM_MarioSpeedY      	
	BPL .Ret         	
	LDA #$10	
	STA !RAM_MarioSpeedY
	
	; on touching bottom of the sprite
	LDA $1490|!Base2		;\ Star
	ORA $1493|!Base2		;| end level timer
	ORA $1497|!Base2		;/ I-Frames
	BNE .Ret
	JSL $00F5B7|!BankB		; hurt the player   
	.Ret
RTS

TouchingSides:
	LDA $0E                   
	CLC                       
	ADC #$10                
	STA $00                   
	LDY #$00                
	LDA !RAM_SpriteXLo,X       
	SEC                       
	SBC !RAM_ScreenBndryXLo    
	CMP $7E                   
	BCC +           		
	LDA $00                   
	EOR #$FF                
	INC A                     
	STA $00                   
	DEY                       
	+
	LDA !RAM_SpriteXLo,X   
	CLC                   
	ADC $00               
	STA !RAM_MarioXPos     
	TYA                   

	ADC !RAM_SpriteXHi,X 
	STA !RAM_MarioXPosHi   
	STZ $7B 

	; touching sides
	LDA $1490|!Base2		;\ Star
	ORA $1493|!Base2		;| end level timer
	ORA $1497|!Base2		;/ I-Frames
	BNE .Ret
	JSL $00F5B7|!BankB		; hurt the player   
	.Ret
RTS

ContactCheck:
	LDA $00                  
	STA $0E                  
	LDA $02                  
	STA $0D                  
	LDA !RAM_SpriteXLo,X     
	SEC                      
	SBC $00                  
	STA $04                  
	LDA !RAM_SpriteXHi,X     
	SBC #$00                 
	STA $0A                  
	LDA $00                  
	ASL                      
	CLC                      
	ADC #$10                 
	STA $06                  
	LDA !RAM_SpriteYLo,X     
	SEC                      
	SBC $02                  
	STA $05                  
	LDA !RAM_SpriteYHi,X     
	SBC #$00                 
	STA $0B                  
	LDA $02                  
	ASL                      
	CLC                      
	ADC #$10                 
	STA $07                  
	JSL $03B664|!BankB       ; Mario clipping
	JSL $03B72B|!BankB       ; check contact

RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;GFX Routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Graphics:
	lda #!GFX_FileNum        ; find or queue GFX
	%FindAndQueueGFX()
	bcs .gfx_loaded
	rts                      ; don't draw gfx if ExGFX isn't ready	
.gfx_loaded
	%GetDrawInfo()

	LDA !15F6,x
	STA $04

    LDA !Palette,x
    BEQ +

    LDA !15F6,x
    AND #$F1
    STA $04

    LDA !Palette,x
    DEC
    AND #$07
    TAY
    LDA Palettes,y
    ORA $04
    STA $04
	+
    
	STZ $00                   
	STZ $01                   
	STZ $02                   
	STZ $03                   
	
	LDA !RAM_SpriteState,X   
	AND #$02                 
	TAY     
	
	LDA !Vert,x					; !Vert		  
	BEQ +	  	 				; clear go to 

	LDA !EXTRA_BITS,x
	AND #$04
	BNE +
	LDY #$02		   			; There is probably a more elegant way to do it, but this works so...                  
	+

	LDA !151C,X             
	STA $0000,Y              	; $0000 holds current length? Indexed by Y. If Y=02, $0002 is used, which is the length in vertical direction
	LSR                      	; divide by 2
	STA $0001,Y              	; Store into $0001, also indexed by Y. Same as above
	LDY !RAM_SprOAMIndex,X   	; Y = Index into sprite OAM 
	LDA !RAM_SpriteYLo,X       
	SEC                       
	SBC !RAM_ScreenBndryYLo    
	STA $0311|!Base2,Y             
	PHA                       
	PHA                       
	PHA                       
	SEC                       
	SBC $02                   
	STA !OAM_Tile3DispY,Y    
	PLA                       
	SEC                       
	SBC $03                   
	STA !OAM_Tile4DispY,Y    
	PLA                       
	CLC                       
	ADC $02                   
	STA !OAM_DispY,Y        
	PLA                       
	CLC                       
	ADC $03                   
	STA !OAM_Tile2DispY,Y    
	LDA !RAM_SpriteXLo,X       
	SEC                       
	SBC !RAM_ScreenBndryXLo    
	STA $0310|!Base2,Y             
	PHA                       
	PHA                       
	PHA                       
	SEC                       
	SBC $00                   
	STA !OAM_Tile3DispX,Y     ; leftmost tile
	PLA                       
	SEC                       
	SBC $01                   
	STA !OAM_Tile4DispX,Y     ; second tile from the left
	PLA                       
	CLC                       
	ADC $00                   
	STA !OAM_DispX,Y          ;rightmost tile
	PLA                       
	CLC                       
	ADC $01                   
	STA !OAM_Tile2DispX,Y     ; second tile from the right
	LDA !RAM_SpriteState,X    
	LSR                       
	LSR                       
	LDA $14 
	LSR : LSR : LSR
	AND #$01
	PHX
	TAX
	LDA Tiles,x
	TAX
	lda !dss_tile_buffer,x
	PLX                
	STA !OAM_Tile2,Y          ; second tile from the right
	STA !OAM_Tile4,Y          ; second tile from the left
	STA $0312|!Base2,Y        ; Middle tile
	STA !OAM_Tile3,Y          ; leftmost tile
	STA !OAM_Tile,Y           ; rightmost tile

	LDA $64
	ORA $04                   
	
	STA !OAM_Tile4Prop,Y      ; OXOOO
	STA !OAM_Tile2Prop,Y      ; OOOXO
	STA !OAM_Tile3Prop,Y      ; XOOOO
	STA $0313|!Base2,Y        ; OOXOO
	If !TileFlipFix == 0
		ORA #$60                  
	endif
	ORA $04
	STA !OAM_Prop,Y           ; OOOOX
	LDA $00                   
	PHA                       
	LDA $02                   
	PHA                       
	LDA #$04                
	JSR FinishOAMWriteRt         
	PLA                       
	STA $02                   
	PLA                       
	STA $00                   
RTS

FinishOAMWriteRt:
	LDY #$02                
	STY $0B                   
	STA $08                   
	LDY !RAM_SprOAMIndex,X   ; Y = Index into sprite OAM 
	LDA !RAM_SpriteYLo,X       
	STA $00                   
	SEC                       
	SBC !RAM_ScreenBndryYLo    
	STA $06                   
	LDA !RAM_SpriteYHi,X     
	STA $01                   
	LDA !RAM_SpriteXLo,X       
	STA $02                   
	SEC                       
	SBC !RAM_ScreenBndryXLo    
	STA $07                   
	LDA !RAM_SpriteXHi,X     
	STA $03 
	CODE_01B7DE:                 
	TYA                       
	LSR                       
	LSR                       
	TAX                       
	LDA $0B                   
	BPL +           
	LDA !OAM_TileSize,X      
	AND #$02                
	STA !OAM_TileSize,X      
	BRA ++           

	+
	STA !OAM_TileSize,X      
	++
	LDX #$00                
	LDA !OAM_DispX,Y         
	SEC                       
	SBC $07                   
	BPL +           
	DEX                       
	+
	CLC                       
	ADC $02                   
	STA $04                   
	TXA                       
	ADC $03                   
	STA $05                   

	JSR CODE_01B844         
	BCC +           
	TYA                       
	LSR                       
	LSR                       
	TAX                       
	LDA !OAM_TileSize,X      
	ORA #$01                
	STA !OAM_TileSize,X      
	+
	LDX #$00                
	LDA !OAM_DispY,Y         
	SEC                       
	SBC $06                   
	BPL +           
	DEX                       
	+
	CLC                       
	ADC $00                   
	STA $09                   
	TXA                       
	ADC $01                   
	STA $0A                   
	JSR CODE_01C9BF         
	BCC +           
	LDA #$F0                
	STA !OAM_DispY,Y         
	+
	INY                       
	INY                       
	INY                       
	INY                       
	DEC $08                   
	BPL CODE_01B7DE           
	LDX $15E9|!Base2      	; X = Sprite index 
RTS                       	; Return 

CODE_01B844:
	REP #$20               	; Accum (16 bit) 
	LDA $04                   
	SEC                       
	SBC !RAM_ScreenBndryXLo    
	CMP #$0100              
	SEP #$20                ; Accum (8 bit) 
RTS                       	; Return 

CODE_01C9BF:
	REP #$20                ; Accum (16 bit) 
	LDA $09                   
	PHA                       
	CLC                       
	ADC #$0010              
	STA $09                   
	SEC                       
	SBC !RAM_ScreenBndryYLo    
	CMP #$0100              
	PLA                       
	STA $09                   
	SEP #$20                ; Accum (8 bit) 
RTS                       	; Return 