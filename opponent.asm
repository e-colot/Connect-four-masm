%include "macros.inc"

section .bss
    fakeGridB RESB 6
    fakeGridA RESB 6
    ; the inital plan was to use these fake grids to simulate hypothetical moves
    ; without loosing the real grids. However, it has been chosen to use them to store
    ; the real grids so other functions can still be called as if it was a "real" move


section .data
    moveValue TIMES 7 DW 0
    ; list of 7 double bytes in wich the value of each column will be stored (3rd element
    ; of the list corresponding to the value of playing the 3rd column)

section .text

    global ADD_MOVE_VALUE
    global OPPONENTS_TURN
    global ALIGNED_3
    global ALIGNED_2

    extern CHECK_GRID
    extern CHECK_FOR_WIN
    extern gridA
    extern gridB
    extern actualPlayerGrid
    extern rowPos
    extern linePos

    OPPONENTS_TURN:
        
        MOV esi, gridA
        MOV edi, fakeGridA
        CALL COPY_GRIDS
        
        MOV esi, gridB
        MOV edi, fakeGridB
        CALL COPY_GRIDS

        ; for each row, call check_grid and evaluate them
        CALL TRY_MOVES

        MOV esi, moveValue
        MOV edx, 6

        MOV bx, -32768
        ; bx stores the best value = -32768 by default
        ; (worst value on 2 bytes to avoid playing it)

; -------------------------- FIND BEST MOVE PROCESSUS --------------------------

    FIND_BEST:
        MOV ax, WORD [esi + 2*edx]
        CMP ax, bx
        JNG NEXT_VERIFICATION

        ; if the new element is bigger than the last one
        MOV bx, ax

    NEXT_VERIFICATION:
        DEC edx
        JNS FIND_BEST

        ; has to check if there are other moves with the same score
        ; stores on 4 bits in r8 (64 bits reg) starting from the LSB the index
        ; of the equal value moves
        ; r9 will store the number of equal value moves 
        ; rax will get a random number
        ; rdx will be the iteration counter

        XOR rdx, rdx
        XOR r8, r8
        XOR r9, r9
        ; esi already pointing to moveValues
        CALL FIND_EQUALS

        ; prepares for the reset of the list

        MOV edi, esi
        ; start memory in edi
        MOV ecx, 7 
        ; do it seven times
        XOR ax, ax
        ; put ax to 0

        REP STOSW

        ; if the whole list has been treated, puts the best move in cl
        MOV cl, bh 
        ; and puts its value in rowPos
        MOV [rowPos], cl

        ; return to play.asm
        RET

    FIND_EQUALS:
        ; must keep bx unchanged
        ; rdx has to be set to 0 (iteration counter)
        ; note that it is rdx NOT dl to "or" it with a 64 bit register

        MOV ax, WORD [esi + 2*edx]
        CMP ax, bx
        JNZ NEXT_EQUAL

        ; if this move value is equal
        SHL r8, 4
        OR r8, rdx
        INC r9

    NEXT_EQUAL:
        INC dl
        ; checks if the whole list has been processed
        CMP dl, 7
        JNZ FIND_EQUALS

        ; unconditionally jump to get random

    GET_RANDOM:

        ; random number in rax
        RDRAND rax
        ; only keep the 3 lower bits of rax
        AND rax, 0b111

    IN_RANGE_FOR_RANDOM:
        ; while rax > r9 {
        ;     rax -= r9
        ; }

        CMP rax, r9
        JB MODIFY_OUTPUT

        ; note that it is JB and not JBE
        ; because if there are (example) 3 moves with the same value, 
        ; the choice must be 0, 1 or 2 but not 3

        ; if not below, rax -= r9
        SUB rax, r9
        JMP IN_RANGE_FOR_RANDOM

    MODIFY_OUTPUT:
        ; change bh to select a random move (still with the highest score)
        ; (temporary put in bh so ecx can be used for the reset)
        ; based on the value stored in rax
        ; this value being on 3 bits, al can be used from now

        MOV bl, 4
        MUL bl
        ; MUL needs a reg8 not an imm8

        ; adding maximum 2 bits so still fit in al
        MOV cl, al
        ; SHR needs cl and not al
        SHR r8, cl
        AND r8, 0b1111
        ; only keeps the bits of interest
        MOV rax, r8
        MOV bh, al

        RET
        ; returns to NEXT_VERIFICATION

; -------------------------- COPY PROCESSUS --------------------------

    COPY_GRIDS:
        ; copies esi in edi
        ; (for 6 bytes list)

        MOV al, 6
        ; iteration counter set to 6 to avoid a CMP
        ; DEC al will raise the zero flag at the end
        
        ; unconditionally jumps to COPY_LOOP

    COPY_LOOP:
        MOV bl, [esi]
        MOV [edi], bl 

        INC esi
        INC edi 
        DEC al

        JNZ COPY_LOOP
        
        RET
        ; exit the "copy list processus" 

; -------------------------- TRY MOVES PROCESSUS --------------------------

    TRY_MOVES:
        ; loop to try to play every move
        MOV BYTE [rowPos], 6
        ; once again doing it by decreasing the iteration to avoid a CMP

    TRY_LOOP:
        ; preparing for the CHECK_GRID call
        MOV cl, [rowPos]
        MOV edx, 5
        CALL CHECK_GRID
        
        ; dh looks like
        ; R T PPP XXX
        ; (more info in win.asm:CALL_TABLE)

        MOV dh, cl
        ; cl is supposed to still have rowPos
        SHL dh, 3
        ; dh = xxPPPxxx

        OR dh, 0b10000000
        ; dh = RxPPPxxx

        AND dh, 0b10111111
        ; dh = RTPPPxxx

        JNO EVALUATE_MOVE_SCORE
        ; if overflow, go to END_TRY_LOOP without evaluating the score
        ; (overflow <=> column is full => moveValue = -50 to not select it)
        MOV ax, -1000
        CALL ADD_MOVE_VALUE

        ; unconditionally jump to END_TRY_LOOP

    END_TRY_LOOP:

        ; prepare for next iteration

        ; resetting the grid
        
        MOV esi, fakeGridA
        MOV edi, gridA
        CALL COPY_GRIDS
        
        MOV esi, fakeGridB
        MOV edi, gridB
        CALL COPY_GRIDS

        ; trying one row lower

        ; first getting the previous rowPos
        MOV cl, dh
        SHR cl, 3
        AND cl, 0b111

        ; then decreasing it and putting it back in rowPos
        DEC cl
        MOV BYTE [rowPos], cl

        ; redo the loop while rowPos >= 0
        JNS TRY_LOOP
    
        RET
        ; returns to OPPONENTS_TURN

    ADD_MOVE_VALUE:
        ; adds the value in ax to the moveValue list at rowPos position
        ; dl has to stay untouched here (stores a line)

        ; dh looks like
        ; R T PPP XXX
        ; (more info in win.asm:CALL_TABLE)

        MOV cl, dh
        SHR cl, 3
        AND ecx, 0b111
        ; gets the index at which the score has to be stored

        LEA edi, [moveValue + 2*ecx]

        MOV bx, [edi]

        TEST dh, 0b01000000
        JNZ NEGATIVE_SCORE
        ; <=> if the team bit is raised, substract points

        ; add points
        ADD bx, ax
        MOV [edi], bx

        RET
        ; exit the "add value processus"

    NEGATIVE_SCORE:
        ; substract points
        SUB bx, ax
        MOV [edi], bx

        RET
        ; exit the "add value processus"

    EVALUATE_MOVE_SCORE:

        CALL CHECK_FOR_WIN

        JMP END_TRY_LOOP

; -------------------------- FILTERING PROCESSUS --------------------------

    ALIGNED_3:
        MOV ax, 3
        ; value to add to score is in ax
        JMP ADD_MOVE_VALUE
        ; jump here so the RET from ADD_MOVE_VALUE leads to the next check in CHECK_FOR_WIN

    ALIGNED_2:
        MOV ax, 1
        ; value to add to score is in ax
        JMP ADD_MOVE_VALUE
        ; jump here so the RET from ADD_MOVE_VALUE leads to the next check in CHECK_FOR_WIN
