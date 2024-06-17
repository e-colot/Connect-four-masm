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
    ;SUB al, '0'
    MOV [tmp], al
%endmacro

section .text
    global _start:

_start:
    PRNT msg, len
    INPUT
    PRNT tmp, 1

    MOV eax, SYS_EXIT
    int 0x80

section .data
    msg DB 'Go on', 0xA, 0xD
    len DB $ - msg



section .bss
    tmp RESB 1


