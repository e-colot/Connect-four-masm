; Charged of verifying if a player has won

%include "macros.inc"

section .data
    endmsg DB 'End of the game', 0xA, 0xD, 0xA, 0xD
    lenendmsg EQU $ - endmsg

section .text

    global CHECK_FOR_WIN

    extern END_GAME
    extern gridA
    extern gridB
    extern actualPlayerGrid
    extern linePos
    extern rowPos

    CHECK_FOR_WIN:
        CALL H_WIN
        CALL V_WIN
        CALL SLANT1_WIN
        CALL SLANT2_WIN
        RET

    RETURN:
        RET

    H_WIN:                                   
    ; checks for - win
        AND ebx, 0
        MOV bl, [linePos]
        MOV esi, [actualPlayerGrid]
        ADD esi, ebx
        ; esi now points to the row that has to be checked
        MOV dl, [esi]
        JMP FIND4

    V_WIN:                                   
    ; checks for | win
        MOV dl, 1
        MOV BYTE cl, 6
        MOV ch, [rowPos]
        SUB cl, ch
        ; cl stores here the column that has to be checked
        MOV esi, [actualPlayerGrid]
        MOV bl, 0                            ; used as a counter for the number of lines
        JMP FOR_EACH_LINE

    FOR_EACH_LINE:
        MOV BYTE al, [esi]
        SHR al, cl
        ; puts the bit of interest at the right of al
        AND al, 1
        ADD dl, al

        SHL dl, 1
        ; shift to make place for the next bit
        INC esi
        ; points to the next line
        INC bl

        ; if the whole column has not been looked yet
        CMP bl, 6
        JNE FOR_EACH_LINE

        JMP FIND4

    SLANT1_WIN:                              
    ; checks for / win
        MOV bl, [linePos]
        MOV bh, [rowPos]
        MOV BYTE cl, 5                       ; 5 and not 6 bcs cl is increased at FOR_SLANT1 before any operation
        SUB cl, bl
        SUB cl, bh                           ; cl is the shift (minus 1)
        MOV esi, [actualPlayerGrid]
        DEC esi
        MOV BYTE ah, -1                      ; iteration counter
        AND dl, 0x0                          ; result registers initalization
        CALL FOR_SLANT1
        JMP FIND4

    FOR_SLANT1:
    ; checks for / win
        INC esi
        INC ah
        INC cl
        CMP cl, 0
        JL FOR_SLANT1
        MOV BYTE al, [esi]
        SHR al, cl
        AND al, 1
        ADD dl, al
        SHL dl, 1
        CMP cl, 6
        JE RETURN
        CMP ah, 5
        JE RETURN
        JMP FOR_SLANT1

    SLANT2_WIN:                              
    ; checks for \ win
        MOV bl, [linePos]
        MOV bh, [rowPos]
        MOV BYTE cl, 7          
        ADD cl, bl
        SUB cl, bh                           ; cl is the shift (plus 1)
        MOV esi, [actualPlayerGrid]
        DEC esi
        MOV BYTE ah, -1                      ; iteration counter
        AND dl, 0x0                          ; result registers initalization
        CALL FOR_SLANT2
        JMP FIND4

    FOR_SLANT2:
        INC esi
        INC ah
        DEC cl
        CMP cl, 7
        JG FOR_SLANT2
        MOV BYTE al, [esi]
        SHR al, cl
        AND al, 1
        ADD dl, al
        SHL dl, 1
        CMP cl, 0
        JE RETURN
        CMP ah, 5
        JE RETURN
        JMP FOR_SLANT2

    FIND4:
        MOV al, dl
        ; done in al not to lose the value in dl
        AND al, 0b1111000
        CMP al, 0b1111000
        JE WIN
        
        MOV al, dl
        AND al, 0b0111100
        CMP al, 0b0111100
        JE WIN
        
        MOV al, dl
        AND al, 0b0011110
        CMP al, 0b0011110
        JE WIN
        
        MOV al, dl
        AND al, 0b0001111
        CMP al, 0b0001111
        JE WIN

        RET

    WIN:
        PRNT endmsg, lenendmsg
        JMP END_GAME
