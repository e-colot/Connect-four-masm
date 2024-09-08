; Charged of displaying the grid

%include "macros.inc"

section .bss
    caracterIndex RESB 1
    lineIndex RESB 1

section .rodata
    aPawn DB 'O'                             ; length of 1
    bPawn DB 'X'                             ; length of 1
    noPawn DB '*'                            ; length of 1
    spaces DB '  '                           ; length of 2
    toLine DB 0x0A                           ; length of 1

section .text

    global SHOW_GRID

    extern gridA
    extern gridB

    TOLINE:
        ; this label could be deleted but it helps comprehension
        PRNT toLine, 1
        RET
        ; returns to NEXT_LINE

    APAWN:
        PRNT aPawn, 1
        JMP SPACE

    BPAWN:
        PRNT bPawn, 1
        JMP SPACE

    NOPAWN:
        PRNT noPawn, 1
        ; inconditionally going to SPACE

    SPACE:
        PRNT spaces, 2
        ; inconditionally going to NEXT_CHARACTER

    NEXT_CHARACTER:
        MOV cl, [caracterIndex]
        DEC cl
        MOV BYTE [caracterIndex], cl
        ; decreases caracterIndex so going to the next caracter
        CMP cl, -1
        JNZ SHOW_CARACTER
        ; if not SHOW_CHARACTER, going to NEXT_LINE

    NEXT_LINE:
        POP ax
        ; getting rid of the value of "complete line"
        CALL TOLINE
        MOV cl, [lineIndex]
        INC cl
        MOV [lineIndex], cl
        CMP cl, 6
        JNZ SHOW_LINE
        ; if there is another line to show, show it
        CALL TOLINE
        ; adds a line after showing the grid
        RET
        ; returns outside of showGrid.asm 

    SHOW_GRID:
        MOV BYTE [lineIndex], 0
        ; start by showing the line 0
        ; inconditionally going to SHOW_LINE

    SHOW_LINE:
        MOVZX ecx, BYTE [lineIndex]          
        ; lineIndex on 1 byte so we have to extend zeros to fill ecx
        ; ecx must be filled to then add it with the address of gridA (4 bytes)
        LEA esi, [gridA + ecx]
        ; esi is now pointing to the current line in gridA

        MOV BYTE ah, [esi]
        ; the line is loaded in ah

        LEA esi, [gridB + ecx]
        MOV BYTE al, [esi]
        ; the line of the opponent's grid is loaded in al
        PUSH ax
        ; ax = ah al (="complete line") is pushed on the stack
        MOV BYTE [caracterIndex], 6
        ; starting at the highest for the mask shifting to the left :
        ;       0b01000000
        ;       0b00100000
        ;       ...
        ; inconditionally going to SHOW_CARACTER

    SHOW_CARACTER:
        MOV cl, [caracterIndex]
        MOV bx, 0x0101
        SHL bx, cl                           
        ; mask on both bl and bh to check for the 2 grids
        POP ax
        PUSH ax
        ; "complete line" pushed again for the next iteration
        AND ax, bx
        JZ NOPAWN
        ; if the result of the AND is zero, no pawn is there
        CMP ax, 0x0100
        ; if the raised bit is on the higher byte of ax, it is a A pawn
        JGE APAWN
        JMP BPAWN

