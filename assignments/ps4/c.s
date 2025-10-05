
    	.text
    	.align	2
    	.globl main
    f:
    addi x2, x2, -128
    sw x1, 124(x2)
    sw x8, 120(x2)
    addi x8, x2, 128
    sw x10, -20(x8)
    sw x11, -24(x8)
    sw x12, -28(x8)
    sw x13, -32(x8)
    sw x14, -36(x8)
    sw x15, -40(x8)
    sw x16, -44(x8)
    sw x17, -48(x8)
    lw x11, 0(x8)
    li x12, 2
    mul x12, x12, x11
    lw x11, 4(x8)
    mul x11, x11, x11
    lw x10, -48(x8)
    add x10, x10, x12
    add x10, x10, x11
    j L1
L1:
    lw x1, 124(x2)
    lw x8, 120(x2)
    addi x2, x2, 128
    jalr x0, 0(x1)
main:
    li x10, 1
    add x10, x10, x0
    li x11, 2
    add x11, x10, x0
    li x10, 3
    add x12, x10, x0
    li x10, 4
    add x13, x10, x0
    li x10, 5
    add x14, x10, x0
    li x10, 6
    add x15, x10, x0
    li x10, 7
    add x16, x10, x0
    li x10, 8
    add x17, x10, x0
    li x10, 9
    sw x10, 0(x8)
    li x11, 10
    sw x11, 4(x8)
    jal x1, f
    j L2
L2:
    lw x1, 124(x2)
    lw x8, 120(x2)
    addi x2, x2, 128
    jalr x0, 0(x1)

    	.data
    	.align 0

