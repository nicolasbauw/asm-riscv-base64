.text
.global _start

.equ BUF_SIZE,4096

# s11 : FD
# s10 : number of bytes read
# s2 : pointer to buffer
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
    mv      a0,s11              # Opened FD
    la      a1,buffer
    li      a2,BUF_SIZE         # we read 4096 bytes and store them to the buffer
    li      a7,63               # "read" system call
    ecall
    mv      s10,a0              # Saving number of read bytes to s10

    la      s2,buffer           # s2 = pointer to buffer
    lb      a0,(s2)
    lb      a1,1(s2)
    lb      a2,2(s2)
    jal     convert_24bit

close_exit:
    mv      a0,s11              # file descriptor was saved in s11
    li      a7,57               # "close" system call
    ecall

exit:
    li  a7,93                   # "exit" system call
    ecall

.lcomm buffer,BUF_SIZE
