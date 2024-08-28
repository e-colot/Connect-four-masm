; Charged of adding pawns

%include "macros.inc"

%macro INPUT 0
    MOV eax, SYS_READ
    MOV ebx, STDIN
    MOV ecx, inputBuffer
    MOV edx, 2
    int 0x80
    MOV al, [inputBuffer]

    ; quits if 'q' is typed
    CMP al, 'q'
    JE END_GAME

    SUB al, '1'
    JS INVALID_MOVE                          
    ; if last operation changed the sign (input < '1' in ASCII)
    CMP al, 6
    JG INVALID_MOVE                          
    ; if input > '7' in ASCII
    MOV [inputBuffer], al
%endmacro

%macro ATURN 0
    MOV esi, gridA
    MOV [actualPlayerGrid], esi
    ; playerA is playing
    PRNT inputmsg, leninputmsg
    INPUT
    MOV al, [inputBuffer]
    MOV [rowPos], al                         ; rowPos used to store the row (0 - 6, left to right)
    MOV BYTE [linePos], 5                    ; linePos used to store the line at which we are trying to add a pawn (0 - 5, top to bottom)

    CALL CHECK_GRID
    ; call and not jump so CHECK_GRID can be called in different contexts (opponent)
    JMP NEXT_ROUND
%endmacro

%macro BTURN 0
    MOV esi, gridB
    MOV [actualPlayerGrid], esi
    PRNT inputmsg, leninputmsg
    INPUT
    MOV al, [inputBuffer]
    MOV [rowPos], al                         ; rowPos used to store the row
    MOV BYTE [linePos], 5                    ; linePos used to store the line at which we are trying to add a pawn

    CALL CHECK_GRID
    ; call and not jump so CHECK_GRID can be called in different contexts (opponent)
    JMP NEXT_ROUND
%endmacro

section .bss
    linePos RESB 1
    rowPos RESB 1
    inputBuffer RESB 2

section .data
    inputmsg DB 'Choose where to place your pawn', 0xA, 0xD
    leninputmsg EQU $ - inputmsg
    invalidmsg DB 'Invalid input', 0xA, 0xD
    leninvalidmsg EQU $ - invalidmsg

section .text

    global LAUNCH_A_TURN
    global linePos
    global rowPos

    extern CHECK_FOR_WIN
    extern SHOW_GRID
    extern END_GAME
    extern gridA
    extern gridB
    extern actualPlayerGrid

    CHECK_GRID:
        ; tries to put the new pawn in the correct column
        ; if not possible on the ground level, it tries higher ...
        MOV cl, [rowPos]
        MOV bx, 0x4040
        ; hexa equivalent to the binary : 0100 0000 0100 0000
        SHR bx, cl                           
        ; same mask idea as in "showGrid.asm"
        MOV esi, gridA
        AND edx, 0
        MOV dl, [linePos]
        ADD esi, edx
        MOV BYTE ah, [esi]
        ; ah = line (from playerA) in wich it tries to put a pawn
        MOV esi, gridB
        ADD esi, edx
        MOV BYTE al, [esi]
        ; al = line (from playerB) in wich it tries to put a pawn
        AND ax, bx
        JE ADD_TO_GRID
        ; add the pawn if there was no pawn on the desired place[actualPlayerGrid]
        MOV al, [linePos]
        DEC al
        MOV [linePos], al
        ; tries one row higher
        JNS CHECK_GRID                        
        ; if linePos < 0
        JMP INVALID_MOVE

    ADD_TO_GRID:
        MOV esi, [actualPlayerGrid]
        AND edx, 0
        ; edx = 0
        MOV dl, [linePos]
        ADD esi, edx
        MOV BYTE al, [esi]
        MOV BYTE bl, 1
        ; bl has its uppermost right bit to 1 and will be shifted to the desired location
        MOV BYTE cl, 6
        SUB cl, [rowPos]
        SHL bl, cl
        OR al, bl
        ; ADD could have done the work too
        ; OR avoid overflowing in case of a programmation error
        MOV BYTE [esi], al
        ; grid changed

        ; end of the "check grid process"
        RET

    NEXT_ROUND:
        CALL SHOW_GRID
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

