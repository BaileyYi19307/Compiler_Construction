	.text
	.align	2
	.globl main
main:
	addi	x2, x2, -32
	sw	x1, 28(x2)
	sw	x8, 24(x2)
	addi	x8, x2, 32
	li	x10, 0xC
	sw	x10, -20(x8)
	li	x10, 0x4
	sw	x10, -24(x8)
	lw	x10, -20(x8)
	addi	x2, x2, -4
	sw	x10, 0(x2)
	lw	x10, -24(x8)
	lw	x11, 0(x2)
	addi	x2, x2, 4
	add	x10, x11, x10
	lw	x1, 28(x2)
	lw	x8, 24(x2)
	addi	x2, x2, 32
	jalr	x0, x1, 0
	.data
	.align 0

