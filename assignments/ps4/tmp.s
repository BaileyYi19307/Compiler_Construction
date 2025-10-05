	.text
	.align	2
	.globl main
f:
	addi	x2, x2, 0xFFFFFF80
	sw	x8, 124(x2)
	sw	x1, 120(x2)
	addi	x8, x2, 0x80
	li	x5, 0x1
	add	x10, x5, x0
	jal x0,L1
L1:
	lw	x1, 120(x2)
	lw	x8, 124(x2)
	addi	x2, x2, 0x80
	jalr	x0, x1, 0x0
main:
	addi	x2, x2, 0xFFFFFF80
	sw	x8, 124(x2)
	sw	x1, 120(x2)
	addi	x8, x2, 0x80
	addi	x2, x2, 0xFFFFFFEC
	sw	x1, 16(x2)
	sw	x5, 12(x2)
	sw	x6, 8(x2)
	sw	x7, 4(x2)
	jal x1,f
	lw	x7, 4(x2)
	lw	x6, 8(x2)
	lw	x5, 12(x2)
	lw	x1, 16(x2)
	addi	x2, x2, 0x14
	add	x5, x10, x0
	sw	x5, -12(x8)
	lw	x5, -12(x8)
	add	x10, x5, x0
	jal x0,L2
L2:
	lw	x1, 120(x2)
	lw	x8, 124(x2)
	addi	x2, x2, 0x80
	jalr	x0, x1, 0x0


	.data
	.align 0
x:	.word 0

