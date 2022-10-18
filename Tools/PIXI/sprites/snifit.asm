;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Snifit, by mikeyk (optimized by Blind Devil)
;;
;; Description: This sprite walks back and forth, occasionally firing balls at Mario.
;;
;; Note: When rideable, clipping tables values should be: 03 0A FE 0E
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;; Uses first extra bit: YES
;; clear: normal Snifit (16x16)
;; set: giant Snifit (32x32)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Extra Property Byte 1
;;    bit 0 - move faster
;;    bit 1 - stay on ledges*
;;    bit 2 - follow mario*
;;    bit 3 - jump over shells
;;    bit 4 - enable spin killing (if rideable)
;;    bit 5 - can be carried (if rideable)
;;    bit 6 - won't walk, eventually hops (grey snifit behavior)*
;;    bit 7 - spit three fireballs instead of spitting a ball*
;;
;; * extension options set these automatically depending on their value
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Extra Property Byte 2
;;    bit 0 - use turning image	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Extra Byte (Extension) 1
;; 00 = red Snifit, falls from ledges
;; 01 = blue Snifit, stays on ledges
;; 02 = grey Snifit, hops in place
;; 03 = fire-spitting red Snifit, falls from ledges
;; 04 = fire-spitting blue Snifit, stays on ledges
;; 05 = fire-spitting grey Snifit, hops in place
;; 06-FF = uses palette/extra property byte configs from CFG - don't override configs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!GFX_FileNum = $8E		;EXGFX number for normal Snifit
!GFX_FileNum_Giant = $8F		;EXGFX number for Giant Snifit

!SnifitProjectile = $05	;custom extended sprite!

;Tilemap tables
Tilemap:
db $01,$00,$00		;frame 1, frame 2, turning (if property is set)

TilemapGiant:
db $00,$01,$02,$03	;top-left, top-right, bottom-left, bottom-right (frame 1)
db $04,$05,$06,$07	;top-left, top-right, bottom-left, bottom-right (frame 2)
db $00,$01,$02,$03	;top-left, top-right, bottom-left, bottom-right (turning, if property is set)

;Palettes (YXPPCCCT format)
!NoLedgeSnifitPal = $08		;a.k.a. red Snifit palette
!LedgeSnifitPal = $06		;a.k.a. blue Snifit palette
!HopSnifitPal = $02		;a.k.a. grey Snifit palette

;Sprite speeds
SpeedX:
db $08,$F8	;right, left (slow)
db $0C,$F4	;right, left (fast)

;Timers
!PreSpawn = $28		;when to start vibrating
!SpawnInterval = $E8	;interval between firing balls
!HopInterval = $40	;interval between Snifit hops

;Grey Snifit hop height
!SpeedY = $DC

;Giant sprite clipping
!GiantClipping = $16		;clipping used for giant sprite, when extra bit is set

;Bullet SFX
!BulletSFX = $10
!BulletPort = $1DFC

;Other defines
!CarryableGiant = 0		;if 1, giant Snifit can be carried. Otherwise, not.
!SpinkillableGiant = 1		;if 1, giant Snifit can be spinkilled (if behavior is on through extra property 1). Otherwise, not.
!GiantIsFaster = 1		;if 1, giant Snifit will move at a faster speed (same as its extra prop 1 speed)
!GiantSpitsBullet = 1		;if 1, giant Snifit will spit a Bullet Bill instead of a small ball (unless if set to spit fireballs).

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite init JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        print "INIT  ",pc
	LDA !7FAB28,x		;load extra prop 1
	PHA			;preserve onto stack

	LDA !7FAB40,x		;load extension 1
	BEQ .RegularRed
	CMP #$01
	BEQ .RegularBlue
	CMP #$02
	BEQ .RegularGrey
	CMP #$03
	BEQ .FireRed
	CMP #$04
	BEQ .FireBlue
	CMP #$05
	BNE .nooptions

	PLA			;restore extra prop 1 value (we saved bytes doing this way!)
	AND #$39
	ORA #$C4
	STA !7FAB28,x
	BRA .greypal

.FireBlue
	PLA
	AND #$39
	ORA #$82
	STA !7FAB28,x
	BRA .bluepal

.RegularRed
	PLA
	AND #$39
	STA !7FAB28,x
	BRA .redpal

.RegularBlue
	PLA
	AND #$39
	ORA #$02
	STA !7FAB28,x
	BRA .bluepal

.RegularGrey
	PLA
	AND #$39
	ORA #$44
	STA !7FAB28,x
	BRA .greypal

.FireRed
	PLA
	AND #$39
	ORA #$80
	STA !7FAB28,x

.redpal
	LDA !15F6,x
	AND #$F1
	ORA #!NoLedgeSnifitPal
	BRA .storepal

.bluepal
	LDA !15F6,x
	AND #$F1
	ORA #!LedgeSnifitPal
	BRA .storepal

.greypal
	LDA !15F6,x
	AND #$F1
	ORA #!HopSnifitPal

.storepal
	STA !15F6,x
	BRA ++

.nooptions
	PLA

++
	LDA !167A,x
	STA !1528,x
	
	LDA #$01
	STA !151C,x

	LDA !7FAB10,x		;load sprite extra bits
	AND #$04		;check if first extra bit is set
	BEQ +			;if not, don't change clipping.

	LDA !1662,x		;load second tweaker byte
	AND #$C0		;preserve properties and clear clipping value
	ORA #!GiantClipping	;add new clipping value
	STA !1662,x		;store result back.
		
+
        %SubHorzPos()
        TYA
        STA !157C,x

        TXA
        AND #$03
        ASL #6
        STA !1504,x
	RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite code JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        print "MAIN ",pc
	PHB                  
        PHK                  
        PLB
        JSR SpriteMainSub
        PLB                  
        RTL
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite main code 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecrementTimers:
	LDA !7FAB28,x
	AND #$40	;if bit 6 is set decrement at will
	BNE +

	LDA !1588,x	;load sprite blocked status
	AND #$04	;check if blocked below (on ground)
	BEQ Return	;if not, don't decrement timer.

+
	LDA !1504,x
	BEQ Return
	DEC !1504,x
Return:
	RTS

SpriteMainSub:
	JSR SubGfx
	
        LDA $9D                 ; \ if sprites locked, return
        BNE Return              ; /
	LDA !14C8,x
	CMP #$08
	BNE Return

	LDA #$00
	%SubOffScreen()
	INC !1570,x

	JSR DecrementTimers

	LDA !1504,x             
        CMP #!PreSpawn  
	BCS WalkingState

	LDA !1504,x    
        CMP #!PreSpawn
        BCS NO_THROW
        STZ !1602,x

        LDA $14
        LSR
	CLC
	ADC $15E9|!Base2
	STA !C2,x

	STZ !B6,x

	LDA !1504,x		; \ if time until throw = 0
        BNE NO_TIME_SET		;  |
        LDA #!SpawnInterval	;  | reset the timer
        STA !1504,x		; /

NO_TIME_SET:
	CMP #$01                ; \ call the ball routine if the timer is 
        BNE NO_THROW            ;  | about to tun out
        JSR SUB_BALL_THROW      ; /

NO_THROW:
	LDA !7FAB28,x
	AND #$40
	BNE WalkingState

	JMP SharedCode
	
WalkingState:	
        LDA $14                 ; Set walking frame based on frame counter
        LSR #3
        CLC
        ADC $15E9|!Base2
        AND #$01               
        STA !1602,x

	LDA !7FAB28,x
	AND #$40
	BEQ NotHop		;don't hop if bit 6 isn't set

	JSR Hop			;only make sprite hop, not walk
	BRA DontWalk

NotHop:
	LDY !157C,x             ; Set x speed based on direction

if !GiantIsFaster
	LDA !7FAB10,x
	AND #$04
	BNE GigaFast
endif

	LDA !7FAB28,x
	AND #$01
	BEQ NoFastSpeed		; Increase speed if bit 0 is set
GigaFast:
	INY #2

NoFastSpeed:
        LDA SpeedX,y           
        STA !B6,x

DontWalk:
	JSL $01802A|!BankB     ; Update position based on speed values

	LDA !1588,x             ; If sprite is in contact with an object...
        AND #$03                  
        BEQ NoObjContact	
        JSR SetSpriteTurning    ;    ...change direction
NoObjContact:
	JSR MaybeStayOnLedges
	
	LDA !1588,x             ; if on the ground, reset the turn counter
        AND #$04
        BEQ SharedCode
	STZ !AA,x
	STZ !151C,x		; Reset turning flag (used if sprite stays on ledges)

	JSR MaybeFaceMario
	JSR MaybeJumpShells

SharedCode:	
	LDA !1528,x
	STA !167A,x
	
        JSL $018032|!BankB	; Interact with other sprites
	JSL $01A7DC|!BankB	; Check for mario/sprite contact (carry set = contact)
        BCC Return11             ; return if no contact
	
        %SubVertPos()           ; \
        LDA $0E                 ;  | if mario isn't above sprite, and there's vertical contact...
        CMP #$E6                ;  |     ... sprite wins
        BMI +
	JMP SpriteWins          ; /
+
        LDA $7D                 ; \ if mario speed is upward, return
        BMI Return11            ; /

if !SpinkillableGiant == 0
		LDA !7FAB10,x
		AND #$04
		BNE SpinKillDisabled
endif

        LDA !7FAB28,x			; Check property byte to see if sprite can be spin jumped
        AND #$10
        BEQ SpinKillDisabled    
        LDA $140D|!Base2               ; Branch if mario is spin jumping
        BEQ SpinKillDisabled
	JMP SpinKill			;O.B.

SpinKillDisabled:	
	LDA $187A|!Base2
	BNE RideSprite
	LDA !7FAB28,x
	AND #$20
	BEQ RideSprite

if !CarryableGiant == 0
		LDA !7FAB10,x
		AND #$04
		BNE RideSprite
endif

	BIT $16		        ; Don't pick up sprite if not pressing button
        BVC RideSprite
	LDA #$0B		; Sprite status = Carried
	STA !14C8,x
	LDA #$FF		; Set time until recovery
	STA !1540,x
	LDA #!SpawnInterval
	STA !1504,x		;reset timer to init

Return11:
	RTS

RideSprite:	
	LDA !7FAB10,x
	AND #$04
	BEQ +

	LDA #$D6
	STA !1534,x
	LDA #$C6
	STA !1FD6,x
	BRA DoneIndexing

+
	LDA #$E1
	STA !1534,x
	LDA #$D1
	STA !1FD6,x

DoneIndexing:
	LDA #$01                ; \ set "on sprite" flag
        STA $1471|!Base2        ; /
        LDA #$06                ; Disable interactions for a few frames
        STA !154C,x             
        STZ $7D                 ; Y speed = 0
        LDA !1534,x             ; \
        LDY $187A|!Base2        ;  | mario's y position += E1 or D1 depending if on yoshi
        BEQ NO_YOSHI            ;  |
        LDA !1FD6,x             ;  |
NO_YOSHI:
	CLC                     ;  |
        ADC !D8,x               ;  |
        STA $96                 ;  |
        LDA !14D4,x             ;  |
        ADC #$FF                ;  |
        STA $97                 ; /
        LDY #$00                ; \ 
        LDA $1491|!Base2        ;  | $1491 == 01 or FF, depending on direction
        BPL LABEL9              ;  | set mario's new x position
        DEY                     ;  |
LABEL9:
	CLC                     ;  |
        ADC $94                 ;  |
        STA $94                 ;  |
        TYA                     ;  |
        ADC $95                 ;  |
        STA $95                 ; /
        RTS                     

SpriteWins:
	LDA !154C,x             ; \ if disable interaction set...
        ORA !15D0,x             ;  |   ...or sprite being eaten...
        BNE Return1             ; /   ...return
        LDA $1490|!Base2        ; Branch if Mario has a star
        BNE MarioHasStar        
        JSL $00F5B7|!BankB	
Return1:
	RTS                    

SpinKill:
	JSR SUB_STOMP_PTS       ; give mario points
	LDA #$F8	        ; Set Mario Y speed
	STA $7D
        JSL $01AB99|!BankB	; display contact graphic
        LDA #$04                ; \ status = 4 (being killed by spin jump)
        STA !14C8,x             ; /   
        LDA #$1F                ; \ set spin jump animation timer
        STA !1540,x             ; /
        JSL $07FC3B|!BankB
        LDA #$08                ; \ play sound effect
        STA $1DF9|!Base2        ; /
        RTS                     ; return

MarioHasStar:
		%Star()
		RTS 

;hop code from grey snifit by Sonikku, adapted by Blind Devil
Hop:
	STZ !C2,x		;reset shake displacement index.

        LDA !1594,x		; If timer isn't equal or higher...
        CMP #!HopInterval	; 
        BCC IncreaseHop		; Increase it.
        LDA !1588,x		; Don't jump if already on ground.
        AND #$04		; 
        BEQ RETURN3
        LDA #!SpeedY		; Set jump height.
        STA !AA,x		; Store it too. 
        STZ !1594,x		; Reset timer.
        RTS			; Return
IncreaseHop:
        INC !1594,x		; Increase timer.
RETURN3:
        RTS			; Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite graphics routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubGfx:	
LDA !7FAB10,x
AND #$04
BNE GiantSnifit
	lda #!GFX_FileNum        ; find or queue GFX
	%FindAndQueueGFX()
	bcs gfx_loaded
	rts                      ; don't draw gfx if ExGFX isn't ready	
	
GiantSnifit:
	lda #!GFX_FileNum_Giant        ; find or queue GFX
	%FindAndQueueGFX()
	bcs gfx_loaded
	rts                      ; don't draw gfx if ExGFX isn't ready	
	
gfx_loaded:
	%GetDrawInfo()

		    STZ $05		    ;reset scratch RAM. it'll hold Y-flip value if stunned.
		    STZ $06		    ;reset scratch RAM. it'll hold number of tiles drawn.

        LDA !157C,x             ; \ $02 = direction
        STA $02                 ; / 

        LDA !1602,x
        STA $03                 ;holds animation frame

	LDA !C2,x
        AND #$01
	STA $09

        LDA !14C8,x		; If killed...
	STA $04
	CMP #$09
	BCS Stunned
        CMP #$02
	BNE NotKilled

Stunned:
	STZ $09
        LDA #$80
        STA $05
	BRA DrawSprite

NotKilled:
	LDA !7FAB34,x		; If turning frame enambled...
	AND #$01
	BEQ DrawSprite	
	LDA !15AC,x		;    ...and turning...
	BEQ DrawSprite
	LDA #$02		;    ...set turning frame
	STA $03

DrawSprite:
        PHX			;preserve sprite index

		LDA !7FAB10,x
		AND #$04
		BNE DrawGiant

        LDA $00                 ; \ tile x position = sprite x location ($00)
        CLC
        ADC $09			;add one to displacement (vibration) if due
        STA $0300|!Base2,y      ; /

	LDA $01                 ; \ tile y position = sprite y location ($01)
        STA $0301|!Base2,y      ; /

	LDX $03			;load tile index
        LDA Tilemap,x           ; \
	TAX
	lda !dss_tile_buffer,x		
        STA $0302|!Base2,y      ; /

	LDX $15E9|!Base2
	LDA !15F6,x             ; tile properties yxppccct, format
	LDX $02                 ; \ if direction == 0...
	BNE NO_FLIP             ;  |
	ORA #$40                ; /    ...flip tile
NO_FLIP:
	ORA $05			; add Y flip if dead/stunned
	ORA $64                 ; add in tile priority of level
        STA $0303|!Base2,y      ; store tile properties

	INC $06			;increment RAM, a tile was drawn

FinishOAM:
        PLX                     ; pull, X = sprite index
        LDY #$02                ; \ 460 = 2 (all 16x16 tiles)
        LDA $06			;  | A = (number of tiles drawn - 1)
        JSL $01B7B3|!BankB      ; / don't draw if offscreen
        RTS                     ; return

XDisp:
db $F8,$08,$F8,$08,$F8		;last value for when X-flipped

YDisp:
db $F0,$F0,$00,$00,$F0,$F0	;last two values for when Y-flipped

DrawGiant:
		    LDA $03
		    ASL #2
		    STA $03		    ;animation index = 0, 4 or 8

		    LDX #$03
GFXLoop:
		    PHX			    ;preserve loop count

		    LDA $02		    ;load sprite direction from scratch RAM
		    BNE FaceLeft	    ;if facing left, don't mess with index.

		    INX			    ;increment X by one, get correct index for table

FaceLeft:
	            LDA $00                 ; \ tile x position = sprite x location ($00)
		    CLC
		    ADC XDisp,x
		    CLC			    ;apparently needed twice here
      		    ADC $09			;add one to displacement (vibration) if due
                    STA $0300|!Base2,y      ; /


		    PLX			    ;restore loop count
		    PHX			    ;and preserve loop count again

		    LDA $04		    ;load sprite status from scratch RAM
		    CMP #$02
		    BEQ Upsidedown
		    CMP #09
		    BCC NotUpsidedown

Upsidedown:
		    INX #2		    ;increment X twice, get correct index for table

NotUpsidedown:
	            LDA $01                 ; \ tile y position = sprite y location ($01)
		    CLC
		    ADC YDisp,x
                    STA $0301|!Base2,y      ; /

		    PLX			    ;restore loop count
		    PHX			    ;and preserve loop count again

		    TXA
		    CLC
                    ADC $03                 ;add animation index to X
		    TAX

                    LDA TilemapGiant,x      ; \ store tile
					TAX
					lda !dss_tile_buffer,x
                    STA $0302|!Base2,y      ; /

		    LDX $15E9|!Base2	    ;get processed sprite index
                    LDA !15F6,x             ; tile properties yxppccct, format
                    LDX $02                 ; \ if direction == 0...
                    BNE NO_FLIP2            ;  |
                    ORA #$40                ; /    ...flip tile
NO_FLIP2:	    ORA $05		    ; add Y flip if stunned
	            ORA $64                 ; add in tile priority of level
                    STA $0303|!Base2,y      ; store tile properties

		    PLX			    ;restore loop count

		    INC $06		    ;increment RAM, a tile was drawn

		    INY #4
		    DEX
		    BPL GFXLoop
                    BRA FinishOAM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ball routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

X_OFFSET:           db $06,$FE,$10,$F8
Y_OFFSET:	    db $06,$02
X_SPEED_BALL:       db $18,$E8
Y_SPEED_FIRE:	    db $F8,$00,$08

SUB_BALL_THROW:
		LDA !7FAB28,x
		AND #$80
		BNE Fireballs

		LDA !157C,x
		TAY

		LDA !7FAB10,x
		AND #$04
		BEQ +
		INY #2
+
		LDA X_OFFSET,y
		STA $00

		LDA !7FAB10,x
		AND #$04
		LSR #2
		TAY

if !GiantSpitsBullet
		CPY #$01
		BNE +
		LDA #$FD
		STA $01
		BRA SpitBullet
+
endif

		LDA Y_OFFSET,y
		STA $01

		LDA !157C,x
		TAY
		LDA X_SPEED_BALL,y
		STA $02

		STZ $03

;Russ Edit
!HitSmthFlag = $1765|!addr

		LDA #!SnifitProjectile+!ExtendedOffset
SpawnExt:
		%SpawnExtended()	
		BCS .Re

LDA #$00
STA !HitSmthFlag,y			;not sure if I really need to do this, but just in case (i think a bug happened with fire thwomp for not clearing sprite table, so)

.Re
		RTS

SpitBullet:
		STZ $02
		STZ $03

		LDA #$1C
		CLC
		%SpawnSprite()
		CPY #$FF
		BEQ no

		LDA #!BulletSFX
		STA !BulletPort|!Base2

		LDA #$08
		STA !14C8,y

		LDA #$10
		STA !1564,y

		LDA !157C,x
		STA !C2,y
no:
		RTS

Fireballs:
		LDA !157C,x
		TAY

		LDA !7FAB10,x
		AND #$04
		BEQ +
		INY #2
+
		LDA X_OFFSET,y
		STA $00

		LDA !7FAB10,x
		AND #$04
		LSR #2
		TAY

		LDA Y_OFFSET,y
		STA $01

		LDA !157C,x
		TAY
		LDA X_SPEED_BALL,y
		STA $02

		LDY #$02
.loop
		PHY
		LDA Y_SPEED_FIRE,y
		STA $03

		LDA #$02
		;JSR SpawnExt
		%SpawnExtended()
		PLY
		DEY
		BPL .loop

		RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MaybeStayOnLedges:	
	LDA !7FAB28,x		; Stay on ledges if bit 1 is set
	AND #$02                
	BEQ NoFlipDirection
	LDA !1588,x             ; If the sprite is in the air
	ORA !151C,x             ;   and not already turning
	BNE NoFlipDirection
	JSR SetSpriteTurning 	;   flip direction
        LDA #$01                ;   set turning flag
	STA !151C,x    
NoFlipDirection:
	RTS
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
MaybeFaceMario:
	LDA !7FAB28,x	; Face Mario if bit 2 is set
	AND #$04
	BEQ Return4	
	LDA !1570,x
	AND #$7F
	BNE Return4
	LDA !157C,x
	PHA
	
	%SubHorzPos()         	; Face Mario
        TYA                       
	STA !157C,X
	
	PLA
	CMP !157C,x
	BEQ Return4
	LDA #$08
	STA !15AC,x
Return4:	
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
MaybeJumpShells:
	LDA !7FAB28,x		; Face Mario if bit 3 is set
	AND #$08
	BEQ Return4
	TXA                     ; \ Process every 4 frames 
        EOR $14                 ;  | 
        AND #$03		;  | 
        BNE Return0188AB        ; / 
        LDY #!SprSize-3		; \ Loop over sprites: 
JumpLoopStart:
	LDA !14C8,Y             ;  | 
        CMP #$0A       		;  | If sprite status = kicked, try to jump it 
        BEQ HandleJumpOver	;  | 
JumpLoopNext:
	DEY                     ;  | 
        BPL JumpLoopStart       ; / 
Return0188AB:
	RTS                     ; Return 

HandleJumpOver:
	LDA !E4,y             ;man
        SEC                       ;why
        SBC #$1A                ;are
        STA $00                   ;there
        LDA !14E0,y             ;so
        SBC #$00                ;many
        STA $08                   ;fucking
        LDA #$44                ;plain
        STA $02                   ;useless
        LDA !D8,y             ;spaces
        STA $01                   ;for
        LDA !14D4,y             ;absolutely
        STA $09                   ;no
        LDA #$10                ;reason
        STA $03                   ;at
        JSL $03B69F|!BankB  ;all?
        JSL $03B72B|!BankB     ;well they have a reason now, as I wrote a fuckton of crap in them lol
        BCC JumpLoopNext        ; If not close to shell, go back to main loop
	LDA !1588,x 		; \ If sprite not on ground, go back to main loop 
	AND #$04		;  |
        BEQ JumpLoopNext        ; / 
        LDA !157C,Y             ; \ If sprite not facing shell, don't jump 
        CMP !157C,x             ;  | 
        BEQ Return0188EB        ; / 
        LDA #$C0                ; \ Finally set jump speed 
        STA !AA,x               ; / 
Return0188EB:
	RTS                     ; Return
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSpriteTurning:
	LDA #$08                ; Set turning timer 
	STA !15AC,X   
        LDA !157C,x
        EOR #$01
        STA !157C,x
Return0190B1:	
        RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; points routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

STAR_SOUNDS:
db $00,$13,$14,$15,$16,$17,$18,$19
             
SUB_STOMP_PTS:
	PHY                      
        LDA $1697|!Base2        ; \
        CLC                     ;  | 
        ADC !1626,x             ; / some enemies give higher pts/1ups quicker??
        INC $1697|!Base2        ; increase consecutive enemies stomped
        TAY                     ;
        INY                     ;
        CPY #$08                ; \ if consecutive enemies stomped >= 8 ...
        BCS NO_SOUND            ; /    ... don't play sound 
        LDA STAR_SOUNDS,y       ; \ play sound effect
        STA $1DF9|!Base2        ; /   
NO_SOUND:
	TYA                     ; \
        CMP #$08                ;  | if consecutive enemies stomped >= 8, reset to 8
        BCC NO_RESET            ;  |
        LDA #$08                ; /
NO_RESET:
	JSL $02ACE5|!BankB
        PLY                     
        RTS                     ; return