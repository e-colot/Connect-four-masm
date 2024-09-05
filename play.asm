; Charged of adding pawns

%include "macros.inc"

%macro INPUT 0
    ; the output is 1byte in cl

    MOV eax, SYS_READ
    MOV ebx, STDIN
    MOV ecx, inputBuffer
    MOV edx, 2
    int 0x80
    MOV cl, [inputBuffer]

    ; quits if 'q' is typed
    CMP cl, 'q'
    JE END_GAME

    SUB cl, '1'
    JS INVALID_MOVE                          
    ; if last operation changed the sign (input < '1' in ASCII)
    CMP cl, 6
    JG INVALID_MOVE                          
    ; if input > '7' in ASCII
%endmacro

%macro ATURN 0
    MOV esi, gridA
    MOV [actualPlayerGrid], esi
    ; playerA is playing
    PRNT inputmsg, leninputmsg
    INPUT
    ; the input is in inputBuffer and in cl

    ; set up for CHECK_GRID call (cl = rowPos, edx = linePos)
    MOV [rowPos], cl                         
    MOV edx, 5

    CALL CHECK_GRID
    ; call and not jump so CHECK_GRID can be called in different contexts (opponent)

    JO INVALID_MOVE
    ; if the overflow flag was (artificially) raised <=> full column

    JMP NEXT_ROUND
%endmacro

%macro BTURN 0
    MOV esi, gridB
    MOV [actualPlayerGrid], esi
    ;PRNT inputmsg, leninputmsg
    ;INPUT
    ; the input is in inputBuffer and in cl

    ; set up for CHECK_GRID call (cl = rowPos, edx = linePos)
    ;MOV [rowPos], cl       

    CALL OPPONENTS_TURN
 
    MOV edx, 5

    CALL CHECK_GRID
    ; call and not jump so CHECK_GRID can be called in different contexts (opponent)

    JO INVALID_MOVE
    ; if the overflow flag was (artificially) raised <=> full column
    
    JMP NEXT_ROUND
%endmacro

section .bss
    linePos RESB 1
    ; linePos used to store the line at which we are trying to add a pawn (0 - 5, top to bottom)
    rowPos RESB 1
    ; rowPos used to store the row (0 - 6, left to right)
    inputBuffer RESB 2

section .rodata
    inputmsg DB 'Choose where to place your pawn', 0xA, 0xD
    leninputmsg EQU $ - inputmsg
    invalidmsg DB 'Invalid input', 0xA, 0xD
    leninvalidmsg EQU $ - invalidmsg

section .text

    global LAUNCH_A_TURN
    global linePos
    global rowPos
    global CHECK_GRID

    extern CHECK_FOR_WIN
    extern SHOW_GRID
    extern END_GAME
    extern OPPONENTS_TURN
    extern gridA
    extern gridB
    extern actualPlayerGrid

    CHECK_GRID:
        ; called with rowPos in cl and linePos in edx
        ; please note that rowPos is never set to cl so put
        ; the value in both rowPos and cl before calling

        ; in case of a success (a pawn has been added) the overflow flag (OF) will be set to 0
        ; because of the OR al, bl which set it to 0 and the MOV instructions that let it unchanged

        ; in case of a fail (full column), OF = 1

        ; tries to put the new pawn in the correct column
        ; if not possible on the ground level, it tries higher ...
        MOV bx, 0x4040
        ; hexa equivalent to the binary : 0100 0000 0100 0000
        SHR bx, cl                           
        ; same mask idea as in "showGrid.asm"

        LEA esi, [gridA + edx]
        MOV BYTE ah, [esi]
        ; ah = line (from playerA) in wich it tries to put a pawn

        LEA esi, [gridB + edx]
        MOV BYTE al, [esi]
        ; al = line (from playerB) in wich it tries to put a pawn

        AND ax, bx
        JE ADD_TO_GRID
        ; add the pawn if there was no pawn on the desired place in actualPlayerGrid

        ; (dl = linePos)
        DEC dl

        ; tries one row higher
        JNS CHECK_GRID                        
        ; if linePos < 0 ( <=> if the column is full)
        ; raising the OF-flag :
        MOV al, 0x7f  ; maximum positive value
        INC al

        RET

    ADD_TO_GRID:
        MOV esi, [actualPlayerGrid]
        ; edx = linePos (done in CHECK_GRID)
        ; (AND edx, 0; MOV dl, [linePos])
        ADD esi, edx

        ; tried to replace the paragraph above by :
        ; LEA esi, [actualPlayerGrid + edx]
        ; but it would load the adress of actualPlayerGrid, not
        ; the adress stored in actualPlayeGrid (bcs it is a pointer)

        MOV BYTE al, [esi]
        MOV bl, 0x40
        ; hexa equivalent to the binary : 0100 0000
        SHR bl, cl
        ; cl = rowPos
        OR al, bl

        MOV edi, esi
        ; using edi for a destination pointer (readibility purpose)

        MOV BYTE [edi], al
        ; grid changed

        MOV [linePos], dl
        ; (old error : MOV [linePos], edx putting 4bytes on a 1byte memory)
        ; (which caused a change in the value stored in rowPos)

        ; end of the "check grid process"
        RET

    NEXT_ROUND:
        CALL SHOW_GRID
        MOV dh, 0
        ; dh != 0 implies that it is a hypothetic move by the opponent
        CALL CHECK_FOR_WIN
        MOV esi, [actualPlayerGrid]
        CMP esi, gridA
        JE LAUNCH_B_TURN
        ; call LAUNCH_A_TURN if not equal

    LAUNCH_A_TURN:
        ATURN

    INVALID_MOVE:
        PRNT invalidmsg, leninvalidmsg
        MOV esi, [actualPlayerGrid]
        CMP esi, gridA
        ; if it was playerA's turn, it should still be him playing
        JE LAUNCH_A_TURN
        ; call LAUNCH_B_TURN if not equal

    LAUNCH_B_TURN:
        BTURN

