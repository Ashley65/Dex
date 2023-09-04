bits 16

section _TEXT class code align 16

global _x86_Video_WriteChar

_x86_Video_WriteChar:
    push ebp
    mov ebp, esp

    push bx

    mov ah , 0Eh
    mov al, [ebp+8]
    mov bh, [ebp+12]

    int 10h

    pop bx

    mov esp, ebp
    pop ebp
    ret




