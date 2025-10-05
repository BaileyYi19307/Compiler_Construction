	.text
	.align	2
	.globl main
f:
	addi	x2, x2, 0xFFFFFF58
	sw	x8, 164(x2)
	sw	x1, 160(x2)
	addi	x8, x2, 0xA8
	sw	x10, -12(x8)
	sw	x11, -16(x8)
	sw	x12, -20(x8)
	sw	x13, -24(x8)
	sw	x14, -28(x8)
	sw	x15, -32(x8)
	sw	x16, -36(x8)
	sw	x17, -40(x8)
	lw	x6, 168(x2)
	sw	x6, -44(x8)
	lw	x6, 172(x2)
	sw	x6, -48(x8)
	lw	x5, -12(x8)
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -12(x8)
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	mul	x5, x5, x6
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -16(x8)
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -16(x8)
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	mul	x5, x5, x6
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	add	x5, x5, x6
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -20(x8)
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -20(x8)
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	mul	x5, x5, x6
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	add	x5, x5, x6
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -24(x8)
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -24(x8)
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	mul	x5, x5, x6
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	add	x5, x5, x6
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -28(x8)
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -28(x8)
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	mul	x5, x5, x6
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	add	x5, x5, x6
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -32(x8)
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -32(x8)
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	mul	x5, x5, x6
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	add	x5, x5, x6
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -36(x8)
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -36(x8)
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	mul	x5, x5, x6
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	add	x5, x5, x6
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -40(x8)
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -40(x8)
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	mul	x5, x5, x6
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	add	x5, x5, x6
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -44(x8)
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -44(x8)
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	mul	x5, x5, x6
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	add	x5, x5, x6
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -48(x8)
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x5, -48(x8)
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	mul	x5, x5, x6
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	add	x5, x5, x6
	add	x10, x5, x0
	jal x0,L1
L1:
	lw	x1, 160(x2)
	lw	x8, 164(x2)
	addi	x2, x2, 0xA8
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
	li	x5, 0xA
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0x9
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0x8
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0x7
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0x6
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0x5
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0x4
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0x3
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0x2
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0x1
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x10, 0(x2)
	addi	x2, x2, 0x4
	lw	x11, 0(x2)
	addi	x2, x2, 0x4
	lw	x12, 0(x2)
	addi	x2, x2, 0x4
	lw	x13, 0(x2)
	addi	x2, x2, 0x4
	lw	x14, 0(x2)
	addi	x2, x2, 0x4
	lw	x15, 0(x2)
	addi	x2, x2, 0x4
	lw	x16, 0(x2)
	addi	x2, x2, 0x4
	lw	x17, 0(x2)
	addi	x2, x2, 0x4
	jal x1,f
	addi	x2, x2, 0x8
	lw	x7, 4(x2)
	lw	x6, 8(x2)
	lw	x5, 12(x2)
	lw	x1, 16(x2)
	addi	x2, x2, 0x14
	add	x5, x10, x0
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	addi	x2, x2, 0xFFFFFFEC
	sw	x1, 16(x2)
	sw	x5, 12(x2)
	sw	x6, 8(x2)
	sw	x7, 4(x2)
	li	x5, 0x14
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0x13
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0x12
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0x11
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0x10
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0xF
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0xE
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0xD
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0xC
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0xB
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	lw	x10, 0(x2)
	addi	x2, x2, 0x4
	lw	x11, 0(x2)
	addi	x2, x2, 0x4
	lw	x12, 0(x2)
	addi	x2, x2, 0x4
	lw	x13, 0(x2)
	addi	x2, x2, 0x4
	lw	x14, 0(x2)
	addi	x2, x2, 0x4
	lw	x15, 0(x2)
	addi	x2, x2, 0x4
	lw	x16, 0(x2)
	addi	x2, x2, 0x4
	lw	x17, 0(x2)
	addi	x2, x2, 0x4
	jal x1,f
	addi	x2, x2, 0x8
	lw	x7, 4(x2)
	lw	x6, 8(x2)
	lw	x5, 12(x2)
	lw	x1, 16(x2)
	addi	x2, x2, 0x14
	add	x5, x10, x0
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	add	x5, x5, x6
	addi	x2, x2, 0xFFFFFFFC
	sw	x5, 0(x2)
	li	x5, 0xAF0
	lw	x6, 0(x2)
	addi	x2, x2, 0x4
	sub	x5, x6, x5
	add	x10, x5, x0
	jal x0,L2
L2:
	lw	x1, 120(x2)
	lw	x8, 124(x2)
	addi	x2, x2, 0x80
	jalr	x0, x1, 0x0


	.data
	.align 0
a:	.word 0
b:	.word 0
c:	.word 0
d:	.word 0
e:	.word 0
g:	.word 0
h:	.word 0
i:	.word 0
j:	.word 0

