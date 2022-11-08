#include <stdio.h>
#include <stdint.h>
#include "../common/hal.h"
#define N 256
#define q 3329
typedef short              int16_t;
//typedef int                int32_t;
// 17^-1 = 1175 % 3329
const int32_t zetas_asm[128] = {
  // 7 & 6 & 5 layers
  2230699446, 3328631909, 4243360600, 3408622288, 812805467, 2447447570, 1094061961, 
  // 1st loop of 4 & 3 & 2 layers
  1370157786, 381889553, 3157039644, 372858381, 427045412, 4196914574, 2265533966, 
  // 2nd loop of 4 & 3 & 2 layers
  2475831253, 1727534158, 1904287092, 1544330386, 2972545705, 2937711185, 2651294021, 
  // 3rd loop of 4 & 3 & 2 layers
  249002310, 3929849920, 72249375, 838608815, 2550660963, 3242190693, 815385801, 
  // 4th loop of 4 & 3 & 2 layers
  1028263423, 2889974991, 1719793153, 3696329620, 42575525, 1703020977, 2470670584, 
  // 5th loop of 4 & 3 & 2 layers
  3594406395, 1839778722, 2701610550, 2991898216, 1851390229, 1041165097, 583155668, 
  // 6th loop of 4 & 3 & 2 layers
  4205945745, 690239563, 3718262466, 1855260731, 3700200122, 1979116802, 3098982111, 
  // 7th loop of 4 & 3 & 2 layers
  734105255, 3087370604, 3714391964, 3415073125, 3376368103, 1910737929, 836028480, 
  // 8th loop of 4 & 3 & 2 layers
  2252632292, 2546790461, 1059227441, 3191874164, 4012420634, 1583035408, 1174052340, 
  // 1 layer
  21932846, 3562152210, 752167598, 3417653460, 2112004045, 932791035, 2951903026, 1419184148, 1817845876, 3434425636, 4233039261, 300609006, 975366560, 2781600929, 3889854731, 3935010590, 2197155094, 2130066389, 3598276897, 2308109491, 2382939200, 1228239371, 1884934581, 3466679822, 1211467195, 2977706375, 3144137970, 3080919767, 945692709, 3015121229, 345764865, 826997308, 2043625172, 2964804700, 2628071007, 4154339049, 483812778, 3288636719, 2696449880, 2122325384, 1371447954, 411563403, 3577634219, 976656727, 2708061387, 723783916, 3181552825, 3346694253, 3617629408, 1408862808, 519937465, 1323711759, 1474661346, 2773859924, 3580214553, 1143088323, 2221668274, 1563682897, 2417773720, 1327582262, 2722253228, 3786641338, 1141798155, 2779020594,
};

const int32_t zetas_inv_asm[128] = {
  // 1 layer	
  1515946703, 3153169142, 508325959, 1572714069, 2967385035, 1877193577, 2731284400, 2073299023, 3151878974, 714752744, 1521107373, 2820305951, 2971255538, 3775029832, 2886104489, 677337889, 948273044, 1113414472, 3571183381, 1586905910, 3318310570, 717333078, 3883403894, 2923519343, 2172641913, 1598517417, 1006330578, 3811154519, 140628248, 1666896290, 1330162597, 2251342125, 3467969989, 3949202432, 1279846068, 3349274588, 1214047530, 1150829327, 1317260922, 3083500102, 828287475, 2410032716, 3066727926, 1912028097, 1986857806, 696690400, 2164900908, 2097812203, 359956707, 405112566, 1513366368, 3319600737, 3994358291, 61928036, 860541661, 2477121421, 2875783149, 1343064271, 3362176262, 2182963252, 877313837, 3542799699, 732815087, 4273034451, 
  // 1st loop of 2 & 3 & 4 layers
  3120914957, 2711931889, 282546663, 1103093133, 3235739856, 1748176836, 2042335005, 
  // 2nd loop of 2 & 3 & 4 layers
  3458938817, 2384229368, 918599194, 879894172, 580575333, 1207596693, 3560862042, 
  // 3rd loop of 2 & 3 & 4 layers
  1195985186, 2315850495, 594767175, 2439706566, 576704831, 3604727734, 89021552, 
  // 4th loop of 2 & 3 & 4 layers
  3711811629, 3253802200, 2443577068, 1303069081, 1593356747, 2455188575, 700560902, 
  // 5th loop of 2 & 3 & 4 layers
  1824296713, 2591946320, 4252391772, 598637677, 2575174144, 1404992306, 3266703874, 
  // 6th loop of 2 & 3 & 4 layers
  3479581496, 1052776604, 1744306334, 3456358482, 4222717922, 365117377, 4045964987, 
  // 7th loop of 2 & 3 & 4 layers
  1643673276, 1357256112, 1322421592, 2750636911, 2390680205, 2567433139, 1819136044, 
  // 8th loop of 2 & 3 & 4 layers
  2029433331, 98052723, 3867921885, 3922108916, 1137927653, 3913077744, 2924809511, 
  // 5 & 6 & 7 layers
  3200905336, 1847519727, 3482161830, 886345009, 51606697, 966335388, 1802363867, 
  // 128^-1 * (2^16)^2
  2435836064
};



extern void ntt_1round(int16_t*, const int32_t *);
extern void pointwise_1round(int16_t*,int16_t*,int16_t*);
extern void pointwise_1round_zeta(int16_t*,int16_t*,int32_t*);
extern void for_poly_for_poly_addition(int16_t*,int16_t*,int16_t*);
extern void for_poly_odd(int16_t*,int16_t*,int16_t*,int16_t*);
extern void invntt_1round(int16_t*, const int32_t *);

void Iptntt_1round(int16_t* h, int16_t* f, int16_t* g, int dim) {
    int16_t f_even[dim], f_odd[dim], g_even[dim], g_odd[dim], fg_even[dim], fg_odd1[dim], fg_odd2[dim], f_add[dim], g_add[dim], fg_add[dim], fg_mul[dim], h_even[dim], h_odd[dim];
    int32_t temp[128] = {};
    int i;
    for(i = 0; i < dim; i++) {
        f_even[i] = f[2 * i];
        f_odd[i] = f[2 * i + 1];

        g_even[i] = g[2 * i];
        g_odd[i] = g[2 * i + 1];
    }

    ntt_1round(f_even, zetas_asm);
    ntt_1round(g_even, zetas_asm);
    pointwise_1round(fg_even, f_even, g_even);

    ntt_1round(f_odd, zetas_asm);
    ntt_1round(g_odd, zetas_asm);
    pointwise_1round(fg_odd1, f_odd, g_odd);
    pointwise_1round_zeta(fg_odd2, fg_odd1, temp);

    for_poly_addition(h_even, fg_even, fg_odd2);
    invntt_1round(h_even, zetas_inv_asm);

    for_poly_addition(f_add, f_even, f_odd);
    for_poly_addition(g_add, g_even, g_odd);
    pointwise_1round(fg_mul, f_add, g_add);

    for_poly_addition(fg_add, fg_even, fg_odd1);
    
    for_poly_subtraction(h_odd, fg_mul, fg_add);
    invntt_1round(h_odd, zetas_inv_asm);

    for(i = 0; i < dim; i++) {
        h[2 * i]     = h_even[i];
        h[2 * i + 1] = h_odd[i];
    }
}

void poly_naivemul(int16_t* h, int16_t* f, int16_t* g) {
	

    int i, j;
	int16_t r[2 * N];

	for (i = 0; i < 2 * N; i++)
		r[i] = 0;

	for (i = 0; i < N; i++)
		for (j = 0; j < N; j++)
		{
			r[i + j] += f[i] * g[j] % q;
			r[i + j] %= q;
		}

	for (i = N; i < 2 * N - 1; i++) {
		r[i - N] = r[i - N] + q - r[i];
		r[i - N] %= q;
	}

	for (i = 0; i < N; i++)
		r[i] = r[i];
}

int main() {
    hal_setup(CLOCK_BENCHMARK);

    hal_send_str("tt");
    int16_t poly_r_naive[N],poly_r[N], poly_a[N], poly_b[N];
    int i;

    for (int j = 0; j < N; j++)
	{
		srand((unsigned int)time(NULL) + j * 10);
		poly_a[j] = rand() % 3329;
        poly_b[j] = rand() % 3329;
		
	}
    poly_naivemul(poly_r_naive, poly_a, poly_b);
    Iptntt_1round(poly_r, poly_a, poly_b, N/2);

    for(i = 0; i < N; i++)
        if(poly_r[i] != poly_r_naive[i])
            break;
    
    if (i == N)   hal_send_str("success\n");
	else hal_send_str("wrong\n");

    hal_send_str("#");

    while (1)
        ;
        
    return 0;
}