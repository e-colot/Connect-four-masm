SYS_READ    EQU 3
SYS_WRITE   EQU 4
STDIN       EQU 0
STDOUT      EQU 1


section .text
    global _start               ; to use gcc

    %macro PRNT 2               ; prints arg1 of length arg2
        MOV eax, SYS_WRITE
        MOV ebx, STDOUT
        MOV ecx, %1
        MOV edx, %2
        int 0x80
    %endmacro

    _start:
        PRNT mdg, lenmsg
        CALL ENDGAME

    ENDGAME:                    ; end the program
        MOV eax, SYS_EXIT
        int 0x80

section .data
    msg DB 'start of the game', 0xA, 0xD
    lenmsg DB $ - msg


section .bss