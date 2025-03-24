section .text
                global My_printf

My_printf:      mov qword [one], rdi                    ;  save arguments
                mov qword [two], rsi                    ;  
                mov qword [three], rdx                  ;    
                mov qword [four], rcx                   ; 
                mov qword [five], r8                    ; 
                mov qword [six], r9                     ; 

                mov rbx, qword [one]
                lea rcx, buffer


new_symbol:     mov al, byte [rbx]
                cmp al, '%'
                jne not_specifier

                inc rbx

                cmp byte [arg_counter], 5               ;  if number of argument <= 6,
                ja stack_arg                            ;  get it from reg
                movsx rax, byte [arg_counter]           ;    
                sal rax, 3                              ;  if number of argument > 6,
                lea r8, arguments                       ;  get it from stack          ---|
                add rax, r8                             ;                                |
                mov r11, [rax]                          ;                                |    
                inc byte [arg_counter]                  ;                                |    
                jmp get_specifier                       ;                                |           
                                                        ;                                |    
stack_arg:      pop r11                                 ;  <-----------------------------|    
 
get_specifier:  call Get_specifier
                inc rbx                                 ;  skip specifier in string
                jmp check_overflw

not_specifier:  mov byte [rcx], al
                inc rcx
                inc rbx
                inc byte [buf_counter]
                cmp al, 0                               ;  if it is string end, go to end of function
                je print                                ;  

check_overflw:  cmp byte [buf_counter], byte BUF_SIZE    
                jne new_symbol
                call Buf_flush
                jmp new_symbol


print:          mov rax, 1
                mov rdi, 1
                mov rsi, buffer
                movsx rdx, byte [buf_counter]
                syscall

                mov rax, 60
                mov rdi, 0
                syscall





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
Get_specifier:  movsx rsi, byte [rbx]
                dec rsi                                 ;  --> needed for correct work of jmp-table:
                lea rax, printf_jmp_table               ;           empty                                                       
                jmp [rax + 8*rsi]                       ;           ...                              
                                                        ;           empty 
                                                        ;                          <--- needed address   
percent:        call Get_percent                        ;           our_specifier     
                jmp empty                               ;                          <--- received address, without dec          
                                                       
bin:            mov r12, 2                              ;  rbx - base of number system
                call Get_digit
                jmp empty

char:           call Get_char
                jmp empty

dec:            mov r12, 10                             ;  rbx - base of number system
                call Get_digit
                jmp empty

oct:            mov r12, 8                              ;  rbx - base of number system
                call Get_digit
                jmp empty

string:         call Get_string
                jmp empty

hex:            mov r12, 16                             ;  rbx - base of number system
                call Get_digit

empty:          ret


;------------------------------------------------------------------------------
; Get percent: part of get specifier, mov '%' into buffer
;
; Entry:    rcx         - address of the first free buffer cell
;           buf_counter - amount occupied cells in buffer 
; Exit:     rcx         - new address of the first free buffer cell
;           buf_counter - new amount occupied cells in buffer 
; Destr:    al
;------------------------------------------------------------------------------
Get_percent:    mov al, '%'
                mov byte [rcx], al
                inc rcx
                inc byte [buf_counter]
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
Get_char:       mov [rcx], r11
                inc rcx
                inc byte [buf_counter]
                ret



;------------------------------------------------------------------------------
; Get digit: part of get specifier, mov digit into buffer
;
; Entry:    rcx          - address of the first free buffer cell
;           r11          - address of digit (only int!)
;           r12          - base of number system (2, 8, 10 or 16)
;           int_buffer   - address of the first empty cell in intermediate buffer
;           BUF_SIZE     - size of buffer
;           INT_BUF_SIZE - size of intermediate buffer
; Exit:     rcx          - new address of the first free buffer cell
;           buf_counter  - amount occupied cells in buffer 
; Destr:    rax
;------------------------------------------------------------------------------
Get_digit:      push rdx
                lea r13, int_buffer + INT_BUF_SIZE - 2   
                mov rax, r11

                mov rdx, 0                              ;  for div

                cmp rax, MAX_SIG_INT
                jb unsig_num
                mov byte [rcx], '-'
                neg rax
                cwde                                    ;  make sig-bit == 0
                inc rcx
                inc byte [buf_counter]

unsig_num:      div r12
                mov byte [r13], dl
                add byte [r13], '0'
                cmp byte [r13], '9' + 1
                jb not_letter
                add byte [r13], 'a' - '0' - 10          ;  skip, if number == [1-9]

not_letter:     mov rdx, 0
                dec r13
                cmp rax, 0
                jne unsig_num
                inc r13

mov_in_buf:     mov al, [r13]                           ;  mov number from int_buffer to buffer
                mov byte [rcx], al
                inc r13
                inc rcx
                inc byte [buf_counter]
                cmp al, 0
                je end_num

                cmp byte [buf_counter], byte BUF_SIZE
                jb mov_in_buf
                push r11
                call Buf_flush
                pop r11
                jmp mov_in_buf

end_num:        dec byte [buf_counter]
                dec rcx
                pop rdx
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

Get_string:     mov al, byte [r11]                      ;  copy byte argument -> byte buffer,
                mov byte [rcx], al                      ;  while it isn't string end
                inc rcx                                 ;  
                inc r11                                 ;  
                inc byte [buf_counter]                  ;   
                cmp al, 0                               ;  
                je end_string                           ;   

                cmp byte [buf_counter], byte BUF_SIZE
                jb Get_string
                push r11
                call Buf_flush
                pop r11
                jmp Get_string

end_string:     dec rcx
                dec byte [buf_counter]            
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

Buf_flush:      mov rax, 1                  
                mov rdi, 1                  
                mov rsi, buffer             
                mov rdx, BUF_SIZE           
                syscall

                mov byte [buf_counter], 0
                lea rcx, buffer
                ret  



;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
section .data
    BUF_SIZE        equ 50
    INT_BUF_SIZE    equ 20
    MAX_SIG_INT     equ 2147483647

    buf_counter db 0
    arg_counter db 1

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
        times ('x' - 's' - 1)   dq empty         
                                dq hex



;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
section .bss
    buffer      resb BUF_SIZE
    int_buffer  resb INT_BUF_SIZE

    arguments:
        one     resq 1
        two     resq 1
        three   resq 1
        four    resq 1
        five    resq 1
        six     resq 1