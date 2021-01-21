
		.file	"FixMath.S"

		.text

|---------------------------------------------------------------------------
| 16.16 fixed-point multiplication for 68020+/ColdFire
|
| int result = FixedMul(int x, int y)|
|     d0                  stack  stack

		.globl	FixedMul
		.type	FixedMul,@function
		.align	4
FixedMul:
		move.l	%d6,-(%sp)
		move.l	%d7,%a1

		move.l	8(%sp),%d6		| Get x
		move.l	12(%sp),%d7		| Get y

		move.w	%d6,%d0			| frac(x) * frac(y)
		mulu.w	%d7,%d0
		clr.w	%d0
		swap	%d0
		move.l	%d0,%a0

		move.l	%d6,%d0			| int(x) * frac(y)
		moveq	#0,%d1
		move.w	%d7,%d1
		swap	%d0
		ext.l	%d0
		muls.l	%d0,%d1
		add.l	%d1,%a0
		swap	%d7

		moveq	#0,%d1			| frac(x) * int(y)
		move.w	%d6,%d1
		move.w	%d7,%d0
		ext.l	%d0
		muls.l	%d0,%d1
		add.l	%d1,%a0

		swap	%d6			| int(x) * int(y)
		muls.w	%d7,%d6
		swap	%d6
		clr.w	%d6
		add.l	%d6,%a0

		move.l	%a0,%d0

		move.l	(%sp)+,%d6
		move.l	%a1,%d7
		rts

.Lfe1:
		.size	FixedMul,.Lfe1-FixedMul


|--------------------------------------------------------------------------
| Saturating 16.16 fixed point division for 68020+/ColdFire 5307+
| Utilizes hardware division (DIVU.L)
|
| Accuracy: roughly 14 MSB of denominator
|
| int result = FixedDiv(int x, int y)
|     d0                  stack  stack

	
		.globl	FixedDiv
		.type	FixedDiv,@function
		.align	4
FixedDiv:
		move.l	%d2,%a0
		move.l	4(%sp),%d0		| Get x
		move.l	%d3,%a1
		move.l	8(%sp),%d1		| Get y

		move.l	%d0,%d2			| sign(x) * sign(y)
		moveq	#31,%d3
		eor.l	%d1,%d2
		asr.l	%d3,%d2
		move.l	%d2,-(%sp)

		move.l	%d0,%d2			| abs(x)
		asr.l	%d3,%d2
		eor.l	%d2,%d0
		sub.l	%d2,%d0

		move.l	%d1,%d2			| abs(y)
		asr.l	%d3,%d2
		eor.l	%d2,%d1
		sub.l	%d2,%d1

		move.l	%d0,%d3			| if (abs(x) >> 15) > abs(y),
		lsr.l	#8,%d3			| saturate result
		lsr.l	#7,%d3
		cmp.l	%d1,%d3
		bhs.s	.saturate

		move.l	%d0,%d2			| Quotient of abs(x) / abs(y)
		divu.l	%d1,%d0

		move.l	%d0,%d3			| Remainder of abs(x) / abs(y)
		mulu.l	%d1,%d3
		sub.l	%d3,%d2

		cmp.l	#0x0000ffff,%d1		| Shift remainder & abs(y)
		bhs.s	.bits16			| up/down 16 bits in total
		swap	%d2
.finish:
		divu.l	%d1,%d2			| (Remainder << shiftup) / (abs(y) >> (16 - shiftup))
		move.l	(%sp)+,%d3

		swap	%d0			| Convert to 16.16 fixed point again
		clr.w	%d0

		add.l	%d2,%d0			| Add in divided remainder

		eor.l	%d3,%d0			| Flip sign, if necessary
		sub.l	%d3,%d0

		move.l	%a0,%d2
		move.l	%a1,%d3
		rts

.bits16:
		cmp.l	#0x00ffffff,%d1
		bhs.s	.bits24
		cmp.l	#0x000fffff,%d1
		bhs.s	.bits20
		lsl.l	#8,%d2
		lsr.l	#4,%d1
		lsl.l	#4,%d2
		bra.s	.finish
.bits20:
		lsr.l	#8,%d1
		lsl.l	#8,%d2
		bra.s	.finish
.bits24:
		cmp.l	#0x0fffffff,%d1
		bhs.s	.bits28
		lsr.l	#8,%d1
		lsr.l	#4,%d1
		lsl.l	#4,%d2
		bra.s	.finish
.bits28:
		clr.w	%d1
		swap	%d1
		bra.s	.finish

.saturate:
		move.l	#0x7fffffff,%d0		| Saturate result
		move.l	(%sp)+,%d1		| to MAXINT * sign(x) * sign(y)
		move.l	%a0,%d2
		eor.l	%d1,%d0
		move.l	%a1,%d3
		rts

.Lfe2:	
		.size	FixedDiv,.Lfe2-FixedDiv
