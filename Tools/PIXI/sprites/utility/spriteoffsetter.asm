;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Sprite Offsetter, by Koopster
;
;usage (also featured in the .json description):
;	EXTRA BYTE 1: sprite number
;	EXTRA BYTE 2: sprite "extra bit":
;		0 or 1: regular sprite
;		2: custom sprite, extra bit clear
;		3: custom sprite, extra bit set
;	EXTRA BYTE 3: x displacement
;	EXTRA BYTE 4: y displacement
;	EXTRA BYTES 5-8: extra bytes 1-4 of the custom sprite to spawn (if applicable)
;
;if the extra bit is clear, the displacement will ADD TO the positions (move further right/down).
;if the extra bit is set, the displacement will SUBTRACT FROM the positions (move further left/up).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print "INIT ",pc
	LDA !extra_byte_1,x		;\
	STA $8A					;|
	LDA !extra_byte_2,x		;|
	STA $8B					;|$8A-$8C: 24-bit pointer to extra bytes
	LDA !extra_byte_3,x		;|
	STA $8C					;/
	
	LDA !7FAB10,x	;\
	AND #$04		;|store extra bit on stack for later
	PHA				;/
	
	LDY #$01 		;get extra byte 2
	LDA [$8A],y		;\
	AND #$03		;|store the "extra bit" information for later as well,
	PHA				;/but just the bits we want of course
	AND #$02		;just check if it's a custom sprite or not for now
	BNE SpawnCustom 
	
;spawn a regular sprite
	LDA [$8A]		;load sprite number
	CMP #$53		;\
	BEQ ThrowBlock	;/deal with throw block
	CMP #$C9		;\check if we have a properly indexed sprite set here (up to C8)
	BCC +			;/
	CMP #$DA		;\
	BCS ShellCase	;/branch to shell special case
-	LDA #$00		;let's not crash the game, shall we?
+	STA !9E,x		;which sprite?
	
	JSL $07F7D2|!BankB
	
	PHB			;preserve data bank register
	PEA $0001	;push $01/whatever to stack
	PLB			;pull $01 to dbr
	
	PHK						;\jslrts to smw's init pointers and run sprite init as normal
	PEA ReturnInit-1		;|
	PEA $80CA-1				;|we need this so the position dependent properties are read before we
	JML $018172|!BankB		;|offset the sprite. so yeah, this won't work for bumpties or whatever
ReturnInit:					;/nonsense custom sprites use position as an index for something
	
	PLB			;pull whatever
	PLB			;pull back dbr
	BRA SpawnEnd

ShellCase:
	CMP #$E0
	BCS -		;not sure why I bother with anti-crash measures, but...
	SEC			;\
	SBC #$D6	;|do this math to get the koopa number
	STA !9E,x	;/
	
	JSL $07F7D2|!BankB
	
	LDA #$09		;set it as carryable
	BRA +			;this technically allows for sprite DE, I wonder if it kills the game!?

ThrowBlock:
	STA !9E,x	;set sprite number
	
	JSL $07F7D2|!BankB
	
	LDA #$09	;\
	BRA +		;/set to a carryable state, as that's the only way to make it spawn

SpawnCustom:
	LDA [$8A]		;\
	STA !7FAB9E,x	;/set sprite number
	
	JSL $0187A7|!BankB
	JSL $07F7D2|!BankB
	
	LDY #$04				;\
	LDA [$8A],y				;|
	STA !extra_byte_1,x		;|
	INY						;|
	LDA [$8A],y				;|
	STA !extra_byte_2,x		;|
	INY						;|set 4 extra bytes for the custom sprite
	LDA [$8A],y				;|
	STA !extra_byte_3,x		;|
	INY						;|
	LDA [$8A],y				;|
	STA !extra_byte_4,x		;/
	
	LDA #$01		;\
+	STA !14C8,x		;/make it run its init next. pretty boy
	
SpawnEnd:
	PLA				;restore the "extra bit" info
	ASL #2			;put it in the proper format
	ORA !7FAB10,x	;\
	STA !7FAB10,x	;/set them here
	
	PLA				;recover the actual extra bit from this sprite
	BNE Subtract	;subtract instead if the extra bit is set
	
;add
	LDY #$02		;get extra byte 2
	LDA !E4,x
	CLC				;\
	ADC [$8A],y		;/add to xpos low
	STA !E4,x
	LDA !14E0,x		;\
	ADC #$00		;|do pseudo 16-bit math
	STA !14E0,x		;/
	
	INY				;get extra byte 3
	LDA !D8,x
	CLC				;\
	ADC [$8A],y		;/add to ypos low
	STA !D8,x
	LDA !14D4,x		;\
	ADC #$00		;|do pseudo 16-bit math
	STA !14D4,x		;/
	BRA Return

Subtract:
	LDY #$02		;get extra byte 2
	LDA !E4,x
	SEC				;\
	SBC [$8A],y		;/subtract from xpos low
	STA !E4,x
	LDA !14E0,x		;\
	SBC #$00		;|do pseudo 16-bit math
	STA !14E0,x		;/
	
	INY				;get extra byte 3
	LDA !D8,x
	SEC				;\
	SBC [$8A],y		;/subtract from ypos low
	STA !D8,x
	LDA !14D4,x		;\
	SBC #$00		;|do pseudo 16-bit math
	STA !14D4,x		;/
	
Return:
	
print "MAIN ",pc 
	RTL 