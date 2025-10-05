	.text
	.align	2
	.globl main
main:
	addi	x2, x2, 0xFFFFFFE0
	sw	x1, 12(x2)
	sw	x8, 8(x2)
	addi	x8, x2, 0x20
	li	x10, 0x0
	sw	x10, -12(x8)
	li	x10, 0x0
	sw	x10, -16(x8)
L2:
	lw	x10, -12(x8)
	addi	x2, x2, 0xFFFFFFFC
	sw	x10, 0(x2)
	li	x10, 0xA
	lw	x11, 0(x2)
	addi	x2, x2, 0x4
	slt	x10, x11, x10
	beq	x10, x0, L3
	j L2
L3:
	lw	x10, -16(x8)
	j L1
L1:
	lw	x1, 12(x2)
	lw	x8, 8(x2)
	addi	x2, x2, 0x20
	jalr	x0, x1, 0x0


	.data
	.align 0

