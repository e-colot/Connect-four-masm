SYS_EXIT    EQU 1
SYS_READ    EQU 3
SYS_WRITE   EQU 4
STDIN       EQU 0
STDOUT      EQU 1


%macro PRNT 2               ; prints arg1 of length arg2
    MOV eax, SYS_WRITE
    MOV ebx, STDOUT
    MOV ecx, %1
    MOV edx, %2
    int 0x80
%endmacro

section .text
    global _start               ; to use gcc

    SPACE:
        PRNT spaces, 2
        JMP NEXT_CHARACTER

    TOLINE:
        PRNT toLine, 1
        RET

    APAWN:
        PRNT aPawn, 1
        JMP SPACE

    BPAWN:
        PRNT bPawn, 1
        JMP SPACE

    NOPAWN:
        PRNT noPawn, 1
        JMP SPACE

    SHOW_LINE:                  ; with in "line" the line to show
        MOV cl, [caracterIndex]
        SUB cl, 1               ; substract 1 bcs ebx has a 1 in pre-last pos
        MOV bx, 0x0101
        SHL bx, cl
        MOV ah, [lineA]
        MOV al, [lineB]
        AND ax, bx
        CMP ax, 0
        JE NOPAWN
        CMP ax, 0x0100
        JGE APAWN
        JMP BPAWN

    NEXT_CHARACTER:
        MOV ecx, [caracterIndex]
        DEC ecx
        MOV [caracterIndex], ecx
        CMP ecx, 0
        JNZ SHOW_LINE
        JMP NEXT_LINE

    NEXT_LINE:
        CALL TOLINE
        RET

    _start:
        PRNT msg, lenmsg
        MOV BYTE [caracterIndex], 7  ; 8 elements in a line
        MOV BYTE [lineA], 0b1001000
        MOV BYTE [lineB], 0b0100011
        CALL SHOW_LINE
        JMP END_GAME

    END_GAME:                    ; end the program
        MOV eax, SYS_EXIT
        int 0x80

section .data
    aPawn DB 'O'                ; length of 1
    bPawn DB 'X'                ; length of 1
    noPawn DB '*'               ; length of 1
    spaces DB '  '              ; length of 2
    toLine DB 0x0A              ; length of 1 (2 * 4bits)
    msg DB 'start of the game', 0xA, 0xD
    lenmsg DB $ - msg


section .bss
    lineA RESB 1
    lineB RESB 1
    caracterIndex RESB 1