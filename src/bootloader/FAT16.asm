
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
bsFileSystem:       db FAT16 ; File system type

start:
    mov ax, 0x07C0 ; Set up 4K stack space after this bootloader
    add ax, 288 ; (4096 + 512) / 16 bytes per paragraph
    mov ss, ax
    mov sp, 4096

    mov ax, 0x07C0 ; Set data segment to where we're loaded
    mov ds, ax

    mov si, text_string ; Put string position into SI
    call print_string ; Call our string-printing routine

    jmp $ ; Jump here - infinite loop!

    text_string: db Hello, World!, 0 ; String terminator

    print_string: ; Routine: output string in SI to screen
        mov ah, 0x0E ; BIOS teletype function
    .repeat:
        lodsb ; Get character from string
        cmp al, 0 ; Check for terminator
        je .done ; If we're done, jump out
        int 0x10 ; Otherwise, print it
        jmp .repeat ; And jump back
    .done:
        ret

    times 510 -($-$$) db 0 ; Pad remainder of boot sector with 0s
    dw 0xAA55 ; The standard PC boot signature
