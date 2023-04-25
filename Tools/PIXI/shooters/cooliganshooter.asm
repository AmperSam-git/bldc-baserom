;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Cooligan shooter. To be used with the Cooligan sprite.
;
;To be placed TWO TILES inside a pipe!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sprite number

	!CooliganSprNum = $0F

;time between spawns

	!Timer = $30

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;shooter code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "MAIN ",pc
	LDA #!Timer
	CLC
	%ShooterMain()
	BCC Shoot

	RTL

Shoot:
	TYX
	LDA #!CooliganSprNum
	STA !7FAB9E,x
	JSL $0187A7|!bank
	JSL $07F7D2|!bank
	LDA #$01
	STA !14C8,x
	LDA #$08
	STA !7FAB10,x
	
	LDA #$10			;\
	STA !1558,x			;|set low priority and sprite interaction disable timers
	STA !1564,x			;/
	
	TXY					;\
	LDX $15E9|!addr		;/sprite's slot to y, shooter's slot back to x
	
	STZ $00				;\
	LDA $1783|!addr,x	;|
	AND #$40			;|
	BEQ +				;|
	LDA #$10			;|set direction and offset based on the extra bit
	STA $00				;|
	LDA #$01			;|
	STA !157C,y			;/
	+
	
	LDA $178B|!addr,x	;\
	SEC					;|
	SBC #$08			;|
	STA.w !D8,y			;|
	LDA $1793|!addr,x	;|
	SBC #$00			;|
	STA !14D4,y			;|
	LDA $179B|!addr,x	;|set all positions, offset in y by half a tile and offset in x by 1 if left
	SEC					;|
	SBC $00				;|
	STA.w !E4,y			;|
	LDA $17A3|!addr,x	;|
	SBC #$00			;|
	STA !14E0,y			;/
	
	RTL 