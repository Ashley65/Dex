org 0x7C00
bits 16
define ENDL 0x0D, 0x0A ; end of line

;BIOS Parameter Block

;FAT12 Header (BIOS Parameter Block) (13 bytes) ref: https://wiki.osdev.org/FAT
JMP short start ; Jump instruction
nop ; NOP instruction
bpbOEM:             db MyOS ; OEM name and version
bpbBytesPerSector:  dw 512 ; Bytes per sector
bpbSectorsPerCluster: db 1 ; Sectors per cluster
bpbReservedSectors: dw 1 ; Reserved sectors
bpbNumberOfFATs:    db 2 ; Number of FATs
bpdDirEntriesCount: dw 224 ; Number of directory entries
bpbTotalSectors16:  dw 2880 ; Total sectors (2880*512 = 1.44MB)
bpbMedia:           db 0xF0 ; Media descriptor (0xF0 = 1.44MB 3.5" floppy)
bpbSectorsPerFAT16: dw 9 ; Sectors per FAT
bpbSectorsPerTrack: dw 18 ; Sectors per track
bpbHeadsPerCylinder: dw 2 ; Heads per cylinder
bpbHiddenSectors:   dd 0 ; Hidden sectors (MBR)
bpbTotalSectors32:  dd 0 ; Total sectors

; extended BIOS Parameter Block
bsDriveNumber:      db 0 ; Drive number
bsUnused:           db 0 ; Unused (reserved)
bsExtBootSignature: db 0x29 ; Extended boot signature
bsSerialNumber:     dd 0xa0a1a2a3 ; Serial number
bsVolumeLabel:      db OS ; Volume label
bsFileSystem:       db FAT12 ; File system type



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

    push es
    push word .afterStack ; push the address of the afterStack label
    retf ; pop the address into CS:IP and jump to it

.afterStack:
    mov [bpbDriveNumber], dl ; save the boot drive number

    mov si, msgLoading ; load the address of the message into SI
    call puts ; call the puts function

    push es ; save registers
    mov ah, 0x08 ; get drive parameters function
    int 0x13 ; call BIOS disk interrupt
    jc error ; if carry flag is set, jump to error
    pop es ; restore registers

    and cl, 0x3F ; mask out the top two bits of Cl
    xor ch, ch ; clear CH (CH = 0)
    mov [bpbSectorsPerTrack], cx ; save the number of sectors per track

    inc dh ; increase DH by 1
    mov [bpbHeadsPerCylinder], dx ; save the number of heads per cylinder in DX

    mov ax, [bpbTotalSectors16] ; load the total number of sectors into AX
    mov bi, [bpbNumberOfFATs] ; load the number of FATs into BX
    xor bh, bh ; clear BH
    mul bx ; multiply AX by BX
    add ax, [bpbReservedSectors] ; add the number of reserved sectors to AX
    push ax ; save the result on the stack

    ; compute the size of the root directory = (number of directory entries * 32) / bytes per sector
    mov ax, [bpdDirEntriesCount] ; load the number of directory entries into AX
    mov ax, 32 ; multiply AX by 32
    xor bx, bx ; clear BX
    div word [bpbBytesPerSector] ; divide AX by the number of bytes per sector

    test dx, dx ; check if the remainder is zero
    jz .rootDirectorySize ; if zero, jump to rootDirectorySize
    inc ax ; increase AX by 1

.rootDirectorySize:

    ;read the root directory
    mov cl, al
    pop ax ; pop the result from the stack into AX
    mov dl, [bpbDriveNumber] ; load the boot drive number into DL
    mov bx, buffer ; load the address of the buffer into BX
    call diskRead ; call the diskRead function

    ;search for the kernel.bin file
    mov di, buffer ; load the address of the buffer into DI

    .searchKernel:
        mov si, kernelBin ; load the address of the kernel.bin string into SI
        mov cx, 11 ; load the length of the kernel.bin string into CX
        push di ; save the address of the buffer on the stack
        repe cmpsb ; compare the string in SI with the string in DI
        pop di ; restore the address of the buffer from the stack
        je .kernelFound ; if the strings are equal, jump to kernelFound

        add di, 32 ; add 32 to DI (32 bytes per directory entry)
        inc bx
        cmp bx, [bpbDirEntriesCount] ; check if we've reached the end of the root directory
        jl .searchKernel ; if not, jump to searchKernel

        jmp kernelNotFound ; jump to kernelNotFound if the kernel is not found

    .kernelFound:
        mov ax, [di + 0x1A] ; load the starting cluster number of the kernel into AX
        mov [kernelCluster], ax ; save the starting cluster number of the kernel

        ;load fat into memory
        mov ax, [bpbReservedSectors] ; load the number of reserved sectors into AX
        mov bx, buffer ; load the address of the buffer into BX
        mov dl, [bpbDriveNumber] ; load the boot drive number into DL
        mov cl, [bpbNumberOfFATs] ; load the number of FATs into CL
        call diskRead ; call the diskRead function

        ;read the kernel and process FAT12
        mov bx, kernelSegment ; load the address of the kernel segment into BX
        mov es, bx ; load the address of the kernel segment into ES
        mov bx , kernelOffset ; load the address of the kernel offset into BX


    .kernelLoadLoop:

        mov ax, [kernelCluster] ; load the starting cluster number of the kernel into AX
        mov ax, 31 ; multiply AX by 31

        mov cl, 1
        mov dl, [bpbDriveNumber] ; load the boot drive number into DL
        call diskRead ; call the diskRead function

        add bx , [bpbBytesPerSector] ; add the number of bytes per sector to BX
        mov ax, [kernelCluster] ; load the starting cluster number of the kernel into AX
        mov cx, 3 ; multiply AX by 3
        mul cx
        mov cx, 2 ; div AX by 2
        div cx

        mov si, buffer ; load the address of the buffer into SI
        mov si, ax ; load the starting cluster number of the kernel into SI
        mov ax, [ds:si] ; load the value at DS:SI into AX

        or dx , dx ; check if DX is zero
        jz .even ; if zero, jump to even

    .odd:
        shr ax, 4 ; shift AX right by 4 bits
        jmp .next ; jump to next

    .even:
        and ax, 0x0FFF ; mask out the top 4 bits of AX

    .next:
        cmp ax, 0xFF8 ; check if AX is greater than or equal to 0xFF8
        jae kernelLoaded ; if greater than or equal to 0xFF8, jump to kernelLoaded

        mov [kernelCluster], ax ; save the starting cluster number of the kernel into AX
        jmp .kernelLoadLoop ; jump to kernelLoadLoop and load the next cluster

    .kernelLoaded:

        mov dl, [bpbDriveNumber] ; load the boot drive number into DL

        mov ax, kernelSegment ; load the address of the kernel segment into AX
        mov es, ax ; load the address of the kernel segment into ES

        jmp kernelSegment:kernelOffset ; jump to the kernel

        jmp .halt ; jump to halt







; print a string
puts:
    ; save registers will be used
    push si
    push bx
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
    pop bx
    pop ax
    pop si
    ret



;ERROR HANDLING
error:
    mov si, msgError ; load the address of the message into SI
    call puts ; call the puts function
    jmp waitForKey ; wait for a keypress

waitForKey:
    mov ah, 0 ; BIOS keyboard services
    int 0x16 ; wait for keypress
    jmp main ; restart the program

.halt:
    cli ; clear interrupts
    hlt ; halt the CPU
;
; Disk routines
;

; LBA to CHS conversion
;ref:https://en.wikipedia.org/wiki/Logical_block_addressing#CHS_conversion

lbaToChs:
    push ax ;save registers
    push dx

    xor dx, dx ; clear DX (DX = 0)
    div word [bpbSectorsPerTrack] ; divide

    inc dx ; increase DX by 1
    mov cx, dx ; move DX to CX (CX = DX + 1)

    xor dx, dx ; clear DX (DX = 0)
    div word [bpbHeadsPerCylinder] ; divide

    mov dh, dl ; move DL to DH (DH = DL)
    mov ch, al ; move AL to CH (CH = AL)
    shl dh, 6 ; shift DH left by 6 bits (DH = DH << 6)
    or dh, cl ; OR DH with CL (DH = DH | CL)

    pop ax ; restore registers
    mov dl, al ; move AL to DL (DL = AL)
    pop dx
    ret ; return

; read a sector from disk
; ref: https://www.stanislavs.org/helppc/int_13-2.html

diskRead:
    pusha ; save registers



    push cx
    call lbaToChs ; convert LBA to CHS
    pop ax ; restore registers

    mov ah, 0x02 ; read sector function
    mov di, 3 ; retry count

.retry:
    pusha ; save registers
    stc ; set carry flag
    int 0x13 ; call BIOS disk interrupt
    jnc .success ; if carry flag is not set, jump to success

    popa ; restore registers
    call diskReset ; reset disk

    dec di ; decrease retry count
    test di, di ; check if retry count is zero
    jz .failure ; if zero, jump to failure
    jmp .retry ; retry

.failure:
    jmp error ; jump to error

.success:
    popa
    pop di ; restore registers
    pop dx
    pop cx
    pop bx
    pop ax
    ret ; return


; reset disk
diskReset:

    pusha ; save registers
    mov ah, 0x00 ; reset disk function
    stc ; set carry flag
    int 0x13 ; call BIOS disk interrupt
    jc .failure ; if carry flag is set, jump to failure
    popa ; restore registers
    ret ; return







; print a string
msgHello: db 'Hello, World!', ENDL, 0
msgError: db 'Error!', ENDL, 0
msgLoading: db 'Loading kernel...', ENDL, 0
kernelSegment equ 0x2000 ; kernel segment
kernelOffset equ 0x0000 ; kernel offset
kernelCluster: dw 0x0000 ; kernel cluster
kernelBin: db 'Stage2.bin', ENDL, 0 ; kernel.bin string

buffer:


; boot signature

 times 510-($-$$) db 0
   db 0x55
   db 0xAA