	.text
	.align	2
	.globl main
f:
	or	x11, x8, x0
	or	x12, x1, x0
	or	x16, x9, x0
	or	x17, x18, x0
	or	x18, x19, x0
	or	x19, x20, x0
	or	x20, x21, x0
	or	x21, x22, x0
	or	x22, x23, x0
	or	x23, x24, x0
	or	x13, x25, x0
	or	x14, x26, x0
	or	x15, x27, x0
	li	x10, 1
	j .L0
.L1:
	j .L0
.L0:
	or	x8, x11, x0
	or	x1, x12, x0
	or	x9, x16, x0
	or	x18, x17, x0
	or	x19, x18, x0
	or	x20, x19, x0
	or	x21, x20, x0
	or	x22, x21, x0
	or	x23, x22, x0
	or	x24, x23, x0
	or	x25, x13, x0
	or	x26, x14, x0
	or	x27, x15, x0
	jalr	x0, x1, 0
main:
	or	x11, x8, x0
	or	x12, x1, x0
	or	x13, x9, x0
	or	x14, x18, x0
	or	x15, x19, x0
	or	x16, x20, x0
	or	x17, x21, x0
	or	x18, x22, x0
	or	x19, x23, x0
	or	x20, x24, x0
	or	x21, x25, x0
	or	x22, x26, x0
	or	x23, x27, x0
	li	x31, 0
	sub	x2, x2, x31
	jal x1,f
	li	x31, 0
	add	x2, x2, x31
	or	x24, x10, x0
	or	x10, x24, x0
	j .L2
.L3:
	j .L2
.L2:
	or	x8, x11, x0
	or	x1, x12, x0
	or	x9, x13, x0
	or	x18, x14, x0
	or	x19, x15, x0
	or	x20, x16, x0
	or	x21, x17, x0
	or	x22, x18, x0
	or	x23, x19, x0
	or	x24, x20, x0
	or	x25, x21, x0
	or	x26, x22, x0
	or	x27, x23, x0
	jalr	x0, x1, 0


	.data
	.align 0

