name "AES Team 2"
org 100h
.data segment
    roundKey DB 02Bh,028h,0abh,009h,
             DB 07eh,0aeh,0f7h,0cfh,
             DB 015h,0d2h,015h,04fh,
             DB 016h,0a6h,088h,03ch
    
    subbedKey DB 4 DUP(0)
             
    sbox DB 063h,07ch,077h,07bh,0f2h,06bh,06fh,0c5h,030h,001h,067h,02bh,0feh,0d7h,0abh,076h,
         DB 0cah,082h,0c9h,07dh,0fah,059h,047h,0f0h,0adh,0d4h,0a2h,0afh,09ch,0a4h,072h,0c0h,
         DB 0b7h,0fdh,093h,026h,036h,03fh,0f7h,0cch,034h,0a5h,0e5h,0f1h,071h,0d8h,031h,015h,
         DB 004h,0c7h,023h,0c3h,018h,096h,005h,09ah,007h,012h,080h,0e2h,0ebh,027h,0b2h,075h,
         DB 009h,083h,02ch,01ah,01bh,06eh,05ah,0a0h,052h,03bh,0d6h,0b3h,029h,0e3h,02fh,084h,
         DB 053h,0d1h,000h,0edh,020h,0fch,0b1h,05bh,06ah,0cbh,0beh,039h,04ah,04ch,058h,0cfh,
         DB 0d0h,0efh,0aah,0fbh,043h,04dh,033h,085h,045h,0f9h,002h,07fh,050h,03ch,09fh,0a8h,
         DB 051h,0a3h,040h,08fh,092h,09dh,038h,0f5h,0bch,0b6h,0dah,021h,010h,0ffh,0f3h,0d2h,
         DB 0cdh,00ch,013h,0ech,05fh,097h,044h,017h,0c4h,0a7h,07eh,03dh,064h,05dh,019h,073h,
         DB 060h,081h,04fh,0dch,022h,02ah,090h,088h,046h,0eeh,0b8h,014h,0deh,05eh,00bh,0dbh,
         DB 0e0h,032h,03ah,00ah,049h,006h,024h,05ch,0c2h,0d3h,0ach,062h,091h,095h,0e4h,079h,
         DB 0e7h,0c8h,037h,06dh,08dh,0d5h,04eh,0a9h,06ch,056h,0f4h,0eah,065h,07ah,0aeh,008h,
         DB 0bah,078h,025h,02eh,01ch,0a6h,0b4h,0c6h,0e8h,0ddh,074h,01fh,04bh,0bdh,08bh,08ah,
         DB 070h,03eh,0b5h,066h,048h,003h,0f6h,00eh,061h,035h,057h,0b9h,086h,0c1h,01dh,09eh,
         DB 0e1h,0f8h,098h,011h,069h,0d9h,08eh,094h,09bh,01eh,087h,0e9h,0ceh,055h,028h,0dfh,
         DB 08ch,0a1h,089h,00dh,0bfh,0e6h,042h,068h,041h,099h,02dh,00fh,0b0h,054h,0bbh,016h
         
    rcon  DB 001h,000h,000h,000h
    
    matrix DB 2h, 3h, 1h, 1h, 
           DB 1h, 2h, 3h, 1h,
           DB 1h, 1h, 2h, 3h,
           DB 3h, 1h, 1h, 2h
    
    data DB 032h,088h,031h,0e0h,
         DB 043h,05ah,031h,037h,
         DB 0f6h,030h,098h,007h,
         DB 0a8h,08dh,0a2h,034h
.code segment
    call readData
    
    call addRoundKey
    mov cx, 9
    round: push cx
           call subDataBytes
           call shiftRows
           call mixColumns
           call keySchedule
           call addRoundKey
           pop cx
           loop round
    call subDataBytes
    call shiftRows
    call keySchedule
    call addRoundKey
    
    call printToScreen
    
    ret
    
    addRoundKey proc
       mov si, 0
       mov cx, 16
       addKey: mov al, data[si]
               xor al, roundKey[si]
               mov data[si], al
               inc si
               loop addKey
    ret 
    addRoundKey endp
    
    subDataBytes proc
        mov si, 0
        mov bx, 0
        mov cx, 16
        subDataElems: mov bl, data[si]
                      mov al, sbox[bx]
                      mov data[si], al
                      inc si
                      loop subDataElems
    ret
    subDataBytes endp
    
    subKeyColumn proc
        mov si, 7
        mov bx, 0
        mov cx, 3
        mov di, 0
        subKeyElems: mov bl, roundKey[si]
                     mov al, sbox[bx]
                     mov subbedKey[di], al
                     add si, 4
                     inc di
                     loop subKeyElems
        mov bl, roundKey[3]
        mov al, sbox[bx]
        mov subbedKey[di], al
    ret
    subKeyColumn endp
    
    shiftRows proc
    ; si <- Current data index
    ; ch <- Number of bytes to shift    
    ; cl <- Number of currently shifted bytes
    ; ax, dx <- Current row to be shifted
    ; bl <- Temporary byte storage
    mov si, 4
    mov ch, 1 
    start: mov ah, data[si]
           mov al, data[si+1]
           mov dh, data[si+2]
           mov dl, data[si+3]
           mov cl, 0 
           shiftNBytes: mov bl, ah
                        mov ah, al
                        mov al, dh
                        mov dh, dl
                        mov dl, bl
                        mov bl, 0
                        inc cl
                        cmp cl, ch
                        jnz shiftNBytes
     done: mov data[si], ah
           mov data[si+1], al
           mov data[si+2], dh
           mov data[si+3], dl
           add si, 4
           inc ch
           cmp ch, 4
           jnz start 
    ret
    shiftRows endp
    
    mixColumns proc
     mov dh, 0
     mov bx, 0
     next: mov ch, 4h
           mov di, 0
     calcCol:mov dl, 0
             mov si, bx
             mov cl, 4h
             calcVal: mov al, data[si]
                      one: cmp matrix[di], 1
                           jz conv
                      two: cmp matrix[di], 2
                           jnz three
                           mov ah, 0
                           shl al, 1
                           jc carry
                           jmp conv
                      three: mov ah, al
                             shl al, 1
                             jc carry
                             xor al, ah
                             jmp conv
                      carry: xor al, ah
                             xor al, 1Bh
                      conv: 
                      add si, 4
                      inc di
                      xor dl, al
                      dec cl
                      jnz calcVal
             push dx
             dec ch
             jnz calcCol
     sub si, 4
     mov cx, 4
     pops: pop ax
           mov data[si], al
           sub si, 4
           loop pops
     inc bl
     cmp bl, 4
     jnz next
    
    ret
    mixColumns endp
    
    keySchedule proc
        call subKeyColumn
        mov si, 0
        mov di, 0
        mov cx, 4
        sumElems: mov al, roundKey[si]
                  xor al, subbedKey[di]
                  xor al, rcon[di]
                  mov roundKey[si], al
                  add si, 4
                  inc di
                  loop sumElems
       mov bx, 1
       replaceCols: mov si, bx
                    mov cx, 4
                    replaceOne: mov al, roundKey[si]
                                xor al, roundKey[si-1]
                                mov roundKey[si], al
                                add si, 4
                                loop replaceOne
                    inc bx
                    cmp bx, 4
                    jnz replaceCols
       mov al, rcon[0]
       shl al, 1
       jnc end
       xor al, 1bh
       end: mov rcon[0], al
    ret
    keySchedule endp
    
    readData proc
        mov ah, 1
        mov si, 0
        mov ch, 4
        nextRow:  mov cl, 4
                  readRow:  int 21h
                            cmp al, '9'
                            jg letterA
                            digitA: sub al, '0'
                                    jmp doneA
                            letterA: sub al, 55
                            doneA:
                            mov bl, al
                            shl bl, 4
                            int 21h
                            cmp al, '9'
                            jg letterB
                            digitB: sub al, '0'
                                    jmp doneB
                            letterB: sub al, 55
                            doneB:
                            add bl, al
                            mov data[si], bl
                            inc si
                            mov ah, 2h
                            mov dx, ' '
                            int 21h
                            mov ah, 1h
                            dec cl
                            jnz readRow
                  mov ah, 2h
                  mov dx,13
                  int 21h     ; Print Carriage Return
                  mov dx,10
                  int 21h     ; Print Line Feed
                  mov ah, 1
                  dec ch
                  jnz nextRow
        mov ah, 2h
        mov dx,13
        int 21h     ; Print Carriage Return
        mov dx,10
        int 21h     ; Print Line Feed
        dec ch
        ret
    readData endp
    
    printToScreen proc
        ; ah <- 2. int 21/AH=2 prints to screen
        ; cl <- Number of elements per row
        ; ch <- Number of rows
        ; si <- Current Data index
        ; dl <- Byte 1 of current data element
        ; dh <- Byte 2 of current data element
        mov ah, 2
        mov cl, 4
        mov ch, 4
        mov si, 0
        printRow: mov cl, 4
                  printNum: mov dh, data[si]
                            mov dl, data[si]
                            shr dl, 4         ; Shift right 4 times (Remove low 4 bits)
                            and dh, 0Fh       ; And with 00001111b (Remove high 4 bits)
            
                            cmp dl, 9h        ; Check if value is an integer or a letter
                            jg letter1        ; Jump if letter
                            add dl, '0'       ; Turn number to ascii equivalent
                            jmp print1
                            letter1: add dl, 55
                            print1: int 21h
        
                            mov dl, dh        ; Move Byte 2 to dl and print it
                            cmp dl, 9h
                            jg letter2
                            add dl, '0'
                            jmp print2
                            letter2: add dl, 55
                            print2: int 21h
                            
                            mov dl, ' '       ; Print a space between each Byte
                            int 21h
                            inc si
                            dec cl
                            jnz printNum
                  mov dx,13
                  int 21h     ; Print Carriage Return
                  mov dx,10
                  int 21h     ; Print Line Feed
                  dec ch
                  jnz printRow
        ret
    printToScreen endp