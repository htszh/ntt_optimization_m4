#ifndef MACROS_INVNTT_I
#define MACROS_INVNTT_I

#include "macros.i"


.macro inv_butterfly_first_layer a, twiddle, tmp, q, qa
    uasx \tmp, \a, \a
    smulwb \a, \twiddle, \tmp
    smlabt \a, \a, \q, \qa 
    pkhtb \a, \a, \tmp, asr#16
.endm

.macro doubleinvbutterfly_plant a0, a1, twiddle, tmp, q, qa
	//tmp.top    = \a0.top    - \a1.top  	% 2**16
	//tmp.bottom = \a0.bottom - \a1.bottom  % 2**16
	usub16 \tmp, \a0, \a1

	//\a0.top    = \a0.top    + \a1.top     %2**16
	//\a0.bootom = \a0.bootom + \a1.bottom  %2**16
	uadd16 \a0, \a0, \a1

	smulwb \a1, \twiddle, \tmp
	smulwt \tmp, \twiddle, \tmp
	smlabt \a1, \a1, \q, \qa
	smlabt \tmp, \tmp, \q, \qa
	pkhtb \a1, \tmp, \a1, asr#16
.endm

.macro two_doubleinvbutterfly_plant a0, a1, a2, a3, twiddle1, twiddle2, tmp, q, qa
	doubleinvbutterfly_plant \a0, \a1, \twiddle1, \tmp, \q, \qa
	doubleinvbutterfly_plant \a2, \a3, \twiddle2, \tmp, \q, \qa
.endm

.macro fqmulprecomp_plant a, twiddle, tmp, q, qa
	smulwb \tmp, \twiddle, \a 
	smulwt \a, \twiddle, \a
	smlabt \tmp, \tmp, \q, \qa
	smlabt \a, \a, \q, \qa
	pkhtb \a, \a, \tmp, asr#16
.endm

#endif /* MACROS_INVNTT_I */