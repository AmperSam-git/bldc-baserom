;Customized Firebar
;by Isikoro

incsrc Custom_Bro_SpawnTable.asm
incsrc Custom_Bro_TilesTable_mikeyk.asm	;TileMap_File

!GFX_FileNum = $92		;EXGFX number for this sprite
!GFX_FileNum2 = $90		;EXGFX number for projectiles
!GFX_FileNum3 = $93		;EXGFX number for Sledge Bro

XSpeed_Table:		db $08,$04,$F8,$FC	;$Normal,$Sledge,$Normal,$Sledge,
WalkSpeed_Table:	db $10,$F0
RunSpeed_Table:		db $20,$E0

;Extra_Bit
;
;0 = Random Jump
;1 = Small Jump Only

;!extra_byte_1,x
;Bros Number
;00 = Hammer_Bro
;01 = Boomerang_Bro
;02 = Fire_Bro
;03 = Ice_Bro
;04 = Bomb_Bro
;05 = Shell_Bro
;06 = Bullet_Bro
;07 = Flame_Bro
;08 = Flame_Bro Short interval
;09 = Ball_Bro
;0A = Elec_Bro
;0B = Hammer_Bro Continuous
;0C = Sledge_Bro
;0D = Sledge_Bro Continuous
;0E = Curve_Bro
;0F = Braze_Bro
;10 = Frost_Bro
;11 = Miracle_Bro
;
;!extra_byte_1,x
;Spawn sprite index
;
;!extra_byte_2,x
;bit0-3 = Random number range to add to spawn sprite index
;Set the spawn sprite number, speed, etc. by adding a random number in the range of 0 to the specified numerical value to the ‚“spawn sprite index.
;It is recalculated every time the value immediately before 00 in ThrowTimerTable is acquired.
;
;bit4-6 = Behavior type
;
;000 = Usually bro. The graphics do not cause an earthquake even in Sledge.
;001 = Sledge bro. The graphics cause an earthquake even in Usually.
;010 = Move forward
;011 = Chase Mario
;100 = Keep a certain distance with Mario.
;111 = Keep a certain distance with Mario. It glides when it jumps over the shell or falls from a certain height.
;101 = Move up and down in the air.
;110 = Move left and right in the air.
;
;bit7
;0 = It does not jump over shells and fireballs.
;1 = Jump over shells and fireballs.


					print "INIT ",pc
					PHB : PHK : PLB
					JSR INIT_CODE
					PLB
					RTL

INIT_CODE:			LDA #$20 : STA !C2,x
					%SubHorzPos()
					TYA : STA !157C,x : STA !1504,x
					LDA #$80 : STA !1540,x	;JumpWaitTimer
					LDA #$08 : STA !1558,x	;AnimationTimer
					LDA !extra_byte_2,x : STA !15F6,x
					LDA !extra_byte_1,x : STA !1594,x
					TAY
					LDA Walk_Animation_Num,y : STA !1602,x
					LDA !15F6,x : AND #$0F
					%Random()
					CLC : ADC !1594,x : STA !1534,x
					TAY
					LDA TimerSetPattern,y
					%Random()	;Random_Num
					CLC : ADC End_Of_TSNImdex,y
					TAY
					LDA TimerSetIndex,y : STA !1510,x
					TAY : LDA ThrowTimer,y
					CMP #$41 : BCC + : LDA #$40
+					STA !15AC,x				;AnimationTimer
					LDA #$80 : STA !163E,x
					LDA !15F6,x : AND #$70
					CMP #$10 : BNE Not_Big
					INC !1FD6,x
Not_Big:			CMP #$50 : BCC No_Fly
					TAY
					LDA !1656,x : ORA #$20 : STA !1656,x
					CPY #$60 : BCC No_Fly
					LDA #$01 : STA !151C,x
					LDA !1686,x : ORA #$80 : STA !1686,x
					STZ !163E,x
No_Fly:				LDA !extra_bits,x : AND #$04 : STA !1570,x
					LDA !1588,x : ORA #$04 : STA !1588,x

					LDA !15F6,x : AND #$60
					CMP #$40 : BNE No_CertainDistance
					STZ !163E,x
					LDA !7FAB9E,x : STA $00 : STX $02
					PHX
					LDX #!SprSize-1
-					CPX $02 : BEQ Next
					LDA !7FAB9E,x : CMP $00 : BNE Next
					LDA !14C8,x : CMP #$08 : BNE Next
					LDA !15F6,x : AND #$60
					CMP #$40 : BNE Next

					PLX : LDA #$80
					STA !14D4,x : STA !14E0,x
					%SubOffScreen()
No_CertainDistance:	RTS

Next:				DEX : BPL -
+					PLX
					LDA !167A,x : ORA #$04 : STA !167A,x
					RTS

					print "MAIN ",pc
					PHB : PHK : PLB
					JSR START_SPRITE_CODE
					PLB
					RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JumpSpeed_Table:	db $B0,$D0,$C0
LRMoveTime:			db $01,$FF
Animation_Late:		db $08,$18

offset:
db $00,$01,$10,$11

Hide:				LDA !166E,x : ORA #$30 : STA !166E,x
					LDA !167A,x : ORA #$02 : STA !167A,x
					LDA #$01 : STA !154C,x : STA !1564,x
					LDA !14E0,x : XBA : LDA !E4,x
					REP #$21

					LDY !157C,x : BEQ +
					ADC #$0020 : CMP $1A : SEP #$20 : BMI Hide_End
					RTS

+					SBC #$011F : CMP $1A : SEP #$20 : BPL Hide_End
RETURN_:			RTS

Hide_End:			LDA !extra_bits,x : AND #$FB : STA !extra_bits,x
					JSL $07F78B|!BankB
					LDA #$01 : STA !14C8,x
					LDA #$04 : STA !154C,x
					RTS

Throw_Wait_:		JMP Throw_Wait

START_SPRITE_CODE:	LDA !15F6,x : AND #$60
					ORA !1570,x
					CMP #$44 : BEQ Hide

					JSR SUB_GFX
+					LDA #$00 : %SubOffScreen()
					LDA !14C8,x	: CMP #$08 : BNE RETURN_
					STA $D7		;Turn_Flag
					LDA $9D : BNE RETURN_

					LDA !15AC,x : BNE Throw_Wait_

					LDY !1594,x
					LDA !1602,x : AND #$01 : ORA Walk_Animation_Num,y
					STA !1602,x



					LDA !1534,x : ASL : ORA !157C,x
					TAY
					LDA Throw_XSpeed,y
					BNE No_Aim

					STZ $01 : STZ $03
					LDA Throw_X_Offset,y : BPL + : DEC $01
+					PHA
					CLC : ADC !E4,x : STA $00
					LDA !14E0,x : ADC $01 : STA $01
					LDY !1534,x
					LDA Throw_Y_Offset,y : BPL + : DEC $03
+					PHA
					CLC : ADC !D8,x : STA $02
					LDA !14D4,x : ADC $03 : STA $03
					REP #$21
					LDA $02 : SBC #$000F
					SEC : SBC $96 : STA $02
					LDA $00 : SEC : SBC $94 : STA $00
					LDA Throw_YSpeed-1,y : BMI +
					SEC : LDA $00 : SBC #$0004 : STA $00
					SEC : LDA $02 : SBC #$0004 : STA $02
+					SEP #$20
					LDA Throw_YSpeed,y
					AND #$7F
					%Aiming()
					LDA $02 : STA $03
					LDA $00 : STA $02
					PLA : STA $01
					PLA : STA $00

					BRA Aimed

No_Aim:				STA $02
					LDA Throw_X_Offset,y : STA $00
					LDY !1534,x
					LDA Throw_YSpeed,y : STA $03
					LDA Throw_Y_Offset,y : STA $01
Aimed:				LDA Throw_Sound,y : BEQ Sound_Set
					BMI Sound_1DFC
					STA $1DF9|!Base2 : BRA Sound_Set
Sound_1DFC:			AND #$7F : STA $1DFC|!Base2


Sound_Set:			LDA Throw_Sprite_Status,y
					BEQ Extended

					PHA : ASL
					LDA Throw_Sprite_Num,y
					%SpawnSprite()
					PLA : BCS Threw
					PHA : AND #$3F : STA !14C8,y
					LDA !9E,y : CMP #$0D : BNE No_Bomb
					LDA #$A0 : STA !1540,y
No_Bomb:			PLA : AND #$40 : BEQ Clear_ExBit
					PHX : TYX
					LDA !extra_bits,x
					ORA #$04
					STA !extra_bits,x
					PLX
Clear_ExBit:		LDA !157C,x : STA !157C,y
					BRA Threw

Extended:			LDA Throw_Sprite_Num,y
					%SpawnExtended()
					BCS Threw
					LDA !157C,x : ROR #2 : STA $1779|!Base2,y

Threw:				LDY !1510,x
					LDA ThrowTimer,y : BNE Next_Timer

					LDY !1534,x							;Copy of extra_byte_1(+#$00~#$0F)
					CLC : ADC TimerSetPattern,y			;
					%Random()	;Random_Num				;
					CLC : ADC End_Of_TSNImdex,y			;
					TAY									;
					LDA TimerSetIndex,y : STA !1510,x	;
					TAY : LDA ThrowTimer,y				;

Next_Timer:			STA !15AC,x : DEC !1510,x
					DEY : LDA ThrowTimer,y
					BNE Throw_Wait

					LDA !15F6,x : AND #$0F
					BEQ Throw_Wait
					%Random()
					CLC : ADC !1594,x : STA !1534,x

Throw_Wait:			LDY !1FD6,x
					CMP ThrowWaitTime,y : BNE Before_Set_up
					LDY !1594,x
					LDA !1602,x : AND #$01 : ORA Setup_Animation_Num,y
					STA !1602,x

Before_Set_up:		LDA !1558,x : BNE NoChange_Tile
					LDY !1FD6,x : LDA Animation_Late,y
					STA !1558,x
					LDA !1602,x : EOR #$01 : STA !1602,x

NoChange_Tile:		LDA !15F6,x : AND #$70
					CMP #$60 : BCC +
					JMP Flying
+					PHA : CMP #$40 : BCC +
					JMP Certain_distance
+					CMP #$20 : BCC +
					JMP Walking

+					LDA !163E,x : DEC : BNE +
					LDA !1686,x : AND #$7F : STA !1686,x

+					LDA !1588,x : BIT #$08
					BEQ No_Ceiling
					LDA !1FD6,x : BEQ No_Ceiling
					STZ !AA,x

No_Ceiling:			LDA !1588,x : BIT #$03 : BEQ No_Wall
					STZ $D7		;Turn_Flag

No_Wall:			LDA !151C,x
					ORA !1588,x : BNE ON_GROUND
					STZ $D7		;Turn_Flag
					LDA #$01 : STA !151C,x

ON_GROUND:			LDA !1588,x
					AND #$04 : BNE ++
					LDA !151C,x : BEQ IN_AIR_
					INC : CMP #$03
					BCS +
					STA !151C,x : JMP IN_AIR+3
+					STZ !1540,x : JMP IN_AIR+3
IN_AIR_:			BRA IN_AIR

++					LDA !1FD6,x : BEQ Mario_NoStop

					LDA !AA,x : CMP #$40 : BMI Mario_NoStop
					LDA #$20 : STA $1887|!Base2		;EarthQuake

					CLC
					LDA !E4,x : PHA : ADC #$04 : STA !E4,x
					LDA !14E0,x : PHA : ADC #$00 : STA !14E0,x
					CLC
					LDA !E4,x : ADC #$08 : AND #$F0 : STA $9A
					LDA !14E0,x : ADC #$00 : STA $9B
					JSR Break_Block

					LDA !E4,x : BIT #$08 : BEQ One_Block
					SEC : SBC #$10 : STA !E4,x
					LDA !14E0,x : SBC #$00 : STA !14E0,x
					REP #$21
					LDA $9A : SBC #$000F : STA $9A
					SEP #$20
					JSR Break_Block

One_Block:			PLA : STA !14E0,x : PLA : STA !E4,x
					LDA #$09 : STA $1DFC|!Base2
					LDA $77 : AND #$04 : BEQ Mario_NoStop

					LDA #$40 : STA $18BD|!Base2		;Mario_StopTimer
Mario_NoStop:		STZ !151C,x : STZ !AA,x
					LDA !1540,x : BNE IN_AIR+3
					LDA #$80

IN_AIR:				STA !1540,x
					LDA !C2,x : BEQ Turn_Flag
					CMP #$40 : BEQ Turn_Flag
					BRA No_TurnTimer
Turn_Flag:			STZ $D7

No_TurnTimer:		LDA $D7 : BNE No_Turn
					INC !1504,x
					LDA !1504,x : ROR #3
					AND #$40
					STA !C2,x

No_Turn:			LDA !1FD6,x : BEQ +
					STZ !B6,x : LDA !1588,x
					AND #$04 : BEQ .IN_AIR
+					LDA !1504,x : AND #$01 : TAY
					CLC : LDA !C2,x
					ADC LRMoveTime,y : STA !C2,x
					TYA : ASL : ADC !1FD6,x : TAY
					LDA XSpeed_Table,y : STA !B6,x

No_Turn_IN_AIR:		STZ $D5
					LDA $14 : LSR : BCS +
					LDA !1540,x : BEQ +
					INC !1540,x

+					LDA !15F6,x
					BPL No_OverShell

					%JumpOverShell()
					BCC No_OverShell
					LDA #$01 : STA !1540,x
					INC $D5

No_OverShell:		LDA !1540,x : DEC : BNE Jump_Wait_
					STZ !1540,x : LDA #$80 : STA !151C,x

					LDA !1FD6,x : BNE Bottom_Of_Screen

					LDA !1570,x : BNE Top_Of_Screen

					LDA !14D4,x : XBA : LDA !D8,x
					REP #$21
					SBC $1C	; Sprite Y_Posi - Camera Y_Posi
					CMP #$003F : BMI Top_Of_Screen
					CMP #$009F : BPL Bottom_Of_Screen
					BRA Random_Jump

Top_Of_Screen:		SEP #$20
					LDY #$01
					LDA $D5 : BEQ +
					INY
+					BRA Small_Jump

Bottom_Of_Screen:	SEP #$20
					LDY #$00
					BRA To_The_top
Jump_Wait_:			BRA Jump_Wait

Random_Jump:		SEP #$20
					LDA $148D|!Base2 : AND #$01 : TAY
					BEQ To_The_top
Small_Jump:			LDA #$20 : STA !AA,x

					LDA !1570,x : BNE To_The_top
					PHY

					LDY #$07 : LDA #$10
					XBA : LDA #$08
					JSR Bottom_Tile_Check

					BCC No_Get_off

Get_off:			LDA $D6 : CMP #$07 : BEQ No_Get_off
					LDA !1686,x : ORA #$80 : STA !1686,x
					LDA #$31 : STA !163E,x

No_Get_off:			PLY

To_The_top:			LDA JumpSpeed_Table,y : STA !AA,x	;Jump

Jump_Wait:			LDA !15B8,x : PHA
					LDA !1588,x : PHA
					JSL $01802A|!BankB
					PLY : PLA : BEQ No_Downhill
					STA $00						;Set	= Uphill
					EOR !B6,x : BMI No_Downhill	;Clear	= Downhill
					LDA !AA,x : BMI No_Downhill
					INC !D8,x : BNE +
					INC !14D4,x
+					TYA : AND #$04
					BEQ No_Downhill
					TYA : STA !1588,x
					LDA $00 : STA !15B8,x
No_Downhill:		LDA !1FD6,x : BNE +
Jump:				SEC
					LDA !D8,x : PHA : SBC #$10 : STA !D8,x
					LDA !14D4,x : PHA : SBC #$00 : STA !14D4,x
					LDA !1588,x : PHA
					AND #$08 : BEQ .No_Ceiling
					JSL $019138|!BankB
					LDA !1588,x : AND #$08 : BEQ .Ride_up
					STZ !AA,x
					BRA .No_Ceiling
.Ride_up:			LDA !1686,x : ORA #$80 : STA !1686,x
					LDA #$19 : STA !163E,x
.No_Ceiling:		PLA : STA !1588,x
					PLA : STA !14D4,x : PLA : STA !D8,x
+					LDA $14 : LSR : BCC +
					JSL $01A7DC|!BankB
					STZ !154C,x
+					JSL $018032|!BankB
					PLA : AND #$60
					CMP #$20 : BEQ RETURN
					%SubHorzPos()
					TYA : STA !157C,x

RETURN:				RTS                     ; return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Walking:			LDA !1588,x : BIT #$03 : BEQ .No_Wall
					LDA !157C,x : EOR #$01 : STA !157C,x

.No_Wall:			LDA !15B8,x : AND #$07
					CMP #$04	: BNE .No_VerySteepSlope
					LDA !157C,x : EOR #$01 : STA !157C,x
					LDA !B6,x : EOR #$FF : INC : STA !B6,x

					LDY !15B8,x
					STZ !15B8,x : BPL .RightDown
					LDA !E4,x : BNE +
					DEC !14E0,x
+					DEC !E4,x : BRA .No_VerySteepSlope
.RightDown:			INC !E4,x : BNE .No_VerySteepSlope
					INC !14E0,x

.No_VerySteepSlope:	LDA !151C,x : BMI .ON_GROUND
					ORA !1588,x : BNE .ON_GROUND
					LDA #$01 : STA !151C,x

.ON_GROUND:			LDA !1588,x
					AND #$04 : BEQ .IN_AIR
					STZ !151C,x : STZ !AA,x
					LDA !1540,x : BNE .IN_AIR
					LDA #$80

.IN_AIR:			STA !1540,x

					PLA : PHA
					CMP #$30 : BNE No_Chase

					LDA !163E,x : BNE No_Chase
					LDA #$40 : STA !163E,x
					%SubHorzPos()
					TYA : STA !157C,x

No_Chase:			LDA !157C,x : TAY
					LDA WalkSpeed_Table,y : STA !B6,x

					JMP No_Turn_IN_AIR


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Certain_distance:	AND #$10 : LSR #2
					TAY
					LSR #2 : STA $0D
					STZ $D5

					LDA !15F6,x
					BPL +

					TYA : ORA !1588,x : AND #$04 : BEQ +
					LDA !157C,x : CMP $76 : BNE +
					LDA $149C|!Base2 : CMP #$09 : BNE +
					LDA #$80 : TSB $D5
					LDA #$10 : STA !163E,x

+					LDA !1588,x : BIT #$03 : BEQ .No_Wall
					LDA !160E,x : CMP #$02 : BNE +
					STZ !160E,x : STZ !1540,x
					INC $D5
					JMP .No_Flapping
+					INC !151C,x : STZ !160E,x : JMP .No_Flapping

.No_Wall:			LDA !1588,x : AND #$04 : BEQ .No_Landing
					STZ !160E,x
					STZ !AA,x
.No_Landing:		ORA !160E,x : BNE .ON_GROUND
					LDA !151C,x : BNE .Bottom_Check_
					LDA $0D : BEQ .No_Wing

					INC !151C,x

					LDY #$0F : LDA #$04
					XBA : LDA #$04
					JSR Bottom_Tile_Check

					BCS .No_Fly
					LDA #$01 : STA !160E,x
					INC $D5
					JMP .No_Flapping

.No_Fly:			STZ !AA,x
					JMP .No_Flapping
.Bottom_Check_:		JMP .Bottom_Check

.No_Wing:			INC !151C,x
					JMP .No_Flapping

.ON_GROUND:			STZ !151C,x
					LDA #$01 : STA !C2,x
					LDA !160E,x : BEQ .No_Flapping_
					DEC : BEQ .Before_Flapping_
					LDA !1602,x : AND #$01 : STA !C2,x
+					LDA $14 : LSR : BCC .No_BottomShell
					LDA !1662,x : PHA
					LDA !1588,x : PHA : ORA #$04 : STA !1588,x
					LDY !AA,x : BMI +
					AND #$C0 : ORA #$17 : STA !1662,x
+					JSL JumpOverShell
					PLA : STA !1588,x
					PLA : STA !1662,x
					BCC .No_BottomShell
					CLC
					BRA .Bottom_Shell
.No_Flapping_:		JMP .No_Flapping

.No_BottomShell:	LDA !1540,x : BNE .Keep_Flapping
					LDA $14 : LSR : BCS +
					LDY #$0F : LDA #$04 : XBA : LDA #$04
					JSR Bottom_Tile_Check
.Bottom_Shell:		LDA #$C0 : STA !1540,x
					BCC .Keep_Flapping

.Cancel_Flapping:	STZ !160E,x
					STZ !1540,x
					JMP .No_Flapping
.Before_Flapping_:	BRA .Before_Flapping

+					INC !1540,x
.Keep_Flapping:		STZ !AA,x
					%SubVertPos()
					LDY $0F : STY $0E : STA $0F
					REP #$20
					LDA $0E : BMI .Rise
					CMP #$0020
					SEP #$20
					BMI .No_Flapping

					LDA #$10 : STA !AA,x
					LDA !1588,x : AND #$04 : BEQ .No_Flapping
					STZ !AA,x
					BRA .No_Flapping

.Rise:				SEP #$20
					LDA #$F0 : STA !AA,x
					LDA !1588,x : AND #$08 : BEQ .No_Flapping
					STZ !AA,x
					BRA .No_Flapping


.Bottom_Check:		LDA !AA,x : CMP #$30 : BMI .No_Flapping
					LDA $0D : BEQ .No_Flapping
					LDA $14 : LSR : BCS .No_Flapping
					LDY #$0F : LDA #$04 : XBA : LDA #$04
					JSR Bottom_Tile_Check
					BCS .No_Flapping
					LDA #$02 : STA !160E,x
					BRA .Lets_Flapping

.Before_Flapping:	LDA !1588,x : BIT #$08 : BNE .Ceiling
					BIT #$04 : BNE .Cancel_Flapping
					LDA !AA,x : CMP #$30 : BMI .No_Flapping
					BRA +

.Ceiling:			LDA #$30 : STA !AA,x
+					INC !160E,x
.Lets_Flapping:		LDA #$C0 : STA !1540,x

.No_Flapping:		LDA !167A,x : ORA #$04 : STA !167A,x
					%SubVertPos()
					LDY $0F : STY $0B : STA $0C
					%SubHorzPos()
					REP #$20
					LDA $0B
					CMP #$0200 : BPL .Y_Far
					CMP #$FE00 : BMI .Y_Far
					BRA +

.Y_Far:				LDA !167A,x : AND #$FFFB : STA !167A,x : LDA $0B
+					CMP #$FFE0 : BCS +
					CMP #$FF80 : BCS ++
+					LDY !163E,x : CPY #$10 : BNE ++
					LDA !163E,x : AND #$FF00 : STA !163E,x
					LDA #$0080 : TRB $D5

++					CLC : LDA $0E : BMI .Mario_Sprite

.Sprite_Mario:		CMP #$0200 : BPL ..X_Far
					BRA +
..X_Far:			LDA !167A,x : AND #$FFFB : STA !167A,x : LDA $0E
+					LDY !163E,x : BEQ +
					SBC #$0020 : SEC
+					SBC #$003F : BMI .GoToBack
					CMP #$0021 : SEP #$20 : BCC .NoWalk
					BRA .GoToFront

.Mario_Sprite:		CMP #$FE00 : BMI ..X_Far
					BRA +
..X_Far:			LDA !167A,x : AND #$FFFB : STA !167A,x : LDA $0E
+					LDY !163E,x : BEQ +
					ADC #$0020 : CLC
+					ADC #$0040 : BPL .GoToBack
					CMP #$FFE0 : SEP #$20 : BCS .NoWalk
					BRA .GoToFront

.GoToBack:			SEP #$20
					LDA !157C,x : EOR #$01 : BRA +

.X_Far:				SEP #$20

.GoToFront:			LDA !157C,x
+					TAY
					LDA RunSpeed_Table,y : STA !B6,x
					BRA +

.NoWalk:			STZ !B6,x
+					LDA !15F6,x
					BPL .No_OverShell

					LDA $0D : ASL #2
					ORA !1588,x : STA !1588,x
					LDA !1662,x : PHA
					LDY !AA,x : BMI +
					AND #$C0 : ORA #$10 : STA !1662,x
+					%JumpOverShell()
					PLA : STA !1662,x
					BCC .No_OverShell
					BRA .OverShell

.No_OverShell:		LDA $D5 : BEQ +
.OverShell:			LDA #$B0 : STA !AA,x
					LDA $0D : STA !160E,x

+					JSL $019138|!BankB
					LDA !1588,x : PHA
					BIT #$08 : BEQ + : STZ !AA,x
+					BIT #$03 : BEQ + : STZ !B6,x
					BIT #$04 : BEQ + : LDA #$B0 : STA !AA,x
+					JSL $01802A|!BankB
					PLA : STA !1588,x

+					LDA $14 : LSR : BCC +
					JSL $01A7DC|!BankB
					STZ !154C,x
+					%SubHorzPos()
					TYA : STA !157C,x

					PLA : CMP #$40 : BEQ .RETURN

					LDA !14C8,x : CMP #$03
					BEQ .Lose_Wing
.RETURN:			RTS

.Lose_Wing:			LDA #$EF
					BRA Lose_Wing+2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Flying:				LDY !163E,x : BNE .NoChange_Speed
					AND #$10 : STA $00
					LDA $14 : AND #$03 : BNE .NoChange_Speed
					CLC
					LDA !151C,x : AND #$01 : TAY
					LDA $00 : BEQ .Horizontal
					LDA !AA,x : ADC LRMoveTime,y : STA !AA,x
					BRA +
.Horizontal:		LDA !B6,x : ADC LRMoveTime,y : STA !B6,x
+					AND #$1F : CMP #$10 : BEQ .MaxSpeed
					BRA .NoChange_Speed

.MaxSpeed:			LDA #$30 : STA !163E,x : INC !151C,x
.NoChange_Speed:	LDA !AA,x : PHA
					JSL $01802A|!BankB
					PLA : STA !AA,x
					LDA !1602,x : AND #$01 : STA !C2,x
					LDA $14 : LSR : BCC +
					JSL $01A7DC|!BankB
					STZ !154C,x

+					LDA !14C8,x : CMP #$03 : BEQ Lose_Wing
					%SubHorzPos()
					TYA : STA !157C,x
					RTS

Lose_Wing:			LDA #$8F
					AND !extra_byte_2,x
					STA !extra_byte_2,x
					LDA #$01 : STA !14C8,x
					JSL $07F78B|!BankB
					LDA #$08 : STA !154C,x
					RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Bottom_Tile_Check:	STY $D6 : STA $0E

					LDA !1588,x : PHA : LDA !D8,x : PHA : LDA !14D4,x : PHA

					CLC
					XBA : ADC !D8,x : STA !D8,x
					LDA !14D4,x : ADC #$00 : STA !14D4,x
					BRA +

.Loops:				LDA !D8,x : ADC $0E : STA !D8,x
					LDA !14D4,x : ADC #$00 : STA !14D4,x
+					JSL $019138|!BankB
					LDA !1588,x : AND #$04 : BNE .Ground	;If two Rideable tiles are vertically aligned, you will not get down.
					DEC $D6 : CLC : BPL .Loops				;You can't get off if there are no Rideable tiles within the lower 4 tiles.
					BRA .No_Ground

.Ground:			SEC
.No_Ground:			PLA : STA !14D4,x : PLA : STA !D8,x : PLA : STA !1588,x : RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Break_Block:		JSL $019138|!BankB
					LDA $18D7|!Base2 : CMP #$01 : BNE NoBreak
					LDA $185F|!Base2 : CMP #$1E : BNE NoBreak
+					CLC
					LDA !D8,x : ADC #$10 : AND #$F0 : STA $98
					LDA !14D4,x : ADC #$00 : STA $99
					REP #$20
					LDA #$0025
					%ChangeMap16()
					SEP #$20
					PHB : LDA #$02
					PHA : PLB
					LDA #$00
					JSL $028663|!BankB	;shatter block
					PLB
NoBreak:			RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; graphics routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ThrowTileTurn:		db $04,$05
ThrowWaitTime:		db $10,$18

SUB_GFX:
LDA !extra_byte_1,x
CMP #$11
BEQ .NotSledge
CMP #$0C
BCS .SledgeGFX
.NotSledge
					lda #!GFX_FileNum2        ; find or queue GFX
					%FindAndQueueGFX()
					bcs .gfx_loaded
					rts                      ; don't draw gfx if ExGFX isn't ready

.SledgeGFX
CMP #$0E
BCS .SledgeGFX2
					lda #!dss_id_hammer_projectile                  ;load hammer projectile
					%FindAndQueueGFX()
					bcs .gfx_loaded3
					rts                      ; don't draw gfx if ExGFX isn't ready

.SledgeGFX2
					lda #!GFX_FileNum2        ; find or queue GFX
					%FindAndQueueGFX()
					bcs .gfx_loaded4
					rts                      ; don't draw gfx if ExGFX isn't ready

.gfx_loaded4
					lda !dss_tile_buffer+$00
					sta !dss_tile_buffer+$08
					lda !dss_tile_buffer+$01
					sta !dss_tile_buffer+$09
					lda !dss_tile_buffer+$05
					sta !dss_tile_buffer+$0A
					lda #!GFX_FileNum3        ; find or queue GFX
					%FindAndQueueGFX()
					bcs .gfx_loaded2
					rts                      ; don't draw gfx if ExGFX isn't ready

.gfx_loaded3
					lda !dss_tile_buffer+$00
					sta !dss_tile_buffer+$08
					lda !dss_tile_buffer+$01
					sta !dss_tile_buffer+$09
					lda #!GFX_FileNum3        ; find or queue GFX
					%FindAndQueueGFX()
					bcs .gfx_loaded2
					rts                      ; don't draw gfx if ExGFX isn't ready
.gfx_loaded
					lda !dss_tile_buffer+$08
					sta !dss_tile_buffer+$0B
					lda !dss_tile_buffer+$07
					sta !dss_tile_buffer+$0A
					lda !dss_tile_buffer+$06
					sta !dss_tile_buffer+$09
					lda !dss_tile_buffer+$05
					sta !dss_tile_buffer+$08
					lda !dss_tile_buffer+$04
					sta !dss_tile_buffer+$07
					lda !dss_tile_buffer+$03
					sta !dss_tile_buffer+$06
					lda !dss_tile_buffer+$02
					sta !dss_tile_buffer+$05
					lda !dss_tile_buffer+$01
					sta !dss_tile_buffer+$04
					lda !dss_tile_buffer+$00
					sta !dss_tile_buffer+$03
					lda #!GFX_FileNum        ; find or queue GFX
					%FindAndQueueGFX()
					bcs .gfx_loaded2
					rts                      ; don't draw gfx if ExGFX isn't ready

.gfx_loaded2
					LDA #$80 : STA $0F
					LDA !15F6,x
					AND #$70 : CMP #$50 : BCC +
					STZ $0F
					LDA !C2,x : STA $07
+					LDY !157C,x
					LDA !1FD6,x : STA $0B
					LDA Dire_XOffset,y : STA $02
					%GetDrawInfo()
					PHX
					LDA !1534,x : STA $0C
					LDA !15AC,x : STA $0D
					LDA !166E,x : AND #$0F : STA $05
					LDA !1602,x : TAX
					LDA Use_Tiles,x : STA $03
					LDA First_Tile_Num,x : STA $04
					CLC : ADC #!Wing_TileNum : ORA $0F : STA $0E
					LDA $04 : ADC $03 : TAX
					TYA : ADC #$04 : STA $08
					BRA .Start

.Loops:				INY #4
.Start:				LDA Y_Offset,x : CMP #$80 : BEQ .Throw_Write
					CLC
					ADC $01 : STA $0301|!Base2,y	;Y Position

					PHX
					LDA Size,x
					BNE .BigTile
					LDA TileMap,x
					pha
					and #$03
					tax
					lda.l offset,x
					sta $45
					pla
					lsr #2
					tax
					lda.l !dss_tile_buffer,x
					ora $45
					BRA .SetTile
.BigTile
					LDA TileMap,x
					TAX
					lda !dss_tile_buffer,x
.SetTile
					PLX
					STA $0302|!Base2,y	;Tile Numver

					PHX
					TXA : CLC : ADC $02 : TAX
					LDA X_Offset_L,x : CLC
					ADC $00 : STA $0300|!Base2,y	;X Position

					LDA $05
					LDX $02 : BEQ .No_Flip
					ORA #$40
.No_Flip:			ORA $64 : STA $0303|!Base2,y	;Property
					PLX

					PHX
					LDA Size,x : PHA
					TYA : LSR #2 : TAX
					PLA : STA $0460|!Base2,x		;Tile Size
					LDA #$00

.Throw_Return:		PLX : DEX
					CPX $0E : BEQ .Wing_Write
					CPX $04 : BPL .Loops

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.Write_End:			PLX
					LDY #$FF : LDA $03
					JSL $01B7B3|!BankB
					RTS

.Wing_Write
JMP .Wing_Write2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.Throw_Write:		PHX : LDX $0C
					LDA Throw_Sprite_Y_Offset,x
					CMP #$80 : BEQ .Spit
					CLC
					ADC $01 : STA $0301|!Base2,y	;Y Position

					PHX
					LDA Throw_Sprite_Size,x
					BNE .BigThrowTile
					LDA Throw_Sprite_Tiles,x
					pha
					and #$03
					tax
					lda.l offset,x
					sta $45
					pla
					lsr #2
					tax
					lda.l !dss_tile_buffer,x
					ora $45
					BRA .StoreBigThrowTile
.BigThrowTile
					LDA Throw_Sprite_Tiles,x
					TAX
					lda !dss_tile_buffer,x
.StoreBigThrowTile
					PLX
					STA $0302|!Base2,y	;Tile Number

					LDA $02 : BNE +
					LDA Throw_Sprite_X_LOffset,x
					BRA ++

+					LDA Throw_Sprite_X_ROffset,x
++					CLC : ADC $00 : STA $0300|!Base2,y	;X Position

					PHX
					LDA Throw_Sprite_Palette,x
					LDX $02 : BEQ ..No_Flip
					EOR #$40
..No_Flip:			ORA $64 : STA $0303|!Base2,y	;Property
					PLX

					LDA Throw_Sprite_Size,x : PHA
					TYA : LSR #2 : TAX
					PLA : STA $0460|!Base2,x		;Tile Size

					JMP .Throw_Return

.Spit:				DEY #4
					JMP .Throw_Return



.Wing_Write2:		INY #4
					PHX
					LDA $07
					ASL : TAX

					PHX
					LDA $02 : BEQ +
					INX
+					LDA Wing_X_Offset,x : CLC
					ADC $00 : STA $0300|!Base2,y	;X Position

					LDA Wing_Y_Offset,x : CLC
					ADC $01 : STA $0301|!Base2,y	;Y Position

					PLA : LSR : TAX : PHX

					LDA Wing_TileMap,x : STA $0302|!Base2,y	;

					LDA #$06
					LDX $02 : BEQ ..No_Flip
					ORA #$40
..No_Flip:			ORA $64 : STA $0303|!Base2,y	;Property
					PLX

					LDA Wing_Size,x : PHA
					TYA : LSR #2 : TAX
					PLA : STA $0460|!Base2,x

					PLX
					INC $03

					JMP .Loops