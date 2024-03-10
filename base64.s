.text
.global _start

.equ SYS_READ,63
.equ SYS_WRITE,64
.equ SYS_OPENAT,56
.equ SYS_CLOSE,57
.equ SYS_EXIT,93
.equ SYS_LSEEK,62
.equ SYS_MMAP,222

.equ AT_FDCWD,-100
.equ STDIN_FILENO,0

.equ BUF_SIZE,100000
.equ BASE64_BUF_SIZE,140000


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
    blt     t0,t1,stdin         # Less than 2 args ? we will read from stdin

    li      a0,AT_FDCWD         # AT_FDCWD
    ld      a1,16(sp)           # argv[1]
    li      a2,0                # flags
    li      a3,0                # mode
    li      a7,SYS_OPENAT       # "openat" system call
    ecall
    blt     a0,x0,exit          # Error ? we exit
    mv      s11,a0              # Saving FD in s11

    li      a1,0                # offset
    li      a2,2                # SEEK_END
    li      a7,SYS_LSEEK        # "lseek" system call
    ecall
    blt     a0,x0,close_exit    # Error ? we close the FD and exit
    mv      s6,a0               # we save the file size in s6

    mv      a0,s11              # first argument : the file descriptor (saved in s11)
    li      a1,0                # offset
    li      a2,0                # SEEK_SET
    li      a7,SYS_LSEEK        # "lseek" system call
    ecall
    blt     a0,x0,close_exit    # Error ? we close the FD and exit

    j       convert_file

stdin:
    mv      s11,x0              # No arg ? read from STDIN_FILENO

convert_file:
    la      s2,buffer           # s2 = pointer to buffer
    la      a3,base64_buffer    # a3 = pointer to converted base64 data
    li      s9,3
    li      s8,2

fill_buffer:
    mv      a0,s11              # Opened FD
    la      a1,buffer
    li      a2,BUF_SIZE         # we read BUF_SIZE bytes and store them to the buffer
    li      a7,SYS_READ         # "read" system call
    ecall
    li      t0,BUF_SIZE
    beq     a0,t0,close_exit    # We read data of the size of the buffer ? file too large -> exit
    mv      s10,a0              # Saving number of read bytes to s10

loop:
    lb      a0,(s2)
    lb      a1,1(s2)
    lb      a2,2(s2)
    jal     convert_24bit

    addi    s2,s2,3             # Incrementing input buffer pointer
    addi    a3,a3,4             # Incrementing output buffer pointer
    addi    s10,s10,-3          # Decrementing byte counter
    bge     s10,s9,loop         # Still a minimum of 3 bytes to process ? continue loop
    beq     s10,x0,no_padding

    li      s7,0x3d             # '=' padding char
    blt     s10,s8,one_padding  # 1 byte left ? we jump
    lb      a0,(s2)             # 2 bytes left ? we load these bytes
    lb      a1,1(s2)
    mv      a2,x0               # and a third null byte
    jal     convert_24bit       # Making the last conversion
    sb      s7,3(a3)            # Adding padding char

    li      a0,0x0a
    sb      a0,4(a3)            # Ending buffer with a newline
    j       print_buffer

one_padding:
    lb      a0,(s2)             # 1 byte left ?
    mv      a1,x0
    mv      a2,x0
    jal     convert_24bit       # Making the last conversion
    sb      s7,2(a3)            # Adding 2 padding chars
    sb      s7,3(a3)

    li      a0,0x0a
    sb      a0,4(a3)            # Ending buffer with a newline
    j       print_buffer

no_padding:
    li      a0,0x0a
    sb      a0,4(a3)            # Ending buffer with a newline

print_buffer:
    addi    a3,a3,5             # Incrementing buffer pointer by
    la      a2,base64_buffer    # the 4 last bytes + newline
    sub     t2,a3,a2            # Computing number of generated bytes
    mv      t0,x0               # t0 will be used for offset
loop_prt_buf:
    li      a0,1                # stdout
    la      a1,base64_buffer    # base64 data
    add     a1,a1,t0
    li      a2,76               # we write a line of 76 chars
    li      a7,SYS_WRITE        # "write" syscall
    ecall
    li      t1,76
    add     t0,t0,t1            # Incrementing offset
    sub     t2,t2,t1
    ble     t2,x0,close_exit
    li      a0,1                # stdout
    la      a1,newline          # newline
    li      a2,1                # we write the new line char
    li      a7,SYS_WRITE        # "write" syscall
    ecall
    bgt     t2,x0,loop_prt_buf

close_exit:
    mv      a0,s11              # file descriptor was saved in s11
    li      a7,SYS_CLOSE        # "close" system call
    ecall

exit:
    li      a7,SYS_EXIT         # "exit" system call
    ecall

.data
newline:
.dword 0x0a
.lcomm buffer,BUF_SIZE
.lcomm base64_buffer,BASE64_BUF_SIZE
