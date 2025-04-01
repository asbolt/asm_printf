section .text
    global My_printf

My_printf:      
    push    rbp                                 ; create stack frame
    mov     rbp, rsp

    push    r9                                  ; save arguments
    push    r8                                  ;  
    push    rcx                                 ;    
    push    rdx                                 ; 
    push    rsi                                 ; 
    push    rdi                                 ; 

    mov     rdi, 1                              ; rdi - arguments counter
    pop     rbx                                 ; rbx - string for print 
    lea     rcx, buffer


new_symbol:     
    mov     al, byte [rbx]
    cmp     al, '%'
    jne     not_specifier

    inc     rbx
    inc     rdi
    cmp     rdi, 6                              ; if argument number > 6 get it
    ja      get_stack_argument                  ; from goo stack frame          ------
    pop     r11                                 ;                                    |                                                    
    jmp     get_specifier                       ;                                    |                                                     
                                                ;                                    |    
get_stack_argument:                             ;                                    |                    
    movsx   rax, byte [stack_counter]           ; <----------------------------------|                                        
    inc     byte [stack_counter]
    mov     r11, [rbp + 8 + rax*8]              ; r11 - argument
 
get_specifier:  
    call    Get_specifier
    inc     rbx                                 ; skip specifier in string
    jmp     check_buffer_overflow

not_specifier:  
    mov     byte [rcx], al
    inc     rcx
    inc     rbx
    inc     byte [buf_counter]
    cmp     al, 0                               ; if it is string end, go to end of function
    je      end_my_printf                       ;  

check_buffer_overflow:  
    cmp     byte [buf_counter], byte BUF_SIZE    
    jne     new_symbol
    call    Buf_flush
    jmp     new_symbol

end_my_printf:       
    mov     rax, 1
    mov     rdi, 1
    mov     rsi, buffer
    movsx   rdx, byte [buf_counter]
    syscall

    leave
    ret





;------------------------------------------------------------------------------
; Get specifier: places the value according to the specifier into the buffer
;                (and flushes the buffer on overflow)
;
; Entry:    rbx - address of one-byte specifier
;           rcx - address of the first free buffer cell
;           r11 - address of argument to print 
; Exit:     rcx - new address of the first free buffer cell
; Destr:    rsi
;------------------------------------------------------------------------------
Get_specifier:  
    movsx rsi, byte [rbx]
    dec rsi                                     ; --> needed for correct work of jmp-table:
    lea rax, printf_jmp_table                   ;          empty                                                       
    jmp [rax + 8*rsi]                           ;          ...                              
                                                ;          empty 
                                                ;                         <--- needed address   
percent:    call Get_percent                    ;          our_specifier     
            jmp empty                           ;                         <--- received address, without dec          
                                                    
bin:        mov r12, 2                          ; rbx - base of number system
            call Get_digit
            jmp empty

char:       call Get_char
            jmp empty

dec:        mov r12, 10                         ; r12 - base of number system
            call Get_digit
            jmp empty

oct:        mov r12, 8                          ; r12 - base of number system
            call Get_digit
            jmp empty

string:     call Get_string
            jmp empty

hex:        mov r12, 16                         ; r12 - base of number system
            call Get_digit
            jmp empty

unsig:      mov r12, 10
            call Get_dec_unsig

empty:      ret


;------------------------------------------------------------------------------
; Get percent: part of get specifier, mov '%' into buffer
;
; Entry:    rcx         - address of the first free buffer cell
;           buf_counter - amount occupied cells in buffer 
; Exit:     rcx         - new address of the first free buffer cell
;           buf_counter - new amount occupied cells in buffer 
; Destr:    al
;------------------------------------------------------------------------------
Get_percent:    
    mov     al, '%'
    mov     byte [rcx], al
    inc     rcx
    inc     byte [buf_counter]
    ret



;------------------------------------------------------------------------------
; Get char: part of get specifier, mov char into buffer
;
; Entry:    rcx         - address of the first free buffer cell
;           r11         - address of char
;           buf_counter - amount occupied cells in buffer
; Exit:     rcx         - new address of the first free buffer cell
;           buf_counter - new amount occupied cells in buffer 
; Destr:    None
;------------------------------------------------------------------------------
Get_char:       
    mov     [rcx], r11
    inc     rcx
    inc     byte [buf_counter]
    ret



;------------------------------------------------------------------------------
; Get digit: part of get specifier, mov digit into buffer
;
; Entry:    rcx          - address of the first free buffer cell
;           r11          - address of digit (only int!)
;           r12          - base of number system (2, 8, 10 or 16)
;           sec_buffer   - address of the first empty cell in intermediate buffer
;           BUF_SIZE     - size of buffer
;           INT_BUF_SIZE - size of intermediate buffer
; Exit:     rcx          - new address of the first free buffer cell
;           buf_counter  - amount occupied cells in buffer 
; Destr:    rax
;------------------------------------------------------------------------------
Get_digit:      
    cmp     r12, 10
    je      Get_dec_number                   

    push    r12 
    mov     rax, 0

offset_calc:    
    shr     r12, 1
    inc     rax
    cmp     r12, 0
    jne     offset_calc
    dec     rax
    pop     r12
    dec     r12

    cmp     r11, MAX_SIG_INT                    ; check if digit < 0
    jb      Get_not_dec_number
    push    rax
    mov     rax, r11
    mov     byte [rcx], '-'
    neg     rax
    cwde                                        ; make sig-bit == 0
    inc     rcx
    inc     byte [buf_counter]
    mov     r11, rax
    pop     rax


Get_not_dec_number:           
    lea     r13, sec_buffer + INT_BUF_SIZE - 2   
    push    rcx
    mov     cl, al

not_dec_unsig_num:     
    mov     rdx, r11
    and     rdx, r12
    shr     r11, cl
                
    mov     byte [r13], dl                      ; r13 - current byte in second buffer
    add     byte [r13], '0'
    cmp     byte [r13], '9' + 1
    jb      not_letter
    add     byte [r13], 'a' - '0' - 10          ; skip, if number == [1-9]

not_letter:    
    dec     r13
    cmp     r11, 0
    jne     not_dec_unsig_num
    inc     r13
    pop     rcx
    mov     rax, 0
    jmp     mov_in_buf


Get_dec_number:
    push    rdx
    lea     r13, sec_buffer + INT_BUF_SIZE - 2   
    mov     rax, r11
    mov     rdx, 0                              ;  for div

    cmp     rax, MAX_SIG_INT
    jb      dec_unsig_num
    mov     byte [rcx], '-'
    neg     rax
    cwde                                        ;  make sig-bit == 0
    inc     rcx
    inc     byte [buf_counter]
    jmp     dec_unsig_num

Get_dec_unsig:  
    push    rdx
    lea     r13, sec_buffer + INT_BUF_SIZE - 2   
    mov     rax, r11
    mov     rdx, 0

dec_unsig_num:      
    div     r12
    mov     byte [r13], dl
    add     byte [r13], '0'

    mov     rdx, 0
    dec     r13
    cmp     rax, 0
    jne     dec_unsig_num
    inc     r13

mov_in_buf:     
    mov     al, [r13]                           ; mov number from sec_buffer to buffer
    mov     byte [rcx], al
    inc     r13
    inc     rcx
    inc     byte [buf_counter]
    cmp     al, 0
    je      end_digit2

    cmp     byte [buf_counter], byte BUF_SIZE
    jb      mov_in_buf
    push    r11
    call    Buf_flush
    pop     r11
    jmp     mov_in_buf

end_digit2:        
    dec     byte [buf_counter]
    dec     rcx
    pop     rdx
    ret



;------------------------------------------------------------------------------
; Get string: part of get specifier, mov string into buffer
;
; Entry:    rcx         - address of the first free buffer cell
;           r11         - address of string (ending with '\0'!)
; Exit:     rcx         - new address of the first free buffer cell
;           buf_counter - amount occupied cells in buffer 
; Destr:    al
;------------------------------------------------------------------------------

Get_string:     
    mov     al, byte [r11]                      ; copy byte argument -> byte buffer,
    mov     byte [rcx], al                      ; while it isn't string end
    inc     rcx                                 ;  
    inc     r11                                 ;  
    inc     byte [buf_counter]                  ;   
    cmp     al, 0                               ;  
    je      end_string                          ;   

    cmp     byte [buf_counter], byte BUF_SIZE
    jb      Get_string
    push    r11
    call    Buf_flush
    pop     r11
    jmp     Get_string

end_string:     
    dec     rcx
    dec     byte [buf_counter]            
    ret



;------------------------------------------------------------------------------
; Buffer flush
;
; Entry:    BUF_SIZE    - size of buffer
;           buffer      - address of first buffer cell
; Exit:     rcx         - new address of the first free buffer cell (== &buffer)
;           buf_counter - new amount occupied cells in buffer (== 0) 
; Destr:    rax, rdi, rsi, rdx
;------------------------------------------------------------------------------

Buf_flush:      
    mov     rax, 1                  
    mov     rdi, 1                  
    mov     rsi, buffer             
    mov     rdx, BUF_SIZE           
    syscall

    mov     byte [buf_counter], 0
    lea     rcx, buffer
    ret  



;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
section .data
    BUF_SIZE        equ 50
    INT_BUF_SIZE    equ 20
    MAX_SIG_INT     equ 2147483647

    buf_counter db 0
    arg_counter db 1
    stack_counter db 1

    printf_jmp_table:
        times ('%' - 1)         dq empty
                                dq percent
        times ('b' - '%' - 1)   dq empty
                                dq bin
                                dq char
                                dq dec
        times ('o' - 'd' - 1)   dq empty
                                dq oct
        times ('s' - 'o' - 1)   dq empty
                                dq string
        times ('u' - 's' - 1)   dq empty
                                dq unsig     
        times ('x' - 'u' - 1)   dq empty         
                                dq hex



;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
section .bss
    buffer      resb BUF_SIZE
    sec_buffer  resb INT_BUF_SIZE

    arguments:
        one     resq 1
        two     resq 1
        three   resq 1
        four    resq 1
        five    resq 1
        six     resq 1