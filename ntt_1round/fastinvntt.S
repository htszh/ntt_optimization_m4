#include "macros_invntt.i"

.syntax unified
.cpu cortex-m4
.thumb

.macro halfplant a0, a1, tmp, q, qa, plantconst
	movw \plantconst, #44984
	movt \plantconst, #19
	doubleplant \a0, \tmp, \q, \qa, \plantconst
	doubleplant \a1, \tmp, \q, \qa, \plantconst
.endm

.macro fullplant a0, a1, a2, a3, tmp, q, qa, plantconst
	movw \plantconst, #44984
	movt \plantconst, #19
	doubleplant \a0, \tmp, \q, \qa, \plantconst
	doubleplant \a1, \tmp, \q, \qa, \plantconst
	doubleplant \a2, \tmp, \q, \qa, \plantconst
	doubleplant \a3, \tmp, \q, \qa, \plantconst
.endm

.global invntt_1round
.type invntt_1round, %function
.align 2
invntt_1round:
push {r4-r11, lr}

	poly        .req r0
	twiddle_ptr .req r1

	poly0       .req r2
	poly1       .req r3
	poly2       .req r4
	poly3       .req r5
	poly4       .req r6
	poly5       .req r7
	poly6       .req r8
	poly7       .req r9

	twiddle1    .req r10
	twiddle2    .req r11
	plantconst  .req r10
	###  qinv        .req r11 ### q^-1 mod 2^2n; n=16
	q           .req r12 
	### at the top of r12
	qa          .req r0
	### qa=2^a q;a=3; at the bottom of r0
	tmp         .req r14

	// movw qa, #26632
	movt q, #3329

##############################################################################################
	### LAYER 1 (skip layer 0)
	movw tmp, #8
	1:
		push {tmp}

        vmov.w s0, poly

        //poly0:poly        ;r0 + r1
        //poly1:poly + 4	;r2 + r3
        //poly2:poly + 8    ;r4 + r5
        //poly3:poly + 12	;r6 + r7
        //poly4:poly + 16   ;r8 + r9
        //poly5:poly + 20	;r10 + r11
        //poly6:poly + 24   ;r12 + r13
        //poly7:poly + 28	;r14 + r15
        ldm poly, {poly0-poly7}
        movw qa, #26632

        // ldr.w twiddle, [twiddle_ptr], #4
        //[twiddle_ptr] -> twiddle1, twiddle2; then twiddle_ptr = twiddle_ptr + #8  
        ldrd twiddle1, twiddle2, [twiddle_ptr], #8 
        inv_butterfly_first_layer poly0, twiddle1, tmp, q, qa
        inv_butterfly_first_layer poly1, twiddle2, tmp, q, qa

        // ldr.w twiddle, [twiddle_ptr], #4
        ldrd twiddle1, twiddle2, [twiddle_ptr], #8 
        inv_butterfly_first_layer poly2, twiddle1, tmp, q, qa
        inv_butterfly_first_layer poly3, twiddle2, tmp, q, qa

        ldrd twiddle1, twiddle2, [twiddle_ptr], #8 
        inv_butterfly_first_layer poly4, twiddle1, tmp, q, qa
        inv_butterfly_first_layer poly5, twiddle2, tmp, q, qa

        // ldr.w twiddle, [twiddle_ptr], #4
        ldrd twiddle1, twiddle2, [twiddle_ptr], #8 
        inv_butterfly_first_layer poly6, twiddle1, tmp, q, qa
        inv_butterfly_first_layer poly7, twiddle2, tmp, q, qa


        vmov.w poly, s0

        stm poly!, {poly0-poly7}


        pop {tmp}
        subs.w tmp, #1
        bne.w 1b





#############################################################################################
	sub.w poly, #256

	.equ distance, 32

	### LAYER 2+3+4

	movw tmp, #8
	2:
		push {tmp}

        vmov.w s0, poly

        //poly0:poly        ;r0 + r1
        //poly1:poly + 4	;r2 + r3
        //poly2:poly + 8    ;r4 + r5
        //poly3:poly + 12	;r6 + r7
        //poly4:poly + 16   ;r8 + r9
        //poly5:poly + 20	;r10 + r11
        //poly6:poly + 24   ;r12 + r13
        //poly7:poly + 28	;r14 + r15
        ldm poly, {poly0-poly7}
        movw qa, #26632
        ########################  layer 2 ######################################################
        ldrd twiddle1, twiddle2, [twiddle_ptr] 
        two_doubleinvbutterfly_plant poly0, poly1, poly2, poly3, twiddle1, twiddle2, tmp, q, qa
        // ldr.w twiddle, [twiddle_ptr], #4
        ldrd twiddle1, twiddle2, [twiddle_ptr, #8] 
        two_doubleinvbutterfly_plant poly4, poly5, poly6, poly7, twiddle1, twiddle2, tmp, q, qa

        fullplant poly0, poly2, poly4, poly6, tmp, q, qa, plantconst

        ########################  layer 3 ######################################################
        ldrd twiddle1, twiddle2, [twiddle_ptr, #16] 
        two_doubleinvbutterfly_plant poly0, poly2, poly1, poly3, twiddle1, twiddle1, tmp, q, qa
        two_doubleinvbutterfly_plant poly4, poly6, poly5, poly7, twiddle2, twiddle2, tmp, q, qa

        ########################  layer 4 ######################################################
        ldr.w twiddle1, [twiddle_ptr, #24] 
        two_doubleinvbutterfly_plant poly0, poly4, poly1, poly5, twiddle1, twiddle1, tmp, q, qa
        two_doubleinvbutterfly_plant poly2, poly6, poly3, poly7, twiddle1, twiddle1, tmp, q, qa

        vmov.w poly, s0

        stm poly!, {poly0-poly7}

        pop {tmp}
        subs.w tmp, #1
        bne.w 2b





#############################################################################################
	sub.w poly, #256

	.equ distance, 4*distance  //128

	### LAYER 5+6+7: 4 times

	movw tmp, #2
	3:
		push {tmp}
        vmov.w s0, poly
        //poly0:poly        ;r0  + r1
        //poly1:poly + 32	;r16 + r17
        //poly2:poly + 64   ;r32 + r33
        //poly3:poly + 96	;r48 + r49
        //poly4:poly + 128  ;r64 + r65
        //poly5:poly + 160	;r80 + r81
        //poly6:poly + 192  ;r96 + r97
        //poly7:poly + 224	;r112 + r113
        load poly, poly0, poly1, poly2, poly3, #0, #distance/4, #2*distance/4, #3*distance/4
        load poly, poly4, poly5, poly6, poly7, #distance, #5*distance/4, #6*distance/4, #7*distance/4
        movw qa, #26632

        ################################    layer  5   ########################################### 
        ldrd twiddle1, twiddle2, [twiddle_ptr] 
        two_doubleinvbutterfly_plant poly0, poly1, poly2, poly3, twiddle1, twiddle2, tmp, q, qa
        // ldr.w twiddle, [twiddle_ptr], #4
        ldrd twiddle1, twiddle2, [twiddle_ptr, #8] 
        two_doubleinvbutterfly_plant poly4, poly5, poly6, poly7, twiddle1, twiddle2, tmp, q, qa

        ################################    layer  6   ###########################################
        ldrd twiddle1, twiddle2, [twiddle_ptr, #16] 
        two_doubleinvbutterfly_plant poly0, poly2, poly1, poly3, twiddle1, twiddle1, tmp, q, qa
        two_doubleinvbutterfly_plant poly4, poly6, poly5, poly7, twiddle2, twiddle2, tmp, q, qa
        // ldr.w twiddle, [twiddle_ptr], #4
        // only need to reduce 4 times
        halfplant poly0, poly4, tmp, q, qa, plantconst
        // fullplant poly0, poly1, poly4, poly5, tmp, q, qa, plantconst

        ################################    layer  7   ###########################################
        ldrd twiddle1, twiddle2, [twiddle_ptr, #24] 
        two_doubleinvbutterfly_plant poly0, poly4, poly1, poly5, twiddle1, twiddle1, tmp, q, qa
        two_doubleinvbutterfly_plant poly2, poly6, poly3, poly7, twiddle1, twiddle1, tmp, q, qa

        ################################# 128^-1 ###############################################
        fqmulprecomp_plant poly0, twiddle2, tmp, q, qa
        fqmulprecomp_plant poly1, twiddle2, tmp, q, qa
        fqmulprecomp_plant poly2, twiddle2, tmp, q, qa
        fqmulprecomp_plant poly3, twiddle2, tmp, q, qa

        vmov.w poly, s0

        store poly, poly4, poly5, poly6, poly7, #distance, #5*distance/4, #6*distance/4, #7*distance/4
        str.w poly1, [poly, #distance/4]
        str.w poly2, [poly, #2*distance/4]
        str.w poly3, [poly, #3*distance/4]
        str.w poly0, [poly], #4 //poly = poly + 4  r0 -> r2


		pop {tmp}
		subs.w tmp, #1
	    bne.w 3b



	movw tmp, #6
	4:
		push {tmp}

        vmov.w s0, poly
        load poly, poly0, poly1, poly2, poly3, #0, #distance/4, #2*distance/4, #3*distance/4
        load poly, poly4, poly5, poly6, poly7, #distance, #5*distance/4, #6*distance/4, #7*distance/4
        movw qa, #26632

        ldrd twiddle1, twiddle2, [twiddle_ptr] 
        two_doubleinvbutterfly_plant poly0, poly1, poly2, poly3, twiddle1, twiddle2, tmp, q, qa
        // ldr.w twiddle, [twiddle_ptr], #4
        ldrd twiddle1, twiddle2, [twiddle_ptr, #8] 
        two_doubleinvbutterfly_plant poly4, poly5, poly6, poly7, twiddle1, twiddle2, tmp, q, qa

        ldrd twiddle1, twiddle2, [twiddle_ptr, #16] 
        two_doubleinvbutterfly_plant poly0, poly2, poly1, poly3, twiddle1, twiddle1, tmp, q, qa
        two_doubleinvbutterfly_plant poly4, poly6, poly5, poly7, twiddle2, twiddle2, tmp, q, qa
        // ldr.w twiddle, [twiddle_ptr], #4

        // halfplant poly0, poly4, tmp, q, qa, plantconst
        // fullplant poly0, poly1, poly4, poly5, tmp, q, qa, plantconst

        ldrd twiddle1, twiddle2, [twiddle_ptr, #24] 
        two_doubleinvbutterfly_plant poly0, poly4, poly1, poly5, twiddle1, twiddle1, tmp, q, qa
        two_doubleinvbutterfly_plant poly2, poly6, poly3, poly7, twiddle1, twiddle1, tmp, q, qa

        // @TODO
        fqmulprecomp_plant poly0, twiddle2, tmp, q, qa
        fqmulprecomp_plant poly1, twiddle2, tmp, q, qa
        fqmulprecomp_plant poly2, twiddle2, tmp, q, qa
        fqmulprecomp_plant poly3, twiddle2, tmp, q, qa

        vmov.w poly, s0

        store poly, poly4, poly5, poly6, poly7, #distance, #5*distance/4, #6*distance/4, #7*distance/4
        str.w poly1, [poly, #distance/4]
        str.w poly2, [poly, #2*distance/4]
        str.w poly3, [poly, #3*distance/4]
        str.w poly0, [poly], #4


        pop {tmp}
        subs.w tmp, #1
        bne.w 4b

	pop {r4-r11, pc}
