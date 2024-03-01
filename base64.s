.text
.global _start

.equ BUF_SIZE,4092
.equ BASE64_BUF_SIZE,4096

# s11 : FD
# s10 : number of bytes read
# s9  : immediate value 3 (minimum amount of bytes to form a 24-bit value)
# s8  : immediate value 2 (for padding calculation)
# s7  : immediate value 0x3d ('=' padding char)
# s2  : pointer to input buffer
# a3  : pointer to output buffer
_start:
    ld      t0,(sp)             # argc
    li      t1,2
    li      a0,-1               # Error code if less than 2 args
    blt     t0,t1,exit          # Less than 2 args ? we exit

    li      a0,-100             # AT_FDCWD
    ld      a1,16(sp)           # argv[1]
    li      a2,0                # flags
    li      a3,0                # mode
    li      a7,56               # "openat" system call
    ecall
    blt     a0,x0,exit          # Error ? we exit
    mv      s11,a0              # Saving FD in s11

convert_file:
    la      s2,buffer           # s2 = pointer to buffer
    la      a3,base64_buffer    # a3 = pointer to converted base64 data
    li      s9,3
    li      s8,2

fill_buffer:
    mv      a0,s11              # Opened FD
    la      a1,buffer
    li      a2,BUF_SIZE         # we read 4096 bytes and store them to the buffer
    li      a7,63               # "read" system call
    ecall
    beq     a0,x0,close_exit    # No bytes read ? EOF -> exit
    mv      s10,a0              # Saving number of read bytes to s10

loop:
    lb      a0,(s2)
    lb      a1,1(s2)
    lb      a2,2(s2)
    jal     convert_24bit

    addi    s2,s2,3             # Incrementing input buffer pointer
    addi    a3,a3,4             # Incrementing output buffer pointer
    addi    s10,s10,-3          # Decrementing byte counter
    beq     s10,x0,fill_buffer  # All bytes processed ? read next BUF_SIZE bytes
    bge     s10,s9,loop         # Still a minimum of 3 bytes to process ? continue loop

    li      s7,0x3d             # '=' padding char
    blt     s10,s8,one_padding  # 1 byte left ? we jump
    lb      a0,(s2)             # 2 bytes left ? we load these bytes
    lb      a1,1(s2)
    mv      a2,x0               # and a third null byte
    jal     convert_24bit       # Making the last conversion
    sb      s7,3(a3)            # Adding padding char
    j       close_exit

one_padding:
    lb      a0,(s2)             # 1 byte left ?
    mv      a1,x0
    mv      a2,x0
    jal     convert_24bit       # Making the last conversion
    sb      s7,2(a3)            # Adding 2 padding chars
    sb      s7,3(a3)

    li      a0,0x0a
    sb      a0,4(a3)            # Ending buffer with a newline

    addi    a3,a3,5             # Incrementing buffer pointer by
    la      a2,base64_buffer    # the 4 last bytes + newline
    sub     a2,a3,a2            # Computing number of generated bytes

    li  a0, 1                   # stdout
    la  a1, base64_buffer       # base64 data
    li  a7, 64                  # "write" syscall
    ecall

close_exit:
    mv      a0,s11              # file descriptor was saved in s11
    li      a7,57               # "close" system call
    ecall

exit:
    li  a7,93                   # "exit" system call
    ecall

.lcomm buffer,BUF_SIZE
.lcomm base64_buffer,BASE64_BUF_SIZE
