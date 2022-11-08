#ifndef MACROS_NTT_I
#define MACROS_NTT_I

#include "macros.i"

### 7 instructions
.macro doublebutterfly_plant a0, a1, twiddle, tmp, q, qa
	smulwb \tmp, \twiddle, \a1 
	smulwt \a1, \twiddle, \a1
	smlabt \tmp, \tmp, \q, \qa
	smlabt \a1, \a1, \q, \qa
	pkhtb \tmp, \a1, \tmp, asr#16
	usub16 \a1, \a0, \tmp
	uadd16 \a0, \a0, \tmp
.endm

.macro two_doublebutterfly_plant a0, a1, a2, a3, twiddle0, twiddle1, tmp, q, qa
	doublebutterfly_plant \a0, \a1, \twiddle0, \tmp, \q, \qa
	doublebutterfly_plant \a2, \a3, \twiddle1, \tmp, \q, \qa
.endm


.macro butterfly_plant a, b, c, twiddle, tmp, q, qa
	smulwt \tmp, \twiddle, \a
	smlabt \tmp, \tmp, \q, \qa
	pkhtb \b, \tmp, \tmp, asr#16
	pkhbt \c, \a, \a, lsl#16
	ssax \a, \c, \b
.endm



#endif /* MACROS_NTT_I */