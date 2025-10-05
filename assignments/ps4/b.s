	.text
	.align	2
	.globl main
f:
	addi	sp, sp, -64
	sw	ra, 60(sp)
	sw	s0, 56(sp)
	addi	s0, sp, 64

	# Save a0–a7 into locals
	sw	a0, -12(s0)
	sw	a1, -16(s0)
	sw	a2, -20(s0)
	sw	a3, -24(s0)
	sw	a4, -28(s0)
	sw	a5, -32(s0)
	sw	a6, -36(s0)
	sw	a7, -40(s0)

	# Load extra args from caller's stack
	lw	t0, 0(sp)     # i (9th arg)
	sw	t0, -44(s0)
	lw	t1, 4(sp)     # j (10th arg)
	sw	t1, -48(s0)

	# h + 2*i + j*j
	lw	t2, -40(s0)   # h
	lw	t3, -44(s0)   # i
	slli	t3, t3, 1     # i * 2
	add	t2, t2, t3

	lw	t4, -48(s0)   # j
	mul	t4, t4, t4
	add	a0, t2, t4

	lw	ra, 60(sp)
	lw	s0, 56(sp)
	addi	sp, sp, 64
	jr	ra

main:
	addi	sp, sp, -48
	sw	ra, 44(sp)
	sw	s0, 40(sp)
	addi	s0, sp, 48

	# Pass args a0–a7
	li	a0, 1
	li	a1, 2
	li	a2, 3
	li	a3, 4
	li	a4, 5
	li	a5, 6
	li	a6, 7
	li	a7, 8

	# Push i and j onto stack
	li	t0, 9
	sw	t0, -8(sp)  # i
	li	t1, 10
	sw	t1, -4(sp)  # j

	call f

	mv	a0, a0
	lw	ra, 44(sp)
	lw	s0, 40(sp)
	addi	sp, sp, 48
	jr	ra

	.data
	.align 0

