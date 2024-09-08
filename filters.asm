; checks if the byte in dh contains pawns in a row


section .rodata
    jumpTable:
        dq FILTER4_0
        dq FILTER4_1
        dq FILTER4_2
        dq FILTER4_3
        dq FILTER4_4
        dq FILTER4_5
        dq FILTER4_6
        
    jumpTablePoints:
        dq FILTER3_0
        dq FILTER3_1
        dq FILTER3_2
        dq FILTER3_3
        dq FILTER3_4
        dq FILTER3_5
        dq FILTER3_6
section .text

    global jumpTable

    extern ALIGNED_4
    extern ALIGNED_3
    extern CALL_TABLE

; -------------------------- FILTERING 4 PROCESSUS --------------------------

    FILTER4_4:        
        MOV al, dl
        AND al, 0b0011110
        CMP al, 0b0011110
        JZ ALIGNED_4
        ; if 4 pawns are aligned

    FILTER4_5:          
        MOV al, dl
        AND al, 0b0111100
        CMP al, 0b0111100
        JZ ALIGNED_4
        ; if 4 pawns are aligned

    FILTER4_6:        
        MOV al, dl
        AND al, 0b1111000
        CMP al, 0b1111000
        JZ ALIGNED_4
        ; if 4 pawns are aligned
        
        ; if it is not a real move
        TEST dh, 0b10000000
        JNZ CHECK_FOR_3

        RET
        ; returns to the next check in CHECK_FOR_WIN

    FILTER4_3:          
        MOV al, dl
        AND al, 0b1111000
        CMP al, 0b1111000
        JZ ALIGNED_4
        ; if 4 pawns are aligned

    FILTER4_2:          
        MOV al, dl
        AND al, 0b0111100
        CMP al, 0b0111100
        JZ ALIGNED_4
        ; if 4 pawns are aligned

    FILTER4_1:          
        MOV al, dl
        AND al, 0b0011110
        CMP al, 0b0011110
        JZ ALIGNED_4
        ; if 4 pawns are aligned

    FILTER4_0:        
        MOV al, dl
        AND al, 0b0001111
        CMP al, 0b0001111
        JZ ALIGNED_4
        ; if 4 pawns are aligned

        ; if it is not a real move
        TEST dh, 0b10000000
        JNZ CHECK_FOR_3

        RET
        ; returns to the next check in CHECK_FOR_WIN


; -------------------------- FILTERING 3 PROCESSUS --------------------------

    CHECK_FOR_3:
        MOV rbx, jumpTablePoints
        JMP CALL_TABLE
        ; (informatively, the last stack element leads to the next check in CHECK_FOR_WIN)
        ; so each of the FILTER3 must finish with a RET

    FILTER3_4:        
        MOV al, dl
        AND al, 0b0011100
        CMP al, 0b0011100
        JZ ALIGNED_3
        ; if 3 pawns are aligned

    FILTER3_5:        
        MOV al, dl
        AND al, 0b0111000
        CMP al, 0b0111000
        JZ ALIGNED_3
        ; if 3 pawns are aligned

    FILTER3_6:        
        MOV al, dl
        AND al, 0b1110000
        CMP al, 0b1110000
        JZ ALIGNED_3
        ; if 3 pawns are aligned

        RET
        ; returns to the next check in CHECK_FOR_WIN

    FILTER3_3:        
        MOV al, dl
        AND al, 0b0111000
        CMP al, 0b0111000
        JZ ALIGNED_3
        ; if 3 pawns are aligned
        
        MOV al, dl
        AND al, 0b0011100
        CMP al, 0b0011100
        JZ ALIGNED_3
        ; if 3 pawns are aligned
        
        MOV al, dl
        AND al, 0b0001110
        CMP al, 0b0001110
        JZ ALIGNED_3
        ; if 3 pawns are aligned

        RET
        ; returns to the next check in CHECK_FOR_WIN

    FILTER3_2:        
        MOV al, dl
        AND al, 0b0011100
        CMP al, 0b0011100
        JZ ALIGNED_3
        ; if 3 pawns are aligned

    FILTER3_1:        
        MOV al, dl
        AND al, 0b0001110
        CMP al, 0b0001110
        JZ ALIGNED_3
        ; if 3 pawns are aligned

    FILTER3_0:        
        MOV al, dl
        AND al, 0b0000111
        CMP al, 0b0000111
        JZ ALIGNED_3
        ; if 3 pawns are aligned

        RET
        ; returns to the next check in CHECK_FOR_WIN

