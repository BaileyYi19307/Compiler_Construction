	.text
	.align	2
	.globl main
main:
	or	x5, x8, x0
	or	x6, x1, x0
	or	x13, x9, x0
	or	x14, x18, x0
	or	x15, x19, x0
	or	x16, x20, x0
	or	x17, x21, x0
	or	x28, x22, x0
	or	x29, x23, x0
	or	x30, x24, x0
	or	x7, x25, x0
	or	x10, x26, x0
	or	x11, x27, x0
	li	x31, 12
	li	x30, 4
	sub	x12, x31, x30
	or	x10, x12, x0
	j .L0
.L1:
	j .L0
.L0:
	or	x8, x5, x0
	or	x1, x6, x0
	or	x9, x13, x0
	or	x18, x14, x0
	or	x19, x15, x0
	or	x20, x16, x0
	or	x21, x17, x0
	or	x22, x28, x0
	or	x23, x29, x0
	or	x24, x30, x0
	or	x25, x7, x0
	or	x26, x10, x0
	or	x27, x11, x0
	jalr	x0, x1, 0


	.data
	.align 0

