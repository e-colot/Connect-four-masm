%include "macros.inc"

section .bss
    ;fakeGridA RESB 6
    ;useless, gridA stays unchanged
    fakeGridB RESB 6
    ; the inital plan was to use these fake grids to simulate hypothetical moves
    ; without loosing the real grids. However, it has been chosen to use them to store
    ; the real grids so other functions can still be called as if it was a "real" move


section .data
    moveValue TIMES 7 DB 0
    ; list of 7 bytes in wich the value of each column will be stored (3rd element
    ; of the list corresponding to the value of playing the 3rd column)

    jumpTablePoints:
        dq FILTER3_0
        dq FILTER3_1
        dq FILTER3_2
        dq FILTER3_3
        dq FILTER3_4
        dq FILTER3_5
        dq FILTER3_6

section .text

    global jumpTablePoints
    global ADD_MOVE_VALUE
    global OPPONENTS_TURN

    extern CHECK_GRID
    extern CHECK_FOR_WIN
    extern gridA
    extern gridB
    extern actualPlayerGrid
    extern rowPos
    extern linePos

    OPPONENTS_TURN:
        ;MOV esi, gridA
        ;MOV edi, fakeGridA
        ;CALL COPY_GRIDS
    ;useless, gridA stays unchanged
        
        MOV esi, gridB
        MOV edi, fakeGridB
        CALL COPY_GRIDS

        ; for each row, call check_grid and evaluate them
        CALL TRY_MOVES

        MOV esi, moveValue
        MOV edx, 6

        XOR bh, bh
        ; bh stores the best index
        MOV bl, -128
        ; bl stores the best value = -128 by default
        ; (worst value to avoid playing it)

    FIND_BEST:
        MOV al, BYTE [esi + edx]
        CMP al, bl
        JNG NEXT_VERIFICATION

        ; if the new element is bigger than the last one
        MOV bl, al
        MOV bh, dl
        ; stores in bh the greatest number index

    NEXT_VERIFICATION:
        DEC edx
        JNS FIND_BEST

        ; prepares for the reset of the list

        MOV edi, esi
        ; start memory in edi
        MOV ecx, 7 
        ; do it seven times
        XOR eax, eax
        ; put eax to 0
        REP STOSB

        ; if the whole list has been treated, puts the best move in cl
        MOV cl, bh 
        ; and puts its value in rowPos
        MOV [rowPos], cl

        ; return to win.asm
        RET


    COPY_GRIDS:
        ; copies esi in edi
        ; (for 6 bytes list)

        MOV al, 6
        ; iteration counter set to 6 to avoid a CMP
        ; DEC al will raise the zero flag at the end

        CALL COPY_LOOP
        RET

    COPY_LOOP:
        MOV bl, [esi]
        MOV [edi], bl 

        INC esi
        INC edi 
        DEC al

        JNZ COPY_LOOP
        RET

    TRY_MOVES:
        ; loop to try to play every move
        MOV BYTE [rowPos], 6
        ; once again doing it by decreasing the iteration to avoid a CMP

    TRY_LOOP:
        ; preparing for the CHECK_GRID call
        MOV cl, [rowPos]
        MOV edx, 5
        CALL CHECK_GRID

        JNO EVALUATE_MOVE_SCORE
        ; if overflow, go to END_TRY_LOOP without evaluating the score
        ; (overflow <=> column is full => moveValue = -10 to not select it)
        MOV al, -10
        CALL ADD_MOVE_VALUE

        ; unconditionally jump to END_TRY_LOOP

    END_TRY_LOOP:

        ; prepare for next iteration

        ; resetting the grid
        ;MOV esi, fakeGridA
        ;MOV edi, gridA
        ;CALL COPY_GRIDS
    ;useless, gridA stays unchanged
        
        MOV esi, fakeGridB
        MOV edi, gridB
        CALL COPY_GRIDS

        ; trying one row lower
        DEC BYTE [rowPos]

        ; redo the loop while rowPos >= 0
    ;but it doesn't seems to work as expected
        JNS TRY_LOOP
    
        RET

    ADD_MOVE_VALUE:
        ; adds the value in al to the moveValue list at rowPos position
        ; dh has to stay untouched here (= 0 if real move)
        ; dl has to stay untouched here (stores a line)
        MOVZX ecx, BYTE [rowPos]
        LEA edi, [moveValue + ecx]

        MOV bl, [edi]
        ADD bl, al
        MOV [edi], bl

        RET

    EVALUATE_MOVE_SCORE:

        MOV dh, 0b10000000
        ; indicates that it is not a real move so the CHECK_FOR_WIN
        ; call will be used to evaluate what the move is worth
        CALL CHECK_FOR_WIN

        JMP END_TRY_LOOP

    FILTER3_4:        
        MOV al, dl
        AND al, 0b0011100
        CMP al, 0b0011100
        CALL ANALYSE_FILTER_OUTPUT

    FILTER3_5:        
        MOV al, dl
        AND al, 0b0111000
        CMP al, 0b0111000
        CALL ANALYSE_FILTER_OUTPUT

    FILTER3_6:        
        MOV al, dl
        AND al, 0b1110000
        CMP al, 0b1110000
        CALL ANALYSE_FILTER_OUTPUT

        RET

    FILTER3_3:        
        MOV al, dl
        AND al, 0b0111000
        CMP al, 0b0111000
        CALL ANALYSE_FILTER_OUTPUT
        
        MOV al, dl
        AND al, 0b0011100
        CMP al, 0b0011100
        CALL ANALYSE_FILTER_OUTPUT
        
        MOV al, dl
        AND al, 0b0001110
        CMP al, 0b0001110
        CALL ANALYSE_FILTER_OUTPUT

        RET

    FILTER3_2:        
        MOV al, dl
        AND al, 0b0011100
        CMP al, 0b0011100
        CALL ANALYSE_FILTER_OUTPUT

    FILTER3_1:        
        MOV al, dl
        AND al, 0b0001110
        CMP al, 0b0001110
        CALL ANALYSE_FILTER_OUTPUT

    FILTER3_0:        
        MOV al, dl
        AND al, 0b0000111
        CMP al, 0b0000111
        CALL ANALYSE_FILTER_OUTPUT

        RET

    ANALYSE_FILTER_OUTPUT:
        JZ ALIGNED_3
        ; if 3 pawns are aligned
        RET

    ALIGNED_3:
        MOV al, 1
        ; value to add to score is in al
        JMP ADD_MOVE_VALUE
        ; jump here so the RET from ADD_MOVE_VALUE heads to the FILTER3
