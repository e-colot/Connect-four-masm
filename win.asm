; Charged of verifying if a player has won

%include "macros.inc"

section .bss
    lineBuffer RESB 1

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

    FOR_EACH_LINE:
        MOV BYTE dl, [esi]
        SHR dl, cl
        AND dl, 0x1
        ADD al, dl
        SHL al, 1
        INC esi
        INC bl
        CMP bl, 6
        JNE FOR_EACH_LINE
        RET

    H_WIN:                                   
    ; checks for - win
        AND ebx, 0x0
        MOV bl, [linePos]
        MOV esi, [actualPlayerGrid]
        ADD esi, ebx
        MOV al, [esi]
        MOV dl, al  ; could be changed after
        JMP FIND4

    V_WIN:                                   
    ; checks for | win
        MOV al, 0x1
        MOV BYTE cl, 6
        MOV ch, [rowPos]
        SUB cl, ch
        MOV esi, [actualPlayerGrid]
        MOV bl, 0                            ; used as a counter for the number of lines
        CALL FOR_EACH_LINE
        MOV dl, al  ; could be changed after
        JMP FIND4

    SLANT1_WIN:                              ; checks for / win
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

; WHOLE SECTION : finds if there are 4 consecutive 1's in an 7 bit word (0b0xxxxxxx)

    FIND4:
        ; finds if there are 4 consecutive 1's in an 7 bit word (0b0xxxxxxx)
        ; the said word is stored in dl
        MOV ax, 0x0001
        ; ah is the streak counter (number of consecutive ones) = 0
        ; al is the iteration counter = 1
        TEST dl, 1
        JZ FIND4_RESTART
        ; if the bit was 1, go to FIND4_CONTINUE

    FIND4_CONTINUE:
        ;if the last bit was a 1
        INC ah  ; streak++

        ; checking if it is a 4-streak
        CMP ah, 4
        JE WIN

        ; inconditionally jump to NEXT_BIT

    NEXT_BIT:
        ; checking if the whole 7-bit word has been scanned
        CMP al, 7
        JE RETURN

        SHR dl, 1
        ; shifts to next bit
        INC al  ; iteration++
        TEST dl, 1
        JNZ FIND4_CONTINUE
        JMP FIND4_RESTART

    FIND4_RESTART:
        MOV ah, 0  ; streak = 0
        JMP NEXT_BIT

    WIN:
        PRNT endmsg, lenendmsg
        JMP END_GAME
