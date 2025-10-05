	.text
	.align	2
	.globl main
main:
	addi	x2, x2, 0xFFFFFFE0
	sw	x1, 12(x2)
	sw	x8, 8(x2)
	addi	x8, x2, 0x20
	li	x10, 0xC
	sw	x10, -12(x8)
	li	x10, 0x4
	sw	x10, -16(x8)
	lw	x10, -12(x8)
	addi	x2, x2, 0xFFFFFFFC
	sw	x10, 0(x2)
	lw	x10, -16(x8)
	lw	x11, 0(x2)
	addi	x2, x2, 0x4
	add	x10, x11, x10
	add	x10, x10, x0
	lw	x1, 12(x2)
	lw	x8, 8(x2)
	addi	x2, x2, 0x20
	jalr	x0, x1, 0x0


	.data
	.align 0

