section .data
    BUF_SIZE equ 10
    INT_BUF_SIZE equ 20
    buf_counter db 0

    str: db 'hi-hi %d ha-ha', 10, 0
    argument dd -13789

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



section .bss
    buffer resb BUF_SIZE
    result resb INT_BUF_SIZE



section .text
                global _start

_start:         push argument
                lea rbx, str
                lea rcx, buffer

new_symbol:     mov al, byte [rbx]
                cmp al, '%'
                jne not_specifier

                inc rbx
                pop r11
                push rax
                call Get_specifier
                pop rax
                inc rbx

                jmp new_symbol


not_specifier:  mov byte [rcx], al
                inc rcx
                inc rbx
                inc byte [buf_counter]
                cmp al, 0
                je print

                cmp byte [buf_counter], BUF_SIZE
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





;------------------------------------------------
; Get specifier: places the value according to the specifier into the buffer
;                (and flushes the buffer on overflow)
;
; Entry:    rbx - address of one-byte specifier
;           rcx - address of the first free buffer cell
;           r11 - address of argument to print 
; Exit:     rcx - new address of the first free buffer cell
; Destr:    rsi
;------------------------------------------------
Get_specifier:  movsx rsi, byte [rbx]
                dec rsi
                lea rax, printf_jmp_table
                jmp [rax + 8*rsi]

percent:        call Get_percent
                jmp empty

bin:            mov r12, 2
                call Get_digit
                jmp empty

char:           call Get_char
                jmp empty

dec:            mov r12, 10
                call Get_digit
                jmp empty

oct:            mov r12, 8
                call Get_digit
                jmp empty

string:         call Get_string
                jmp empty

hex:            mov r12, 16
                call Get_digit

empty:          ret


;------------------------------------------------
; Get percent: part of get specifier, mov '%' into buffer
;
; Entry:    rcx         - address of the first free buffer cell
; Exit:     rcx         - new address of the first free buffer cell
;           buf_counter - amount occupied cells in buffer 
; Destr:    al
;------------------------------------------------
Get_percent:    mov al, '%'
                mov byte [rcx], al
                inc rcx
                inc byte [buf_counter]
                ret



;------------------------------------------------
; Get char: part of get specifier, mov '%' into buffer
;
; Entry:    rcx         - address of the first free buffer cell
;           r11         - address of char
; Exit:     rcx         - new address of the first free buffer cell
;           buf_counter - amount occupied cells in buffer 
; Destr:    al
;------------------------------------------------
Get_char:       mov al, byte [r11]
                mov byte [rcx], al
                inc rcx
                inc byte [buf_counter]
                ret



;------------------------------------------------
; Get char: part of get specifier, mov digit into buffer
;
; Entry:    rcx          - address of the first free buffer cell
;           r11          - address of digit (only int!)
;           result       - address of the first empty cell in intermediate buffer
;           BUF_SIZE     - size of buffer
;           INT_BUF_SIZE - size of intermediate buffer
; Exit:     rcx          - new address of the first free buffer cell
;           buf_counter  - amount occupied cells in buffer 
; Destr:    al
;------------------------------------------------
Get_digit:      
                push rax
                push rdx
                lea r13, result + 18
                movsx rax, dword [r11]

                cmp dword [r11], 0
                jb Next
                mov byte [rcx], '-' 
                inc rcx
                inc byte [buf_counter]
                neg rax

Next:           div r12
                mov byte [r13], dl
                add byte [r13], '0'
                cmp byte [r13], ':'
                jb Next2
                add byte [r13], 'a' - '0' - 10

Next2           mov rdx, 0
                dec r13
                cmp rax, 0
                jne Next

                inc r13

Next1:          mov al, [r13]
                mov byte [rcx], al
                inc r13
                inc rcx
                inc byte [buf_counter]
                cmp al, 0
                jne Next1

                dec rcx
                pop rdx
                pop rax
                ret



;------------------------------------------------
; Get string: part of get specifier, mov string into buffer
;
; Entry:    rcx         - address of the first free buffer cell
;           r11         - address of string (ending with '\0'!)
; Exit:     rcx         - new address of the first free buffer cell
;           buf_counter - amount occupied cells in buffer 
; Destr:    al
;------------------------------------------------
Get_string:     
get_string:     mov al, byte [r11]
                mov byte [rcx], al
                inc rcx
                inc r11
                inc byte [buf_counter]
                cmp al, 0
                jne get_string

dd:             dec rcx
                dec byte [buf_counter]
                
                ret                        ;// TODO почему-то работает, если строка больше размера буффера

Buf_flush:      mov rax, 1
                mov rdi, 1
                mov rsi, buffer
                mov rdx, BUF_SIZE
                syscall

                mov byte [buf_counter], 0
                lea rcx, buffer
                ret  


                ;// TODO почему-то работает, если спецификатор вылезает за пределы буффера