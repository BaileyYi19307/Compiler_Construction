	.text
	.align	2
	.globl main
main:
	addi	x2, x2, -32
	sw	x1, 28(x2)
	sw	x8, 24(x2)
	addi	x8, x2, 32
	li	x10, 0
	sw	x10, -12(x8)
	li	x10, 0
	sw	x10, -16(x8)
L_test:
	lw	x10, -12(x8)
	li	x11, 10
	slt	x12, x10, x11
	beq	x12, x0, L_exit
	lw	x10, -16(x8)
	lw	x11, -12(x8)
	add	x10, x10, x11
	sw	x10, -16(x8)
	lw	x10, -12(x8)
	addi	x10, x10, 1
	sw	x10, -12(x8)
	j	L_test
L_exit:
	lw	x10, -16(x8)
	lw	x1, 28(x2)
	lw	x8, 24(x2)
	addi	x2, x2, 32
	jalr	x0, x1, 0
	.data
	.align 0

