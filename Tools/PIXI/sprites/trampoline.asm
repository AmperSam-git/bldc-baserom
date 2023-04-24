print "MAIN ",pc
PHB : PHK : PLB
    JSR main
PLB : RTL
print "INIT ",pc
PHB : PHK : PLB
    JSR init
PLB : RTL
RTL

;"Trampoline" made by ME! (Donut)
;give credit if used

;!!!edit this file with notepad++ or something else for extra clarity!!!
;if you need any help feel free to pm me on the site, or contact me through discord :)

!bouncy = 1			;if 0, the trampoline won't act bouncy
;handy if you want to use this as a decoration!

speeds:				;y speeds for different locations on the beans; three table entries per bean
;speeds from 80 to FF with 80 being the fastest
db $C8,$C8,$C8,$C8,$C8,$C0,$B8,$B0;from the leftmost bean...
db $A8,$A0,$98,$94,$94,$98,$A0,$A8
db $B0,$B8,$C0,$C8,$C8,$C8,$C8,$C8;...to the rightmost one

;here's an other table (commented out)
;db $C8,$C8,$C8,$C8,$C8,$C0,$B8,$B8
;db $A0,$98,$94,$94,$94,$94,$98,$A0
;db $B8,$B8,$C0,$C8,$C8,$C8,$C8,$C8
;with this one it's easier to get high bounces
;feel free to make your own and tweak these

!noisy = 1				;if 0, the trampoline won't make any sound
!sound = $08			;sound to play
!soundbank = $1DFC|!addr;soundbank to use

!tile = $3D			;tile for beans
!props = $2A		;properties for beans (YXPPCCCT)

;tables my beloved
;only mess with these if you (more or less) know what you're doing

frames:				;y offsets when walked on; 3 entries/bean
;positive values will shift the bean down; for example: $02 means two pixels down
;from the leftmost to the rightmost bean
db $00,$00,$00,$00,$00,$00,$00,$00;1  the player's on the left
db $00,$00,$00,$00,$00,$00,$00,$00;2
db $00,$00,$00,$00,$00,$00,$00,$00;3
db $00,$01,$01,$00,$00,$00,$00,$00;4
db $00,$01,$01,$00,$00,$00,$00,$00;5
db $00,$01,$01,$01,$00,$00,$00,$00;6  ...in between...
db $00,$02,$03,$02,$02,$01,$01,$00;7  ...the left 'n middle
db $00,$04,$05,$05,$04,$02,$01,$00;8
db $00,$04,$06,$06,$05,$03,$02,$00;9
db $00,$04,$07,$07,$06,$04,$02,$00;10
db $00,$04,$07,$08,$07,$05,$02,$00;11
db $00,$04,$07,$09,$09,$07,$04,$00;12 ...in the...
db $00,$04,$07,$09,$09,$07,$04,$00;13 ...middle
db $00,$02,$05,$07,$08,$07,$04,$00;14
db $00,$02,$04,$06,$07,$07,$04,$00;15
db $00,$02,$03,$05,$06,$06,$04,$00;16
db $00,$01,$02,$04,$05,$05,$04,$00;17
db $00,$01,$01,$02,$02,$03,$02,$00;18 ...in between
db $00,$00,$00,$00,$01,$01,$01,$00;19 ...the right 'n middle
db $00,$00,$00,$00,$00,$01,$01,$00;20
db $00,$00,$00,$00,$00,$01,$01,$00;21
db $00,$00,$00,$00,$00,$00,$00,$00;22
db $00,$00,$00,$00,$00,$00,$00,$00;23
db $00,$00,$00,$00,$00,$00,$00,$00;24 ...on the right

offsets:			;player y position offset when on beans, basically; 3 entries/bean
dw $0000,$0000,$0000,$0000,$0001,$0001,$0003,$0005;goes from left...
dw $0006,$0007,$0008,$0009,$0009,$0008,$0007,$0006
dw $0005,$0003,$0001,$0001,$0000,$0000,$0000,$0000;...to right
;(it shifts the sprite's y position)

bframes:			;wobble animation y offsets
;same as for "frames"; positive values shift the bean down
;from the leftmost to the rightmost bean
db $00, $00, $00, $00, $00, $00, $00, $00;1 not vibrating
db $00, $00, $01, $01, $01, $01, $00, $00;2 ↑
db $00, $00,-$01,-$01,-$01,-$01, $00, $00;3 |
db $00, $01, $02, $02, $02, $02, $01, $00;4 dying down
db $00,-$02,-$03,-$03,-$03,-$03,-$02, $00;5 dying down
db $00, $02, $04, $05, $05, $04, $02, $00;6 |
db $00,-$03,-$05,-$07,-$07,-$05,-$03, $00;7 |
db $00, $04, $07, $09, $09, $07, $04, $00;8	vibrating
db $00, $04, $07, $09, $09, $07, $04, $00;9 failsafe

wobbel:				;animation timer values for wobble, based on position; three table entries per bean
db $01,$01,$03,$03,$05,$05,$07,$07;from the leftmost...
db $07,$09,$09,$09,$09,$09,$09,$07
db $07,$07,$05,$05,$03,$03,$01,$01;...to the rightmost

init:				;backup the starting y position, cuz we'll be needing it
	LDA !14D4,x		;high y
	STA !1534,x		;high starting y
	LDA !D8,x		;low y
	STA !1570,x		;low starting y
RTS

main:
	JSR gfx			;JEE F AXE

	LDA #$00
	%SubOffScreen()	;subscribe
	
	LDA !14C8,x
	CMP #$08		;alive?
	BCS +
	RTS
	+
	LDA $9D			;paused?
	BEQ +
	RTS
	+
	
	SEP #$20
	LDA !14E0,x		;high x
	XBA
	LDA !E4,x		;high x
	REP #$20
	STA $02			;16-bit x
	LDA $D1			;player x
	SEC : SBC $02	;subtract sprite x
	CMP #$0030		;check if in range
	SEP #$20
	BCS .outofrangex;so... in range?
	
	LSR
	STA !1504,x		;save this number for the animation and for some other stuff
	
	ASL : TAY		;put in y index for the offset
	
	LDA !1534,x		;high starting y
	XBA
	LDA !1570,x		;low starting y
	REP #$20
	CLC : ADC offsets,y;load offset
	SEP #$20		;save offset to...
	STA !D8,x		;low y
	XBA
	STA !14D4,x		;high y
.outofrangex
	JSL $01B44F		;call solid routine
	BCC .notonbeans
	
if !bouncy;don't compile this if not bouncy...
	LDA #$01
	STA !C2,x		;set onbean flag
endif;...lets save on some bytes
	
	LDA !1534,x		;high starting y
	STA !14D4,x		;high y
	LDA !1570,x		;low starting y
	STA !D8,x		;low y
	RTS
.notonbeans
if !bouncy
	LDA $16
	ORA $18
	AND #$80
	BEQ .finish		;not jumpin'?
	
	LDA !C2,x
	BEQ .finish		;not on bean?
	
if !noisy
	LDA #!sound
	STA !soundbank	;play sound
endif

	LDA !1504,x
	TAY				;use player's position on the beans to index speeds table
	LDA speeds,y
	STA $7D			;set speed
	
	LDA wobbel,y
	STA !1540,x		;set wobble animation timer
.finish
	STZ !C2,x		;reset onbean flag
endif;endif for if !bouncy
	STZ !1504,x		;if not on top, reset frames
	LDA !1534,x		;high starting y
	STA !14D4,x		;high y
	LDA !1570,x		;low starting y
	STA !D8,x		;low y
RTS

gfx:
	%GetDrawInfo()	;go and get it!
	
	LDA !1504,x
	ASL #3
	STA $02			;ready to use as frame index!
	
if !bouncy;save on sum bytes!
	LDA !1540,x		;wobble timer
	ASL #3			;...into...
	STA $03			;a value we'll use later as an index
endif
	
	PHX
	LDX #$07		;8 beanz
	
	.loop
	TXA : ASL #3		;use loopcount as x offset
	CLC : ADC $00
	STA $0300|!addr,y	;x position
	LDA #!tile
	STA $0302|!addr,y	;tile number
	LDA #!props
	STA $0303|!addr,y	;properties
	
	PHX
if !bouncy;again, getting rid of useless code if not bouncy
	LDA $03				;wobble set?
	BNE .wobble
endif
	TXA
	CLC : ADC $02 : TAX	;calculate the index for the walked on frames
	LDA $01
	CLC : ADC frames,x	;frame stuff
if !bouncy
	BRA ++
	.wobble
	TXA
	CLC : ADC $03 : TAX	;calculate the index for the wobble
	LDA $01
	CLC : ADC bframes,x	;frame stuff
	++
endif
	PLX
	STA $0301|!addr,y	;y position
	
	INY #4
	DEX
	BPL .loop		;standard loop stuff
	
	PLX
	LDA #$07		;tile to draw - 1
	LDY #$00		;8x8 sprite
	JSL $01B7B3
RTS