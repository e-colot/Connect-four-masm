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

    extern ADD_MOVE_VALUE
    extern END_GAME
    extern gridA
    extern gridB
    extern actualPlayerGrid
    extern linePos
    extern rowPos
    extern jumpTablePoints

    CHECK_FOR_WIN:
        ; dh = 1 000 XXXX implies that it is a hypothetic move by the opponent
        ; dh because it stays untouched in the whole file 
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

    ; this section prepares for CALL_TABLE (details are in the descrption
    ; of CALL_TABLE)
        MOV al, 6
        MOV bl, BYTE [rowPos]
        SUB al, bl
        ; al contains the offset (4 bits)

        AND dh, 0b10000000
        ; preserves only the highest bit of dh
        ADD dh, al

        MOV rbx, jumpTable

        CALL CALL_TABLE

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

        XOR ch, ch
        ; ch is used to move cl between each line (0 for a vertical line)

        ; inconditionally go to CREATE_LINE

    CREATE_LINE:
        ; creates a line with the bits in actualPlayerGrid
        ; with cl the top column shift
        ; with ch the shift that must be applied between each line

        ; used for / | \ but not -

        MOV esi, [actualPlayerGrid]
        XOR bl, bl                 
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
        JNZ FOR_EACH_LINE

        ; preparation for CALL_TABLE
        MOV al, 5
        MOV bl, BYTE [linePos]
        SUB al, bl
        ; al contains the offset (4 bits)

        AND dh, 0b10000000
        ; preserves only the highest bit of dh
        ADD dh, al

        MOV rbx, jumpTable

        ; inconditionally jumps to CALL_TABLE

    CALL_TABLE:
        ; calls a jumpTable (stored in rbx) with an offset

        ; this offset is either 5-linePos or 6-rowPos
        ; it is the first one if a horizontal line is checked
        ; and the second one in any other case

        ; as dh is used to check if it is a real move (1 bit used)
        ; but still stays unchanged, the "real-satus bit" will
        ; be on the left of dh and the offset on the right of dh
        ; the offset being between 0 and 7, it only takes 3 bits

        ; so dh looks like
        ; R 0000 XXX
        ; with R the "real-status bit"
        ; and X the offset value
        
        MOVZX rax, dx
        SHR rax, 8
        
        AND al, 0b00000111
        ; removes the "real-status bit"

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
        CALL ANALYSE_FILTER_OUTPUT

    FILTER4_5:          
        MOV al, dl
        AND al, 0b0111100
        CMP al, 0b0111100
        CALL ANALYSE_FILTER_OUTPUT

    FILTER4_6:        
        MOV al, dl
        AND al, 0b1111000
        CMP al, 0b1111000
        CALL ANALYSE_FILTER_OUTPUT
        
        ; if it is not a real move
        TEST dh, 0b10000000
        JNZ CHECK_FOR_3

        RET

    FILTER4_3:          
        MOV al, dl
        AND al, 0b1111000
        CMP al, 0b1111000
        CALL ANALYSE_FILTER_OUTPUT

    FILTER4_2:          
        MOV al, dl
        AND al, 0b0111100
        CMP al, 0b0111100
        CALL ANALYSE_FILTER_OUTPUT

    FILTER4_1:          
        MOV al, dl
        AND al, 0b0011110
        CMP al, 0b0011110
        CALL ANALYSE_FILTER_OUTPUT

    FILTER4_0:        
        MOV al, dl
        AND al, 0b0001111
        CMP al, 0b0001111
        CALL ANALYSE_FILTER_OUTPUT

        ; if it is not a real move
        TEST dh, 0b10000000
        JNZ CHECK_FOR_3

        RET

    ANALYSE_FILTER_OUTPUT:
        JZ ALIGNED_4
        ; if 4 pawns are aligned
        RET

    ALIGNED_4:
        TEST dh, 0b10000000
        ; if it is a real move
        JZ WIN

        MOV al, 10
        ; value to add to score is in al
        CALL ADD_MOVE_VALUE
        ; unconditionally jump to CHECK_FOR_3
        RET

    CHECK_FOR_3:
        MOV rbx, jumpTablePoints
        JMP CALL_TABLE
        ; (informatively, the last stack element heads to one of the FILTER4)
        ; so each of the FILTER3 must lead to a RET

    WIN:
        PRNT endmsg, lenendmsg
        JMP END_GAME
