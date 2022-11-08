#include "macros_ntt.i"

.syntax unified
.cpu cortex-m4
.thumb

.global ntt_1round
.type ntt_1round, %function
.align 2
ntt_1round:
	push {r4-r11, r14}

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
	###  qinv        .req r11 ### q^-1 mod 2^2n; n=16
	q           .req r12 
	### at the top of r12
	qa          .req r0
	### qa=2^a q;a=3; at the bottom of r12
	tmp         .req r14

	movt q, #3329
	
	##################################################################################################
	//1+2+3
	.equ distance, 128

	movw tmp, #8
	1:
		push {tmp}

		vmov.w s0, poly

		//poly0: poly;      r0  + r1 ; 
		//poly1: poly + 32; r16 + r17; 
		//poly2: poly + 64; r32 + r33;
		//poly3: poly + 96; r48 + r49; 
		load poly, poly0, poly1, poly2, poly3, #0, #distance/4, #2*distance/4, #3*distance/4
		
		//poly4: poly + 128; r64  + r65; 
		//poly5: poly + 160; r80  + r81; 
		//poly6: poly + 192; r96  + r97; 
		//poly7: poly + 224; r112 + r113; 
		load poly, poly4, poly5, poly6, poly7, #distance, #5*distance/4, #6*distance/4, #7*distance/4
		
		movw qa, #26632

        //layer 1
		ldr.w twiddle1, [twiddle_ptr]
		two_doublebutterfly_plant poly0, poly4, poly1, poly5, twiddle1, twiddle1, tmp, q, qa
		two_doublebutterfly_plant poly2, poly6, poly3, poly7, twiddle1, twiddle1, tmp, q, qa

        //layer 2
		ldrd twiddle1, twiddle2, [twiddle_ptr, #4] 
		### increase 1cc while reduce 8cc
		two_doublebutterfly_plant poly0, poly2, poly1, poly3, twiddle1, twiddle1, tmp, q, qa
		two_doublebutterfly_plant poly4, poly6, poly5, poly7, twiddle2, twiddle2, tmp, q, qa

        //layer 3
		ldrd twiddle1, twiddle2, [twiddle_ptr, #12] 
		### increase 1cc while reduce 4cc
		two_doublebutterfly_plant poly0, poly1, poly2, poly3, twiddle1, twiddle2, tmp, q, qa

		ldrd twiddle1, twiddle2, [twiddle_ptr, #20] 
		### increase 1cc while reduce 4cc
		two_doublebutterfly_plant poly4, poly5, poly6, poly7, twiddle1, twiddle2, tmp, q, qa

		// pop {poly}
		vmov.w poly, s0

		store poly, poly4, poly5, poly6, poly7, #distance, #5*distance/4, #6*distance/4, #7*distance/4
		str.w poly1, [poly, #distance/4]
		str.w poly2, [poly, #2*distance/4]
		str.w poly3, [poly, #3*distance/4]
		str.w poly0, [poly], #4 //r0 -> r2 -> r4 -> ... -> r14

		pop {tmp}
		subs.w tmp, #1
		bne.w 1b

		#########################################################################################
		//4+5+6
		sub.w poly, #64
		add.w twiddle_ptr, #28

		.equ distance, distance/8  //distance:16 

		movw tmp, #8
		2:
			push {tmp}
			@ movw tmp, #2
			@ 3:
			@ 	push {tmp}

				vmov.w s0, poly

				//poly0: poly;      r0 + r1; 
				//poly1: poly + 4;  r2 + r3; 
				//poly2: poly + 8;  r4 + r5; 
				//poly3: poly + 12; r6 + r7;
				@ load poly, poly0, poly1, poly2, poly3, #0, #distance/4, #2*distance/4, #3*distance/4
				//poly4: poly + 16; r8  + r9; 
				//poly5: poly + 20; r10 + r11;  
				//poly6: poly + 24; r12 + r13;  
				//poly7: poly + 28; r14 + r15;  
				@ load poly, poly4, poly5, poly6, poly7, #distance, #5*distance/4, #6*distance/4, #7*distance/4

                ldm poly, {poly0-poly7}

				movw qa, #26632

                //layer 4
				ldr twiddle1, [twiddle_ptr] 
				two_doublebutterfly_plant poly0, poly4, poly1, poly5, twiddle1, twiddle1, tmp, q, qa
				two_doublebutterfly_plant poly2, poly6, poly3, poly7, twiddle1, twiddle1, tmp, q, qa

                //layer 5
				ldrd twiddle1, twiddle2, [twiddle_ptr, #4] 
				two_doublebutterfly_plant poly0, poly2, poly1, poly3, twiddle1, twiddle1, tmp, q, qa
				two_doublebutterfly_plant poly4, poly6, poly5, poly7, twiddle2, twiddle2, tmp, q, qa

                //layer 6
				ldrd twiddle1, twiddle2, [twiddle_ptr, #12] 
				two_doublebutterfly_plant poly0, poly1, poly2, poly3, twiddle1, twiddle2, tmp, q, qa

				ldrd twiddle1, twiddle2, [twiddle_ptr, #20] 
				two_doublebutterfly_plant poly4, poly5, poly6, poly7, twiddle1, twiddle2, tmp, q, qa


				// pop {poly}
				vmov.w poly, s0
                stm poly!, {poly0-poly7}
				@ store poly, poly4, poly5, poly6, poly7, #distance,#5*distance/4, #6*distance/4, #7*distance/4
				@ str.w poly1, [poly, #distance/4]
				@ str.w poly2, [poly, #2*distance/4]
				@ str.w poly3, [poly, #3*distance/4]
				@ str.w poly0, [poly], #4

				@ pop {tmp}
				@ subs.w tmp, #1
				@ bne.w 3b

			add.w poly, #32
			add.w twiddle_ptr, #28

			pop {tmp}
			subs.w tmp, #1
			bne.w 2b

		###########################################################################################
		// layer 1

		sub poly, #256
		movw tmp, #16
		4:
			push {tmp}

			vmov.w s0, poly

			//poly0:poly;      r0  + r1;          
			//poly1:poly + 4;  r2  + r3;  
			//poly2:poly + 8;  r4  + r5;      
			//poly3:poly + 12; r6  + r7;  
			//poly4:poly + 16; r8  + r9;     
			//poly5:poly + 20; r10 + r11; 
			//poly6:poly + 24; r12 + r13;   
			//poly7:poly + 28; r14 + r15;  
			ldm poly, {poly0-poly3}

			movw qa, #26632

			ldrd twiddle1, twiddle2, [twiddle_ptr], #8
            butterfly_plant poly0, poly4, poly5, twiddle1, tmp, q, qa
            butterfly_plant poly1, poly4, poly5, twiddle2, tmp, q, qa
			//wo_doublebutterfly_plant poly0, poly1, poly2, poly3, twiddle1, twiddle2, tmp, q, qa

			ldrd twiddle1, twiddle2, [twiddle_ptr], #8
			butterfly_plant poly3, poly4, poly5, twiddle1, tmp, q, qa
            butterfly_plant poly4, poly4, poly5, twiddle2, tmp, q, qa
            //two_doublebutterfly_plant poly4, poly5, poly6, poly7, twiddle1, twiddle2, tmp, q, qa

			vmov.w poly, s0
			stm poly!, {poly0-poly3}

			pop {tmp}
			subs.w tmp, #1
			bne.w 4b

		pop {r4-r11, pc}