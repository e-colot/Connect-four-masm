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

    NOPAWN:
        PRNT noPawn, 1
        JMP SPACE

    SHOW_CARACTER:                  ; with in "line" the line to show
        MOV cl, [caracterIndex]
        SUB cl, 1                   ; substract 1 bcs ebx has a 1 in pre-last pos
        MOV bl, 1
        SHL bl, cl
        MOV al, [line]
        AND al, bl
        CMP al, 0
        JE NOPAWN
        JMP APAWN

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
        MOV BYTE [line], bl
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
        MOV esi, gridA
        ADD esi, 3
        MOV BYTE [esi], 0b1100011
        CALL SHOW_GRID
        JMP END_GAME

section .data
    gridA TIMES 6 DB 0b0001100 ; 1st bit will be unused
    aPawn DB 'O'                ; length of 1
    noPawn DB '*'               ; length of 1
    spaces DB '  '              ; length of 2
    toLine DB 0x0A              ; length of 1
    msg DB 'start of the game', 0xA, 0xD
    lenmsg DB $ - msg


section .bss
    line RESB 1
    caracterIndex RESB 1
    lineIndex RESB 1
    tmp RESB 1