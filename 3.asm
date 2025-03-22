section .bss
    buffer resb 10

section .data
    str: db '%%c%b%sf', 10
    g: db 'hihi', 10

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

section .text
                global _start

_start:         lea rbx, str
                lea rcx, buffer

new_symbol:     mov al, byte [rbx]
                cmp al, '%'
                jne not_specifier

                inc rbx
                push rax
                call Get_specifier
                pop rax
                inc rbx
                jmp new_symbol

not_specifier:  mov byte [rcx], al
                inc rcx
                inc rbx
                cmp al, 10
                jne new_symbol

                mov rax, 1
                mov rdi, 1
                mov rsi, buffer
                mov rdx, 10
                syscall

                mov rax, 60
                mov rdi, 0
                syscall






Get_specifier:  movsx rsi, byte [rbx]
                dec rsi
                lea rax, printf_jmp_table
                jmp [rax + 8*rsi]

percent:        call Get_percent
                jmp empty

bin:            call Get_digit
                jmp empty

char:           call Get_char
                jmp empty

dec:            call Get_digit
                jmp empty

oct:            call Get_digit
                jmp empty

string:         call Get_string
                jmp empty

hex:            call Get_digit

empty:        ret



Get_percent:    mov [rcx], byte 'A'
                inc rcx
                jmp empty
                ret

Get_char:       mov [rcx], byte 'B'
                inc rcx
                jmp empty
                ret

Get_digit:      mov [rcx], byte 'C'
                inc rcx
                jmp empty
                ret

Get_string:     mov [rcx], byte 'D'
                inc rcx
                jmp empty
                ret
