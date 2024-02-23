.global convert_24bit
.text

# input : three bytes (a0 a1 a2)
# output :  the three bytes converted to base64 (four bytes in a0 a1 a2 a3)
convert_24bit:
# step 1 : put the 3 bytes (24 bits) in a 32-bit word (result in a0)

    sllw    a0,a0,16
    sllw    a1,a1,8

    or      a0,a0,a1
    or      a0,a0,a2

# step 2 : octal conversion (three bytes = four sextets)
# result : four octal numbers in t0 t1 t2 t3

    li      t0,0xFC0000
    and     t0,t0,a0
    srliw   t0,t0,18

    li      t1,0x3F000
    and     t1,t1,a0
    srliw   t1,t1,12

    li      t2,0xFC0
    and     t2,t2,a0
    srliw   t2,t2,6

    li      t3,0x3F
    and     t3,t3,a0

# step 3 : retrieve corresponding char from the LUT
# result : 4 bytes in a0 a1 a2 a3

    la      t4,table            # pointer to the LUT

    add     t5,t4,t0            # t5 = table index + offset (first sextet)
    lb      a0,(t5)

    add     t5,t4,t1            # t5 = table index + offset (second sextet)
    lb      a1,(t5)

    add     t5,t4,t2            # t5 = table index + offset (third sextet)
    lb      a2,(t5)

    add     t5,t4,t3            # t5 = table index + offset (fourth sextet)
    lb      a3,(t5)

    ret

.data
table:
    .ascii  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
