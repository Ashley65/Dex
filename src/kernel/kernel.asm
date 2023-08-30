org 0x7C00
bits 16
define ENDL, 0x0A, 0x00 ; end of line

start:
    jmp main


; BIOS loads the boot sector into memory at 0x7C00 and jumps to it
main:
    ; setup an data segment
    mov ax, 0x07C0 ; can't use 0x0000 because of the BIOS data
    mov ds, ax
    mov es, ax

    ;setup stack
    mov ss, ax
    mov sp, 0x7C00 ; stack grows down from 0x7C00 to 0x7CFF (256 bytes)

    ; print a message
    mov si, msg_hello ; load the address of the message into SI
    call puts ; call the puts function




    hlt ; halt the CPU


puts:
    ; save registers will be used
    push si
    push ax

; loop through the string until we hit a null byte
.loop:
    lodsb ; load a byte from DS:SI into AL and increment SI
    or al, al ; check if AL is zero
    jz .done ; if zero, jump to done
    mov ah, 0x0E ; tty mode
    int 0x10 ; print the character
    jmp .loop ; loop back

; restore registers
.done:
    pop ax
    pop si
    ret



; print a string
msg_hello: db "Hello World!", 0