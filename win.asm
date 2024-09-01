; Charged of verifying if a player has won

%include "macros.inc"

section .rodata
    endmsg DB 'End of the game', 0xA, 0xD, 0xA, 0xD
    lenendmsg EQU $ - endmsg

section .data
    jumpTable:
        dq FILTER4_0
        dq FILTER4_1
        dq FILTER4_2
        dq FILTER4_3
        dq FILTER4_4
        dq FILTER4_5
        dq FILTER4_6

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

    H_WIN:                                   
    ; checks for - win
        MOVZX ebx, BYTE [linePos]
        MOV esi, [actualPlayerGrid]
        ADD esi, ebx
        ; esi now points to the row that has to be checked

        MOV dl, [esi]
        ; dl contains the row that has to be checked

        MOVZX rbx, BYTE [rowPos]
        MOV rax, 6
        SUB rax, rbx
        MOV rbx, jumpTable

        MOV rdi, [rbx + rax*8]
        ; loads the instruction address from jumpTable
        JMP rdi

    V_WIN:                                   
    ; checks for | win
        MOV dl, 1
        MOV BYTE cl, 6
        MOV ch, [rowPos]
        SUB cl, ch
        ; cl stores here the column-shift that has to be checked

        ; Q :
        ;   What is a column-shift (term used only for the WIN-related labels) ?
        ; A :
        ;   Because there is a usage of masks, it is easier to store by how much the byte
        ;   has to be shifted instead of having its column number. Practically, it means that
        ;   0 corresponds to the rightmost column and it increases when it goes left

        MOV ch, 0
        ; ch is used to move cl between each line (0 for a vertical line)

        ; inconditionally go to CREATE_LINE

    CREATE_LINE:
        ; creates a line with the bits in actualPlayerGrid
        ; with cl the top column shift
        ; with ch the shift that must be applied between each line

        MOV esi, [actualPlayerGrid]
        MOV bl, 0                            
        ; used as iteration counter for the number of lines

        MOV dl, 0
        ; dl used to store the result
        
        ; inconditionally go to FOR_EACH_LINE

    FOR_EACH_LINE:

        ; if we are ouside of the grid (right)
        CMP cl, 0
        JB SKIP_THIS_ROW

        ; if we are ouside of the grid (left)
        CMP cl, 6
        JG SKIP_THIS_ROW

        MOV BYTE al, [esi]
        SHR al, cl
        ; puts the bit of interest at the right of al
        AND al, 1
        ADD dl, al

    SKIP_THIS_ROW:
        ; for the diagonals, the extremities are often outside the grid
        ; so it doesn't have to be added

        SHL dl, 1
        ; shift to make place for the next bit
        INC esi
        ; points to the next line
        ADD cl, ch
        ; allows diagonal search
        INC bl
        ; iteration ++

        ; if the whole column has not been looked yet
        CMP bl, 6
        JNE FOR_EACH_LINE

        MOVZX rbx, BYTE [linePos]
        MOV rax, 5
        SUB rax, rbx
        MOV rbx, jumpTable

        MOV rdi, [rbx + rax*8]
        ; loads the instruction address from jumpTable
        JMP rdi

    SLANT1_WIN:                              
    ; checks for / win
        MOV cl, 6
        SUB cl, [linePos]
        SUB cl, [rowPos]
        ; cl contains the column-shift (might be < 0) corresponding to the highest row
        ; of the diagonal that has to be checked

        MOV ch, 1
        ; ch is used to move cl between each line (1 because it goes to the bottom left)
        ; could be confusing to be > 0 to go left but it is reversed (column-shift)

        JMP CREATE_LINE

    SLANT2_WIN:                              
    ; checks for \ win
        MOV cl, 6
        SUB cl, [linePos]
        ADD cl, [rowPos]
        ; cl contains the column-shift (might be > 6) corresponding to the highest row
        ; of the diagonal that has to be checked

        MOV ch, -1
        ; ch is used to move cl between each line (-1 because it goes to the bottom right)
        ; could be confusing to be < 0 to go right but it is reversed (column-shift)

        JMP CREATE_LINE

; this whole section is to be used in the jumpTable to check only
; the combinations that are possible

    FILTER4_4:        
        MOV al, dl
        AND al, 0b0011110
        CMP al, 0b0011110
        JE WIN

    FILTER4_5:        
        MOV al, dl
        AND al, 0b0111100
        CMP al, 0b0111100
        JE WIN

    FILTER4_6:        
        MOV al, dl
        AND al, 0b1111000
        CMP al, 0b1111000
        JE WIN

        RET

    FILTER4_3:        
        MOV al, dl
        AND al, 0b1111000
        CMP al, 0b1111000
        JE WIN

    FILTER4_2:        
        MOV al, dl
        AND al, 0b0111100
        CMP al, 0b0111100
        JE WIN

    FILTER4_1:        
        MOV al, dl
        AND al, 0b0011110
        CMP al, 0b0011110
        JE WIN

    FILTER4_0:        
        MOV al, dl
        AND al, 0b0001111
        CMP al, 0b0001111
        JE WIN

        RET


    WIN:
        PRNT endmsg, lenendmsg
        JMP END_GAME
