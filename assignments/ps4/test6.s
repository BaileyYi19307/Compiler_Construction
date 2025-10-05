	.text
	.align	2
	.globl main

f:
	addi	x2, x2, -128
	sw	x1, 124(x2)
	sw	x8, 120(x2)
	addi	x8, x2, 128
	sw	x10, -12(x8)
	sw	x11, -16(x8)
	sw	x12, -20(x8)
	sw	x13, -24(x8)
	sw	x14, -28(x8)
	sw	x15, -32(x8)
	sw	x16, -36(x8)
	sw	x17, -40(x8)
	lw	x5, 0(x2)
	sw	x5, -44(x8)
	lw	x6, 4(x2)
	sw	x6, -48(x8)
	lw	x5, -44(x8)
	sll	x6, x5, 1
	lw	x5, -48(x8)
	mul	x5, x5, x5
	add	x6, x6, x5
	lw	x5, -40(x8)
	add	x10, x6, x5
L1:
	lw	x1, 124(x2)
	lw	x8, 120(x2)
	addi	x2, x2, 128
	jalr	x0, x1, 0

main:
	addi	x2, x2, -128
	sw	x1, 124(x2)
	sw	x8, 120(x2)
	addi	x8, x2, 128
	li	x10, 1
	add	x10, x10, x0
	li	x10, 2
	add	x11, x10, x0
	li	x10, 3
	add	x12, x10, x0
	li	x10, 4
	add	x13, x10, x0
	li	x10, 5
	add	x14, x10, x0
	li	x10, 6
	add	x15, x10, x0
	li	x10, 7
	add	x16, x10, x0
	li	x10, 8
	add	x17, x10, x0
	li	x10, 9
	sw	x10, 0(x2)
	li	x10, 10
	sw	x10, 4(x2)
	jal	x1, f
	j	L2

L2:
	lw	x1, 124(x2)
	lw	x8, 120(x2)
	addi	x2, x2, 128
	jalr	x0, x1, 0

	.data
	.align 0

