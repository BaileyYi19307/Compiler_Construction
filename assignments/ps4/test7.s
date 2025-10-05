	.text
	.align	2
	.globl main
f:
	addi	x2, x2, -512
	sw	x1, 508(x2)
	sw	x8, 504(x2)
	addi	x8, x2, 512
	sw	x10, -20(x8)
	sw	x11, -24(x8)
	sw	x12, -28(x8)
	sw	x13, -32(x8)
	sw	x14, -36(x8)
	sw	x15, -40(x8)
	sw	x16, -44(x8)
	sw	x17, -48(x8)
	lw	x10, 0(x8)
	slli	x10, x10, 1
	lw	x11, 4(x8)
	mul	x11, x11, x11
	add	x10, x10, x11
	lw	x11, -48(x8)
	add	x10, x10, x11
L1:
	lw	x1, 508(x2)
	lw	x8, 504(x2)
	addi	x2, x2, 512
	jalr	x0, x1, 0
main:
	addi	x2, x2, -512
	sw	x1, 508(x2)
	sw	x8, 504(x2)
	addi	x8, x2, 512
	li	x10, 1
	mv	x10, x10
	li	x10, 2
	mv	x11, x10
	li	x10, 3
	mv	x12, x10
	li	x10, 4
	mv	x13, x10
	li	x10, 5
	mv	x14, x10
	li	x10, 6
	mv	x15, x10
	li	x10, 7
	mv	x16, x10
	li	x10, 8
	mv	x17, x10
	li	x10, 9
	sw	x10, 0(x8)
	li	x10, 10
	sw	x10, 4(x8)
	jal	x1, f
	j	L2
L2:
	lw	x1, 508(x2)
	lw	x8, 504(x2)
	addi	x2, x2, 512
	jalr	x0, x1, 0
	.data
	.align 0

