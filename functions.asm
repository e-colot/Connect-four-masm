; --------------------------- CONSTANTS ------------------------------

SYS_EXIT    EQU 1
SYS_READ    EQU 3
SYS_WRITE   EQU 4
STDIN       EQU 2
STDOUT      EQU 1

; ---------------------------- MACROS --------------------------------







section .text
    global SHOW_GRID
    global END_GAME

    extern gridA
    extern gridB
    extern aPawn
    extern bPawn 
    extern noPawn
    extern spaces
    extern toLine
    extern startmsg
    extern lenstartmsg
    extern inputmsg
    leninputmsg
    extern invalidmsg
    extern leninvalidmsg
    extern endmsg
    extern lenendmsg
    extern lineA
    extern lineB
    extern caracterIndex
    extern lineIndex

; ----------------------------- WIN ---------------------------------



; --------------------------- PLAYING --------------------------------

    

; ---------------------- SHOWING THE GRID ----------------------------

    
        
; ---------------------------- END -----------------------------------

    END_GAME:                                ; end the program
        MOV eax, SYS_EXIT
        int 0x80