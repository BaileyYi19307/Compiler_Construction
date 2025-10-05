	.text
	.align	2
	.globl main

f:
	addi	sp, sp, -48
	sw	ra, 44(sp)
	sw	s0, 40(sp)
	addi	s0, sp, 48
	sw	a0, -20(s0)
	sw	a1, -24(s0)
	sw	a2, -28(s0)
	sw	a3, -32(s0)
	sw	a4, -36(s0)
	sw	a5, -40(s0)
	sw	a6, -44(s0)
	sw	a7, -48(s0)
	lw	t0, 0(s0)        # i = 9 (loaded from stack)
	slli	t1, t0, 1        # 2 * i
	lw	t2, 4(s0)         # j = 10 (loaded from stack)
	mul	t3, t2, t2       # j * j
	add	t1, t1, t3       # 2 * i + j * j
	lw	t4, -48(s0)       # h = a7 = 8
	add	t1, t1, t4       # + h
	mv	a0, t1
	lw	ra, 44(sp)
	lw	s0, 40(sp)
	addi	sp, sp, 48
	jr	ra

main:
	addi	sp, sp, -32
	sw	ra, 28(sp)
	sw	s0, 24(sp)
	addi	s0, sp, 32
	li	a0, 1
	li	a1, 2
	li	a2, 3
	li	a3, 4
	li	a4, 5
	li	a5, 6
	li	a6, 7
	li	a7, 8
	li	t0, 9
	sw	t0, 0(sp)
	li	t1, 10
	sw	t1, 4(sp)
	lw	t2, 0(sp)
	lw	t3, 4(sp)
	mv	a0, a0
	mv	a1, a1
	mv	a2, a2
	mv	a3, a3
	mv	a4, a4
	mv	a5, a5
	mv	a6, a6
	mv	a7, a7
	call f
	mv	t4, a0
	mv	a0, t4
	lw	ra, 28(sp)
	lw	s0, 24(sp)
	addi	sp, sp, 32
	jr	ra

