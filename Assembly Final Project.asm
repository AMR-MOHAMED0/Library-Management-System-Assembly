;===============================================================================
; PROJECT: Library Management System (LMS) - FINAL MASTER VERSION
; MANSOURA UNIVERSITY - CS DEPT - YEAR 3
;===============================================================================
; FEATURES:
; 1. Robust Menu Input: Ignores empty ENTER key (0DH).
; 2. Strict Numeric Validation: Rejects non-numeric input for IDs/Choices.
; 3. Delete Function: Correct memory shifting logic for data removal.
; 4. Professional Header: FCIS Mansoura University branding.
;===============================================================================

.MODEL SMALL
.STACK 100h

.DATA
    ; --- CONSTANTS ---
    MAX_BOOKS       EQU 10
    TITLE_SIZE      EQU 20          

    ; --- DATA ARRAYS ---
    IDS             DW MAX_BOOKS DUP(0)             
    TITLES          DB MAX_BOOKS * TITLE_SIZE DUP('$') 
    STATUS          DB MAX_BOOKS DUP(0)             

    ; --- GLOBAL VARIABLES ---
    COUNT           DW 0                                
    CURRENT_INDEX   DW 0  
    PARSE_ERR_FLAG  DB 0   ; Flag: 0=Success, 1=Error                              
    
    ; --- INPUT BUFFERS ---
    IN_ID_BUF       DB 6, ?, 6 DUP('$')             
    IN_TITLE_BUF    DB 20, ?, 20 DUP('$')            
    NEW_LINE        DB 0DH, 0AH, '$'

    ; --- UI STRINGS ---
    MENU_MSG        DB 0DH, 0AH, 0DH, 0AH
                    DB '      MANSOURA UNIVERSITY       ', 0DH, 0AH
                    DB '  FCIS - LIBRARY MASTER SYSTEM  ', 0DH, 0AH
                    DB '--------------------------------', 0DH, 0AH
                    DB '1. Add New Book', 0DH, 0AH
                    DB '2. Show All Books', 0DH, 0AH
                    DB '3. Borrow Book', 0DH, 0AH
                    DB '4. Return Book', 0DH, 0AH
                    DB '5. Delete Book', 0DH, 0AH 
                    DB '6. Exit System', 0DH, 0AH
                    DB '--------------------------------', 0DH, 0AH
                    DB 'Enter Choice (1-6): $'
    
    MSG_INVALID     DB 0DH, 0AH, '>> ERROR: Invalid choice! Use 1-6.', '$'
    MSG_NAN         DB 0DH, 0AH, '>> ERROR: ID must be NUMBERS only!', '$'
    MSG_EMPTY_IN    DB 0DH, 0AH, '>> ERROR: Input cannot be empty!', '$'
    
    MSG_ENTER_ID    DB 0DH, 0AH, 'Enter Book ID (Numeric): $'
    MSG_ENTER_TITLE DB 0DH, 0AH, 'Enter Title (max 19 chars): $'
    
    MSG_ADDED       DB 0DH, 0AH, 'SUCCESS: Book Added!', '$'
    MSG_DELETED     DB 0DH, 0AH, 'SUCCESS: Book Deleted & List Shifted!', '$'
    MSG_FULL        DB 0DH, 0AH, 'ERROR: Library is Full!', '$'
    MSG_EMPTY       DB 0DH, 0AH, 'NOTICE: Library is empty.', '$'
    MSG_NOT_FOUND   DB 0DH, 0AH, 'ERROR: ID Not Found.', '$'
    MSG_BORROWED    DB 0DH, 0AH, 'SUCCESS: Marked as BORROWED.', '$'
    MSG_RETURNED    DB 0DH, 0AH, 'SUCCESS: Marked as AVAILABLE.', '$'
    MSG_PRESS_KEY   DB 0DH, 0AH, 0DH, 0AH, '>> Press any key to continue...$'
    
    HEADER_MSG      DB 0DH, 0AH, 'ID    | STATUS    | TITLE', 0DH, 0AH
                    DB '---------------------------------', 0DH, 0AH, '$'
    TXT_AVAIL       DB 'Available ', '$'
    TXT_BORR        DB 'Borrowed  ', '$'
    SEPARATOR       DB ' | ', '$'

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX      ; Critical for string operations (MOVSB)

MAIN_LOOP:
    CALL CLEAR_SCREEN

    MOV DX, OFFSET MENU_MSG
    MOV AH, 09H
    INT 21H

    ; --- SAFE MENU INPUT ---
    MOV AH, 01H
    INT 21H

    ; 1. Handle Empty Enter
    CMP AL, 0DH
    JE MAIN_LOOP    

    ; 2. Validate Range
    CMP AL, '1'
    JB MENU_ERROR 
    CMP AL, '6'
    JA MENU_ERROR 

    ; 3. Route
    SUB AL, '0'
    CMP AL, 1
    JE DO_ADD
    CMP AL, 2
    JE DO_SHOW
    CMP AL, 3
    JE DO_BORROW
    CMP AL, 4
    JE DO_RETURN
    CMP AL, 5
    JE DO_DELETE
    CMP AL, 6
    JE DO_EXIT
    
    JMP MAIN_LOOP

MENU_ERROR:
    MOV DX, OFFSET MSG_INVALID
    MOV AH, 09H
    INT 21H
    CALL WAIT_KEY
    JMP MAIN_LOOP

; --- JUMP TABLE WRAPPERS ---
DO_ADD:
    CALL ADD_BOOK
    CALL WAIT_KEY     
    JMP MAIN_LOOP
DO_SHOW:
    CALL SHOW_BOOKS
    CALL WAIT_KEY
    JMP MAIN_LOOP
DO_BORROW:
    CALL BORROW_BOOK
    CALL WAIT_KEY
    JMP MAIN_LOOP
DO_RETURN:
    CALL RETURN_BOOK
    CALL WAIT_KEY
    JMP MAIN_LOOP
DO_DELETE:
    CALL DELETE_BOOK
    CALL WAIT_KEY
    JMP MAIN_LOOP
DO_EXIT:
    MOV AH, 4CH
    INT 21H
MAIN ENDP

;===============================================================================
; LOGIC PROCEDURES
;===============================================================================

ADD_BOOK PROC
    MOV AX, COUNT
    CMP AX, MAX_BOOKS
    JAE AB_FULL

    ; 1. Get ID with Validation
AB_GET_ID:
    MOV DX, OFFSET MSG_ENTER_ID
    MOV AH, 09H
    INT 21H
    
    MOV DX, OFFSET IN_ID_BUF
    MOV AH, 0AH
    INT 21H
    
    CALL PARSE_INPUT_ID
    CMP PARSE_ERR_FLAG, 1
    JE AB_GET_ID    
    
    ; Save ID
    MOV SI, COUNT
    ADD SI, SI       
    MOV IDS[SI], AX

    ; 2. Get Title
    MOV DX, OFFSET MSG_ENTER_TITLE
    MOV AH, 09H
    INT 21H
    
    MOV DX, OFFSET IN_TITLE_BUF
    MOV AH, 0AH
    INT 21H

    ; Save Title (Block Copy)
    MOV AX, COUNT
    MOV BX, TITLE_SIZE
    MUL BX          ; AX = Offset in TITLES array
    MOV DI, AX       
    
    LEA BX, TITLES
    ADD BX, DI      ; BX points to destination in TITLES
    
    MOV SI, OFFSET IN_TITLE_BUF + 2 
    MOV CL, [IN_TITLE_BUF + 1]      
    MOV CH, 0
    
    ; Handle Empty Title input
    CMP CX, 0
    JE AB_TITLE_DONE
    
AB_COPY_LOOP:
    MOV AL, [SI]
    MOV [BX], AL
    INC SI
    INC BX
    LOOP AB_COPY_LOOP
    
AB_TITLE_DONE:
    MOV BYTE PTR [BX], '$' ; Null terminate

    ; 3. Init Status (0 = Available)
    MOV SI, COUNT
    MOV STATUS[SI], 0

    INC COUNT
    
    MOV DX, OFFSET MSG_ADDED
    MOV AH, 09H
    INT 21H
    RET

AB_FULL:
    MOV DX, OFFSET MSG_FULL
    MOV AH, 09H
    INT 21H
    RET
ADD_BOOK ENDP

DELETE_BOOK PROC
    CMP COUNT, 0
    JE DEL_EMPTY

    ; 1. Input ID to Delete
    MOV DX, OFFSET MSG_ENTER_ID
    MOV AH, 09H
    INT 21H

    MOV DX, OFFSET IN_ID_BUF
    MOV AH, 0AH
    INT 21H

    CALL PARSE_INPUT_ID
    CMP PARSE_ERR_FLAG, 1
    JE DEL_RET

    ; 2. Search for ID
    MOV CX, COUNT
    MOV SI, 0       ; SI represents the Index (0, 1, 2...)

DEL_SEARCH_LOOP:
    MOV DI, SI
    ADD DI, DI      ; DI = SI * 2 (for Word Array)
    CMP IDS[DI], AX
    JE DEL_FOUND
    INC SI
    LOOP DEL_SEARCH_LOOP
    
    MOV DX, OFFSET MSG_NOT_FOUND
    MOV AH, 09H
    INT 21H
    RET

DEL_FOUND:
    ; SI is the index of the book to remove.
    ; We need to shift everything from SI+1 up to COUNT-1 down by one slot.
    
    ; Calculate Items to Shift: CX = COUNT - 1 - SI
    MOV CX, COUNT
    DEC CX
    SUB CX, SI
    
    ; If CX is 0 (deleting the last item), skip shifting.
    CMP CX, 0
    JE DEL_DECREMENT

    ; --- SHIFTING LOOP ---
DEL_SHIFT_LOOP:
    PUSH CX
    PUSH SI 
    
    ; A. Shift ID (Word)
    ; Move IDS[SI+1] to IDS[SI]
    MOV DI, SI
    INC DI          ; DI = Next Index
    
    ADD SI, SI      ; SI as offset
    ADD DI, DI      ; DI as offset
    
    MOV AX, IDS[DI]
    MOV IDS[SI], AX
    
    POP SI          ; Restore raw index
    PUSH SI
    
    ; B. Shift Status (Byte)
    ; Move STATUS[SI+1] to STATUS[SI]
    MOV AL, STATUS[SI+1]
    MOV STATUS[SI], AL
    
    ; C. Shift Title (20 Bytes)
    ; Destination: TITLES + (SI * 20)
    ; Source:      TITLES + ((SI+1) * 20)
    
    ; Calc Dest Address
    MOV AX, SI
    MOV BX, TITLE_SIZE
    MUL BX
    LEA DI, TITLES
    ADD DI, AX      ; ES:DI = Dest
    
    ; Calc Source Address
    MOV AX, SI
    INC AX
    MOV BX, TITLE_SIZE
    MUL BX
    LEA SI, TITLES  ; Note: Reusing SI register locally for source pointer
    ADD SI, AX      ; DS:SI = Source
    
    MOV CX, TITLE_SIZE
    CLD
    REP MOVSB       ; Copy 20 bytes
    
    POP SI          ; Restore Loop Index
    POP CX          ; Restore Loop Counter
    
    INC SI          ; Move to next slot
    LOOP DEL_SHIFT_LOOP

DEL_DECREMENT:
    DEC COUNT
    MOV DX, OFFSET MSG_DELETED
    MOV AH, 09H
    INT 21H
DEL_RET:
    RET

DEL_EMPTY:
    MOV DX, OFFSET MSG_EMPTY
    MOV AH, 09H
    INT 21H
    RET
DELETE_BOOK ENDP

SHOW_BOOKS PROC
    CMP COUNT, 0
    JE SHOW_EMPTY_MSG

    MOV DX, OFFSET HEADER_MSG
    MOV AH, 09H
    INT 21H

    MOV CX, COUNT
    MOV CURRENT_INDEX, 0

SHOW_LOOP:
    PUSH CX         

    ; Print ID
    MOV SI, CURRENT_INDEX
    ADD SI, SI
    MOV AX, IDS[SI]
    CALL PRINT_NUM_AX
    
    MOV DX, OFFSET SEPARATOR
    MOV AH, 09H
    INT 21H

    ; Print Status
    MOV SI, CURRENT_INDEX
    MOV AL, STATUS[SI]
    CMP AL, 0
    JE PR_AVAIL
    MOV DX, OFFSET TXT_BORR
    JMP PR_STAT_DONE
PR_AVAIL:
    MOV DX, OFFSET TXT_AVAIL
PR_STAT_DONE:
    MOV AH, 09H
    INT 21H

    MOV DX, OFFSET SEPARATOR
    MOV AH, 09H
    INT 21H

    ; Print Title
    MOV AX, CURRENT_INDEX
    MOV BX, TITLE_SIZE
    MUL BX
    LEA DX, TITLES
    ADD DX, AX      
    MOV AH, 09H
    INT 21H

    MOV DX, OFFSET NEW_LINE
    MOV AH, 09H
    INT 21H

    INC CURRENT_INDEX
    POP CX           
    LOOP SHOW_LOOP
    RET

SHOW_EMPTY_MSG:
    MOV DX, OFFSET MSG_EMPTY
    MOV AH, 09H
    INT 21H
    RET
SHOW_BOOKS ENDP

BORROW_BOOK PROC
    MOV DX, OFFSET MSG_ENTER_ID
    MOV AH, 09H
    INT 21H
    MOV DX, OFFSET IN_ID_BUF
    MOV AH, 0AH
    INT 21H
    
    CALL PARSE_INPUT_ID
    CMP PARSE_ERR_FLAG, 1
    JE BB_RET
    
    MOV CX, COUNT
    MOV SI, 0       
BB_SEARCH:
    MOV DI, SI
    ADD DI, DI
    CMP IDS[DI], AX
    JE BB_FOUND
    INC SI
    LOOP BB_SEARCH
    
    MOV DX, OFFSET MSG_NOT_FOUND
    MOV AH, 09H
    INT 21H
    RET
BB_FOUND:
    MOV STATUS[SI], 1   
    MOV DX, OFFSET MSG_BORROWED
    MOV AH, 09H
    INT 21H
BB_RET:
    RET
BORROW_BOOK ENDP

RETURN_BOOK PROC
    MOV DX, OFFSET MSG_ENTER_ID
    MOV AH, 09H
    INT 21H
    MOV DX, OFFSET IN_ID_BUF
    MOV AH, 0AH
    INT 21H
    
    CALL PARSE_INPUT_ID
    CMP PARSE_ERR_FLAG, 1
    JE RB_RET
    
    MOV CX, COUNT
    MOV SI, 0
RB_SEARCH:
    MOV DI, SI
    ADD DI, DI
    CMP IDS[DI], AX
    JE RB_FOUND
    INC SI
    LOOP RB_SEARCH
    
    MOV DX, OFFSET MSG_NOT_FOUND
    MOV AH, 09H
    INT 21H
    RET
RB_FOUND:
    MOV STATUS[SI], 0   
    MOV DX, OFFSET MSG_RETURNED
    MOV AH, 09H
    INT 21H
RB_RET:
    RET
RETURN_BOOK ENDP

;===============================================================================
; UTILITIES & VALIDATION
;===============================================================================

CLEAR_SCREEN PROC
    MOV AH, 00H
    MOV AL, 03H      
    INT 10H
    RET
CLEAR_SCREEN ENDP

WAIT_KEY PROC
    MOV DX, OFFSET MSG_PRESS_KEY
    MOV AH, 09H
    INT 21H
    MOV AH, 07H      
    INT 21H
    RET
WAIT_KEY ENDP

PARSE_INPUT_ID PROC
    ; Reads IN_ID_BUF, validates numeric, returns AX = Number
    ; Sets PARSE_ERR_FLAG = 1 if invalid
    
    MOV PARSE_ERR_FLAG, 0
    
    ; Check Empty
    MOV CL, [IN_ID_BUF + 1]
    CMP CL, 0
    JE PI_EMPTY

    ; Check Non-Numeric
    MOV SI, OFFSET IN_ID_BUF + 2
    MOV CH, 0
    PUSH CX
PI_SCAN:
    MOV AL, [SI]
    CMP AL, '0'
    JB PI_NAN
    CMP AL, '9'
    JA PI_NAN
    INC SI
    LOOP PI_SCAN
    POP CX

    ; Parse
    MOV SI, OFFSET IN_ID_BUF + 2
    MOV AX, 0
    MOV BX, 10
PI_CONVERT:
    MUL BX          
    MOV DL, [SI]
    SUB DL, '0'
    MOV DH, 0
    ADD AX, DX
    INC SI
    LOOP PI_CONVERT
    RET

PI_NAN:
    POP CX
    MOV DX, OFFSET MSG_NAN
    MOV AH, 09H
    INT 21H
    MOV PARSE_ERR_FLAG, 1
    RET
PI_EMPTY:
    MOV DX, OFFSET MSG_EMPTY_IN
    MOV AH, 09H
    INT 21H
    MOV PARSE_ERR_FLAG, 1
    RET
PARSE_INPUT_ID ENDP

PRINT_NUM_AX PROC
    ; Prints value in AX
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV CX, 0
    MOV BX, 10
PN_DIV_LOOP:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE PN_DIV_LOOP
    
PN_PRT_LOOP:
    POP DX
    ADD DL, '0'
    MOV AH, 02H
    INT 21H
    LOOP PN_PRT_LOOP
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUM_AX ENDP

END MAIN