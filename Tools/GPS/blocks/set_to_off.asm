db $42

JMP + : JMP + : JMP + : JMP + : JMP +
JMP ++ : JMP + : JMP + : JMP + : JMP +

+:
    LDA $14AF|!addr     ;\If switch already pressed, ++ act as $25
    BNE ++              ;/

    INC $14AF|!addr     ;set switch to off
    LDA #$0B
    STA $1DF9|!addr     ;sound number
++:
    RTL

print "A button that sets the on/off status to off."