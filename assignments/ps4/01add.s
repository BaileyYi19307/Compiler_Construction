	.text
	.align	2
	.globl main
main:
	addi	x2, x2, 0xFFFFFFF0
	sw	x1, 12(x2)
	sw	x8, 8(x2)
	addi	x8, x2, 0x10
	li	x10, 0xC
	addi	x2, x2, 0xFFFFFFFC
	sw	x10, 0(x2)
	li	x10, 0x4
	lw	x11, 0(x2)
	addi	x2, x2, 0x4
	add	x10, x11, x10
	lw	x1, 12(x2)
	lw	x8, 8(x2)
	addi	x2, x2, 0x10
	jalr	x0, x1, 0x0


	.data
	.align 0

