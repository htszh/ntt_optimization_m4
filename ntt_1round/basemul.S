.syntax unified
.cpu cortex-m4
.thumb

.macro base_mul a0, zeta1, zeta2, tmp, tmp2, q, qa
	smulwb \tmp,  \zeta1, \a0
	smulwt \tmp2, \zeta2, \a0
	smlabt \tmp, \tmp, \q, \qa
	smlabt \tmp2, \tmp2, \q, \qa
	pkhtb  \a0, \tmp, \tmp2, asr#16
.endm

.macro plant_red q, qa, qinv, tmp
	mul \tmp, \tmp, \qinv     
	//tmp*qinv mod 2^2n/ 2^n; in high half
	smlatt \tmp, \tmp, \q, \qa
	// result in high half
.endm

.global pointwise_1round
.type pointwise_1round, %function
.align 2
pointwise_1round:
	push {r4-r11, lr}

	poly_r		.req r0
	poly_a		.req r1
	poly_b		.req r2
	
	poly0       .req r4
	poly1       .req r5
	poly2       .req r6
	poly3       .req r7
	
	q       	.req r8
	qa      	.req r14
	qinv    	.req r9
	tmp     	.req r10
	tmp2    	.req r11
	zeta    	.req r12
	loop    	.req r14

	movw loop, #32
	1:
		vmov.w s0, loop

		### q in the top half
        movw qa, #26632
        movt  q, #3329  
        ### qinv=0x6ba8f301
        movw qinv, #62209  // bottom
        movt qinv, #27560  // top

        ldrd poly0, poly2, [poly_a], #8
        ldrd poly1, poly3, [poly_b], #8

        smulbb tmp, poly0, poly1
        smultt tmp2, poly0, poly1
        plant_red q, qa, qinv, tmp
        plant_red q, qa, qinv, tmp2
        pkhtb poly0, tmp, tmp2, asr#16
        str poly0, [poly_r], #4

        smulbb tmp, poly2, poly3
        smultt tmp2, poly2, poly3
        plant_red q, qa, qinv, tmp
        plant_red q, qa, qinv, tmp2
        pkhtb poly2, tmp, tmp2, asr#16
        str poly2, [poly_r], #4

		vmov.w loop,s0
		subs.w loop, #1
		bne.w 1b

	.unreq poly_r   
	.unreq poly_a   
	.unreq poly_b   

	.unreq poly0  
	.unreq poly1  
	.unreq poly2  
	.unreq poly3  
	.unreq q      
	.unreq qa     
	.unreq qinv   
	.unreq tmp    
	.unreq tmp2   
	.unreq zeta   
	.unreq loop   

	pop {r4-r11, pc}



.global pointwise_1round_zeta
.type pointwise_1round_zeta, %function
.align 2
pointwise_1round_zeta:
	push {r4-r11, lr}

	poly_r		.req r0
    poly_a		.req r1
	zeta_ptr	.req r2
	
    zeta1       .req r3
    zeta2       .req r4
	poly0       .req r5
	poly1       .req r6
	poly2       .req r7
	poly3       .req r8
	
	q       	.req r9
	qa      	.req r10
	tmp     	.req r11
	tmp2    	.req r12
	//zeta    	.req r12
	loop    	.req r14

    movt q, #3329
    movw qa, #26632

    movw loop, #16
    1:
        vmov.w s0, loop

        ldm poly_a,{poly0-poly3}

        ldrd zeta1, zeta2, [zeta_ptr], #8
        base_mul poly0, zeta1, zeta2, tmp, tmp2, q, qa
        str poly0, [poly_r], #4

        ldrd zeta1, zeta2, [zeta_ptr], #8
        base_mul poly1, zeta1, zeta2, tmp, tmp2, q, qa
        str poly1, [poly_r], #4

        ldrd zeta1, zeta2, [zeta_ptr], #8
        base_mul poly2, zeta1, zeta2, tmp, tmp2, q, qa
        str poly2, [poly_r], #4

        ldrd zeta1, zeta2, [zeta_ptr], #8
        base_mul poly3, zeta1, zeta2, tmp, tmp2, q, qa
        str poly3, [poly_r], #4

        //stm poly_r!, {poly0-poly3}
        vmov.w loop, s0
		subs.w loop, #1
		bne.w 1b

    pop {r4-r11, lr}

.global for_poly_addition
.type for_poly_addition, %function
.align 2
for_poly_addition:
    push {r4-r11, lr}
    poly_r      .req r0
    poly_a      .req r1
    poly_b      .req r2

    poly0       .req r3
	poly1       .req r4
	poly2       .req r5
	poly3       .req r6
	poly4       .req r7
	poly5       .req r8
	poly6       .req r9
	poly7       .req r10

    tmp         .req r11
    tmp2        .req r12

    loop    	.req r14

    movw loop, #16
    1:
        push {loop}

        ldm poly_a, {poly0-poly3}
        ldm poly_b, {poly4-poly7}

        uadd16 tmp, poly0, poly4
        str tmp, [poly_r], #4

        uadd16 tmp, poly1, poly5
        str tmp, [poly_r], #4

        uadd16 tmp, poly2, poly6
        str tmp, [poly_r], #4

        uadd16 tmp, poly3, poly7
        str tmp, [poly_r], #4

        pop {loop}
        subs.w loop, #1
        bne.w 1b
    pop {r4-r11, lr}


.global for_poly_subtraction
.type for_poly_subtraction, %function
.align 2
for_poly_subtraction:
    push {r4-r11, lr}

    poly_r      .req r0
    poly_a      .req r1
    poly_b      .req r2
    

    poly0       .req r3
	poly1       .req r4
	poly2       .req r5
	poly3       .req r6
	poly4       .req r7
	poly5       .req r8
	poly6       .req r9
	poly7       .req r10
	
	
    loop    	.req r14

    movw loop, #16
    1:
        push {loop}
        
        ldm poly_a, {poly0-poly3}
        ldm poly_b, {poly4-poly7}

        usub16 tmp, poly0, poly4
        str tmp, [poly_r], #4

        usub16 tmp, poly1, poly5
        str tmp, [poly_r], #4

        usub16 tmp, poly2, poly6
        str tmp, [poly_r], #4

        usub16 tmp, poly3, poly7
        str tmp, [poly_r], #4

        pop {loop}
        subs.w loop, #1
        bne.w 1b

    pop {r4-r11, lr}