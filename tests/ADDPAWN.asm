SYS_EXIT    EQU 1
SYS_READ    EQU 3
SYS_WRITE   EQU 4
STDIN       EQU 2
STDOUT      EQU 1


%macro PRNT 2               ; prints arg1 of length arg2
    MOV eax, SYS_WRITE
    MOV ebx, STDOUT
    MOV ecx, %1
    MOV edx, %2
    int 0x80
%endmacro

%macro INPUT 0
    MOV eax, SYS_READ
    MOV ebx, STDIN
    MOV ecx, tmp
    MOV edx, 2
    int 0x80
    MOV al, [tmp]
    SUB al, '1'
    MOV [tmp], al
%endmacro

%macro ATURN 0
    MOV esi, gridA
    MOV [actualPlayerGrid], esi
    PRNT inputmsg, leninputmsg
    INPUT
    MOV al, [tmp]
    MOV [caracterIndex], al     ; caracterIndex used to store the row
    MOV BYTE [lineIndex], 5          ; lineIndex used to store the line at which we are trying to add a pawn
    JMP CHECK_GRID
%endmacro

%macro BTURN 0
    MOV esi, gridB
    MOV [actualPlayerGrid], esi
    PRNT inputmsg, leninputmsg
    INPUT
    MOV al, [tmp]
    MOV [caracterIndex], al     ; caracterIndex used to store the row
    MOV BYTE [lineIndex], 5          ; lineIndex used to store the line at which we are trying to add a pawn
    JMP CHECK_GRID
%endmacro


section .text
    global _start               ; to use gcc

    CHECK_GRID:
        MOV bl, [caracterIndex]
        MOV cl, 6
        SUB cl, bl
        MOV bx, 0x0101
        SHL bx, cl            ; mask
        MOV esi, gridA
        AND edx, 0
        MOV dl, [lineIndex]
        ADD esi, edx
        MOV BYTE ah, [esi]
        MOV esi, gridB
        ADD esi, edx
        MOV BYTE al, [esi]
        AND ax, bx
        CMP ax, 0
        JE ADD_TO_GRID
        MOV al, [lineIndex]
        DEC al
        MOV [lineIndex], al
        CMP al, 0xFF            ; if underflow (so if lineIndex == -1)
        JNZ CHECK_GRID
        JMP INVALID_MOVE

    ADD_TO_GRID:
        MOV esi, [actualPlayerGrid]
        AND edx, 0x0
        MOV dl, [lineIndex]
        ADD esi, edx
        MOV BYTE al, [esi]
        MOV BYTE bl, 1
        MOV BYTE cl, 6
        SUB cl, [caracterIndex]
        SHL bl, cl
        OR al, bl
        MOV BYTE [esi], al
        JMP NEXT_ROUND

    NEXT_ROUND:
        CALL SHOW_GRID
        MOV esi, [actualPlayerGrid]
        CMP esi, gridA
        JE LAUNCH_B_TURN
        JMP LAUNCH_A_TURN

    INVALID_MOVE:
        PRNT invalidmsg, leninvalidmsg
        MOV esi, [actualPlayerGrid]
        CMP esi, gridA
        JE LAUNCH_A_TURN
        JMP LAUNCH_B_TURN

    LAUNCH_A_TURN:
        ATURN

    LAUNCH_B_TURN:
        BTURN

    SHOW_GRID:
        MOV BYTE [lineIndex], 0
        JMP SHOW_LINE

    TOLINE:
        PRNT toLine, 1
        RET

    SPACE:
        PRNT spaces, 2
        JMP NEXT_CHARACTER

    APAWN:
        PRNT aPawn, 1
        JMP SPACE

    BPAWN:
        PRNT bPawn, 1
        JMP SPACE

    NOPAWN:
        PRNT noPawn, 1
        JMP SPACE

    SHOW_CARACTER:
        MOV cl, [caracterIndex]
        SUB cl, 1                   ; substract 1 bcs ebx has a 1 in pre-last pos
        MOV bx, 0x0101
        SHL bx, cl                  ; mask
        MOV ah, [lineA]
        MOV al, [lineB]
        AND ax, bx
        CMP ax, 0
        JE NOPAWN
        CMP ax, 0x0100
        JGE APAWN
        JMP BPAWN

    NEXT_CHARACTER:
        MOV cl, [caracterIndex]
        DEC cl
        MOV BYTE [caracterIndex], cl
        CMP cl, 0
        JNZ SHOW_CARACTER
        JMP NEXT_LINE

    SHOW_LINE:
        MOVZX ecx, BYTE [lineIndex]        ; lineIndex on 1 byte so we have to extend zeros to "cover" the last data
        MOV esi, gridA
        ADD esi, ecx
        MOV BYTE bl, [esi]
        MOV BYTE [lineA], bl
        MOV esi, gridB
        ADD esi, ecx
        MOV BYTE bl, [esi]
        MOV BYTE [lineB], bl
        MOV BYTE [caracterIndex], 7
        JMP SHOW_CARACTER

    NEXT_LINE:
        CALL TOLINE
        MOV cl, [lineIndex]
        INC cl
        MOV [lineIndex], cl
        CMP cl, 6
        JNZ SHOW_LINE
        RET

    END_GAME:                    ; end the program
        MOV eax, SYS_EXIT
        int 0x80

    _start:
        PRNT msg, lenmsg
        CALL SHOW_GRID
        ATURN
        JMP END_GAME

section .data
    gridA TIMES 6 DB 0b0000000 ; 1st bit will be unused
    gridB TIMES 6 DB 0b0000000 ; 1st bit will be unused
    aPawn DB 'O'                ; length of 1
    bPawn DB 'X'                ; length of 1
    noPawn DB '*'               ; length of 1
    spaces DB '  '              ; length of 2
    toLine DB 0x0A              ; length of 1
    msg DB 'start of the game', 0xA, 0xD
    lenmsg EQU $ - msg
    inputmsg DB 'Choose where to place your pawn', 0xA, 0xD
    leninputmsg EQU $ - inputmsg
    invalidmsg DB 'Invalid input', 0xA, 0xD
    leninvalidmsg EQU $ - invalidmsg

section .bss
    lineA RESB 1
    lineB RESB 1
    caracterIndex RESB 1
    lineIndex RESB 1
    tmp RESB 2
    actualPlayerGrid RESD 1
