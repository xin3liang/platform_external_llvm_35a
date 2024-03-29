# Instructions that are valid
#
# FIXME: Test MIPS-I instead of MIPS32
# RUN: llvm-mc %s -triple=mips-unknown-linux -show-encoding -mcpu=mips32 | FileCheck %s

	.set noat
	abs.d	$f7,$f25          # CHECK: encoding:
	abs.s	$f9,$f16
	add	$s7,$s2,$a1
	add.d	$f1,$f7,$f29
	add.s	$f8,$f21,$f24
	addi	$t5,$t1,26322
	addu	$t1,$a0,$a2
	and	$s7,$v0,$t4
	c.ngl.d	$f29,$f29
	c.ngle.d	$f0,$f16
	c.sf.d	$f30,$f0
	c.sf.s	$f14,$f22
	cfc1	$s1,$21
	ctc1	$a2,$26
	cvt.d.s	$f22,$f28
	cvt.d.w	$f26,$f11
	cvt.s.d	$f26,$f8
	cvt.s.w	$f22,$f15
	cvt.w.d	$f20,$f14
	cvt.w.s	$f20,$f24
	div	$zero,$t9,$t3
	div.d	$f29,$f20,$f27
	div.s	$f4,$f5,$f15
	divu	$zero,$t9,$t7
	ehb                      # CHECK: ehb # encoding:  [0x00,0x00,0x00,0xc0]
	lb	$t8,-14515($t2)
	lbu	$t0,30195($v1)
	lh	$t3,-8556($s5)
	lhu	$s3,-22851($v0)
	li	$at,-29773
	li	$zero,-29889
	lw	$t0,5674($a1)
	lwc1	$f16,10225($k0)
	lwc2	$18,-841($a2)
	lwl	$s4,-4231($t7)
	lwr	$zero,-19147($gp)
	mfc1	$a3,$f27
	mfhi	$s3
	mfhi	$sp
	mflo	$s1
	mov.d	$f20,$f14
	mov.s	$f2,$f27
	move	$s8,$a0
	move	$t9,$a2
	mtc1	$s8,$f9
	mthi	$s1
	mtlo	$sp
	mtlo	$t9
	mul.d	$f20,$f20,$f16
	mul.s	$f30,$f10,$f2
	mult	$sp,$s4
	mult	$sp,$v0
	multu	$gp,$k0
	multu	$t1,$s2
	neg.d	$f27,$f18
	neg.s	$f1,$f15
	nop
	nor	$a3,$zero,$a3
	or	$t4,$s0,$sp
	sb	$s6,-19857($t6)
	sh	$t6,-6704($t7)
	sll   $a3,18               # CHECK: sll $7, $7, 18         # encoding: [0x00,0x07,0x3c,0x80]
	sll   $a3,$zero,18         # CHECK: sll $7, $zero, 18      # encoding: [0x00,0x00,0x3c,0x80]
	sll   $a3,$zero,$t1        # CHECK: sllv $7, $zero, $9     # encoding: [0x01,0x20,0x38,0x04]
	sllv  $a3,$t1              # CHECK: sllv $7, $7, $9        # encoding: [0x01,0x27,0x38,0x04]
	sllv  $a3,$zero,$t1        # CHECK: sllv $7, $zero, $9     # encoding: [0x01,0x20,0x38,0x04]
	slt   $s7,$11,$k1          # CHECK: slt $23, $11, $27      # encoding: [0x01,0x7b,0xb8,0x2a]
	slti  $s1,$10,9489         # CHECK: slti $17, $10, 9489    # encoding: [0x29,0x51,0x25,0x11]
	sltiu $t9,$t9,-15531       # CHECK: sltiu $25, $25, -15531 # encoding: [0x2f,0x39,0xc3,0x55]
	sltu  $s4,$s5,$11          # CHECK: sltu  $20, $21, $11    # encoding: [0x02,0xab,0xa0,0x2b]
	sltu  $t8,$t9,-15531       # CHECK: sltiu $24, $25, -15531 # encoding: [0x2f,0x38,0xc3,0x55]
	sra   $s1,15               # CHECK: sra $17, $17, 15       # encoding: [0x00,0x11,0x8b,0xc3]
	sra   $s1,$s7,15           # CHECK: sra $17, $23, 15       # encoding: [0x00,0x17,0x8b,0xc3]
	srav  $s1,$sp              # CHECK: srav $17, $17, $sp     # encoding: [0x03,0xb1,0x88,0x07]
	srav  $s1,$s7,$sp          # CHECK: srav $17, $23, $sp     # encoding: [0x03,0xb7,0x88,0x07]
	srl   $2,7                 # CHECK: srl $2, $2, 7          # encoding: [0x00,0x02,0x11,0xc2]
	srl   $2,$2,7              # CHECK: srl $2, $2, 7          # encoding: [0x00,0x02,0x11,0xc2]
	srl   $t9,$s4,$a0          # CHECK: srlv $25, $20, $4      # encoding: [0x00,0x94,0xc8,0x06]
	srlv  $t9,$a0              # CHECK: srlv $25, $25, $4      # encoding: [0x00,0x99,0xc8,0x06]
	srlv  $t9,$s4,$a0          # CHECK: srlv $25, $20, $4      # encoding: [0x00,0x94,0xc8,0x06]
	ssnop                      # CHECK: ssnop                  # encoding: [0x00,0x00,0x00,0x40]
	sub	$s6,$s3,$t4
	sub.d	$f18,$f3,$f17
	sub.s	$f23,$f22,$f22
	subu	$sp,$s6,$s6
	sw	$ra,-10160($sp)
	swc1	$f6,-8465($t8)
	swc2	$25,24880($s0)
	swl	$t7,13694($s3)
	swr	$s1,-26590($t6)
	xor	$s2,$a0,$s8
