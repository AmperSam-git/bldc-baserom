
			!Hammer_SpNum		= $03+$13	;Hammer.asm
			!ElecBall_SpNum		= $07+$13	;ElecBall.asm
			!SledgeHammer_SpNum	= $03+$13	;SledgeHammer.asm

			!BoundBall_SpNum	= $B1		;Ball.cfg
			!Boomerang_SpNum	= $B2		;Boomerang.cfg
			!FireBall_SpNum		= $B3		;FireBall.cfg
			!IceBall_SpNum		= $B4		;IceBall.cfg


Throw_Sprite_Num:		db !Hammer_SpNum		;Number of sprite to spawn
						db !Boomerang_SpNum		;Booomerang
						db !FireBall_SpNum		;FireBall
						db !IceBall_SpNum		;IceBall
						db $0D					;Bomb
						db $04					;Shell
						db $1C					;Bullet Bill
						db $B3					;Frame
						db $B3					;Frame
						db !BoundBall_SpNum		;Ball
						db !ElecBall_SpNum		;ElecBall
						db !Hammer_SpNum		;Hammer
						db !SledgeHammer_SpNum	;SledgeHammer
						db !SledgeHammer_SpNum	;SledgeHammer
						db !Boomerang_SpNum		;Booomerang
						db !FireBall_SpNum		;FireBall
						db !IceBall_SpNum		;IceBall
						db !Hammer_SpNum		;Hammer
						db !Boomerang_SpNum		;Booomerang
						db !FireBall_SpNum		;FireBall
						db !IceBall_SpNum		;IceBall


Throw_Sprite_Status:	db $00	;Hammer			;00 = Extended
						db $81	;Booomerang		;bit0~5 Status num
						db $81	;FireBall		;
						db $81	;IceBall		;bit6 Extra Bit
						db $08	;Bomb			;bit7 0=Normal,1=Custom
						db $0A	;Shell
						db $01	;Bullet Bill
						db $01	;Frame
						db $01	;Frame
						db $81	;Ball
						db $00	;ElecBall
						db $00	;Hammer
						db $00	;SledgeHammer
						db $00	;SledgeHammer
						db $81	;Booomerang
						db $81	;FireBall
						db $81	;IceBall
						db $00	;Hammer
						db $81	;Booomerang
						db $81	;FireBall
						db $81	;IceBall


Throw_Sound:		db $23	;Hammer				;bit0-6 Spawn sound effect number
					db $28	;Booomerang			;bit7 Bank(0...$1DF9,1...$1DFC)
					db $86	;FireBall
					db $95	;IceBall
					db $20	;Bomb
					db $03	;Shell
					db $89	;Bullet Bill
					db $97	;Frame
					db $97	;Frame
					db $0F	;Ball
					db $1A	;ElecBall
					db $23	;Hammer
					db $23	;SledgeHammer
					db $23	;SledgeHammer
					db $28	;Booomerang
					db $86	;FireBall
					db $95	;IceBall
					db $23	;Hammer
					db $28	;Booomerang
					db $86	;FireBall
					db $95	;IceBall



End_Of_TSNImdex:	db $00	;Hammer			Spawn wait timer index end position
					db $04	;Booomerang
					db $05	;FireBall
					db $05	;IceBall
					db $07	;Bomb
					db $08	;Shell
					db $09	;Bullet Bill
					db $0A	;Frame
					db $0B	;Frame
					db $07	;Ball
					db $0C	;ElecBall
					db $0D	;Hammer
					db $0E	;SledgeHammer
					db $10	;SledgeHammer
					db $11	;Booomerang
					db $12	;FireBall
					db $12	;IceBall
					db $00	;Hammer
					db $04	;Booomerang
					db $05	;FireBall
					db $05	;IceBall

TimerSetPattern:	db $02	;Hammer			Number of spawn standby timer patterns -1
					db $00	;Booomerang
					db $01	;FireBall
					db $01	;IceBall
					db $00	;Bomb
					db $00	;Shell
					db $00	;Bullet Bill
					db $00	;Frame
					db $00	;Frame
					db $00	;Ball
					db $00	;ElecBall
					db $00	;Hammer
					db $01	;SledgeHammer
					db $00	;SledgeHammer
					db $00	;Booomerang
					db $00	;FireBall
					db $00	;IceBall
					db $02	;Hammer
					db $00	;Booomerang
					db $01	;FireBall
					db $01	;IceBall

TimerSetIndex:	db $01,$01,$03,$01	;00-03	Spawn wait timer table start position
				db $06				;04		See line 234 of Custom_Bro.asm for information on how to get the spawn wait timer index.
				db $08,$09			;05-06
				db $0B				;07
				db $0D				;08
				db $0F				;09
				db $11				;0A
				db $13				;0B
				db $15				;0C
				db $17				;0D
				db $19,$1A			;0E,0F
				db $1C				;10
				db $1F				;11
				db $22				;12

ThrowTimer:		db $00,$60,$28,$28	;00-03	Spawn wait timer table
				db $00,$F7,$62		;04-06	When 00 is acquired, the spawn wait timer index is acquired again.
				db $00,$80,$20		;07-09
				db $00,$C0			;0A,0B
				db $00,$A0			;0C,0D
				db $00,$76			;0E,0F
				db $00,$90			;10,11
				db $00,$48			;12,13
				db $00,$60			;14,15
				db $00,$28			;16,17
				db $00,$80,$40		;18-1A
				db $00,$40			;1B,1C
				db $00,$F7,$80		;1D-1F
				db $00,$80,$30		;20-22


Throw_XSpeed:	db $12,$EE	;Hammer			;Spawn X speed
				db $20,$E0	;Booomerang		;$Rightward,$Leftward
				db $20,$E0	;FireBall		;Aim for Mario when set to 00
				db $18,$E8	;IceBall
				db $18,$E8	;Bomb
				db $32,$CE	;Shell
				db $00,$00	;Bullet Bill
				db $10,$F0	;Frame
				db $10,$F0	;Frame
				db $10,$F0	;Ball
				db $00,$00	;ElecBall
				db $12,$EE	;Hammer
				db $1A,$E6	;SledgeHammer
				db $12,$EE	;SledgeHammer
				db $20,$E0	;Booomerang
				db $20,$E0	;FireBall
				db $18,$E8	;IceBall
				db $12,$EE	;Hammer
				db $20,$E0	;Booomerang
				db $20,$E0	;FireBall
				db $18,$E8	;IceBall

Throw_YSpeed:	db $CE	;Hammer				;Spawn Y speed
				db $F8	;Booomerang			;When X Speed is 00, bit 0-6 are the reference speed.
				db $00	;FireBall			;bit7 0 = 8x8 Sprite , 1 = 16x16 Sprite
				db $00	;IceBall
				db $C0	;Bomb
				db $00	;Shell
				db $00	;Bullet Bill
				db $00	;Frame
				db $00	;Frame
				db $C0	;Ball
				db $18	;ElecBall
				db $CE	;Hammer
				db $C4	;SledgeHammer
				db $D0	;SledgeHammer
				db $F8	;Booomerang
				db $00	;FireBall
				db $00	;IceBall
				db $CE	;Hammer
				db $F8	;Booomerang
				db $00	;FireBall
				db $00	;IceBall


Throw_X_Offset:	db $FC,$04	;Hammer			;Spawn X offset
				db $07,$F9	;Booomerang		;$Rightward,$Leftward
				db $10,$F8	;FireBall
				db $10,$F8	;IceBall
				db $07,$F9	;Bomb
				db $07,$F9	;Shell
				db $06,$FA	;Bullet Bill
				db $10,$F0	;Frame
				db $10,$F0	;Frame
				db $07,$F9	;Ball
				db $08,$00	;ElecBall
				db $FC,$04	;Hammer
				db $F6,$0A	;SledgeHammer
				db $F6,$0A	;SledgeHammer
				db $01,$FF	;Booomerang
				db $0A,$FE	;FireBall
				db $0A,$FE	;IceBall
				db $FC,$04	;Hammer
				db $07,$F9	;Booomerang
				db $10,$F8	;FireBall
				db $10,$F8	;IceBall

Throw_Y_Offset:	db $EC	;Hammer				;Spawn Y offset
				db $F2	;Booomerang
				db $FA	;FireBall
				db $FA	;IceBall
				db $F2	;Bomb
				db $F2	;Shell
				db $F2	;Bullet Bill
				db $FD	;Frame
				db $FD	;Frame
				db $F2	;Ball
				db $00	;ElecBall
				db $EC	;Hammer
				db $E8	;SledgeHammer
				db $E8	;SledgeHammer
				db $EE	;Booomerang
				db $EE	;FireBall
				db $EE	;IceBall
				db $EC	;Hammer
				db $F2	;Booomerang
				db $FA	;FireBall
				db $FA	;IceBall